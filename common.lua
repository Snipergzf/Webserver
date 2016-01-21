-- Copyright (C) 2015 fffonion

-- common utils
-- requires lfs (lua file system) module

local lfs = require('lfs')
local config = require('config')

local _M = { _VERSION = '0.01' }


local function _wrapper_require(path)
	ngx.log(ngx.DEBUG, "[LI] load "..path)
	return require(path)
end

function _M.try_load_module(path)
	local lua_path = string.gsub(path, "/", ".") -- map uri-style to lua-package-style
	local s, r = pcall(_wrapper_require, path) -- call with error handling
	return s, r
end

function _M.try_load_controller(name)
	return _M.try_load_module('v'..ngx.var.ver..'.controller.'..name)
end

function _M.try_load_model(name)
	return _M.try_load_module('v'..ngx.var.ver..'.model.'..name)
end

function _M.try_load_view(name)
	return _M.try_load_module('v'..ngx.var.ver..'.view.'..name)
end

function _M.send_resp(view)
	-- send view to client
	ngx.status = view.http_status
	
	local ret = view:get_view()
	-- ngx.header["Content-Length"] = string.len(ret)
	if view.content_type then
		ngx.header["Content-Type"] = view.content_type
	else
		ngx.header["Content-Type"] = 'text/html'
	end
	ngx.send_headers()
	ngx.say(ret)
end

function _M.get_dbconn()
	if ngx.ctx['mysql_instance'] ~= nil then
		return ngx.ctx['mysql_instance']
	end
	local mysql = require "resty.mysql"
	local db, err = mysql:new()
	if not db then
		ngx.log(ngx.ERR, "[LI] failed to instantiate mysql: ", err)
		return nil
	end
	db:set_timeout(1000) -- 1 sec
	local ok, err, errno, sqlstate =
	  db:connect{
		 path = config.MYSQL_UNIX_SOCKET,
		 database = "Register",
		 user = config.MYSQL_USER_NAME,
		 password = config.MYSQL_USER_PASS
	}
	if not db then
		ngx.log(ngx.ERR, "[LI] failed to connect: ", err, ": ", errno, " ", sqlstate)
		return nil
	end
	ngx.ctx['mysql_instance'] = db
	return db
end

function _M.get_mongo()
	local conn = nil
	if ngx.ctx['mongo_instance'] ~= nil then
		conn = ngx.ctx['mongo_instance']
	else
		local mongol = require "resty.mongol"
		conn = mongol:new()
		if not conn then
			ngx.log(ngx.ERR, "[LI] failed to instantiate mongodb")
			return nil
		end
		conn:set_timeout(1000)
		local ok, err = conn:connect(config.MONGO_HOST, config.MONGO_PORT)
		if not ok then
			ngx.log(ngx.ERR, "[LI] failed to connect mongodb: ", err)
			return nil
		end
		ngx.ctx['mongo_instance'] = conn
	end
	local db = conn:new_db_handle(config.MONGO_COLLECTION)
	local ok, err = db:auth(config.MONGO_USER_NAME, config.MONGO_USER_PASS)
	if not ok then
		ngx.log(ngx.ERR, "[LI] failed to auth to mongodb: ", err)
		return nil
	end
	return db
end

function _M.cleanup()
	if ngx.ctx['mysql_instance'] ~= nil then
		local ok, err = ngx.ctx['mysql_instance']:set_keepalive(10000, 10)
		if ok == nil then
			ngx.log(ngx.ERR, "failed to set keep alive for mysql connection", err)
			ngx.ctx['mysql_instance']:close()
		end
	end
	if ngx.ctx['mongo_instance'] ~= nil then
		local ok, err = ngx.ctx['mongo_instance']:set_keepalive(10000, 10)
		if ok == nil then
			ngx.log(ngx.ERR, "failed to set keep alive for mongo connection", err)
			ngx.ctx['mongo_instance']:close()
		end
	end
end

function _M.zero_index_array(arr)
	local cnt = 0
	local ret = {}
	for _, s in ipairs(arr) do
		ret[cnt] = s
		cnt = cnt +1
	end
	return ret
end

function _M.random_str(l, seed)
    local s = 'abcdefghijklmnhopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
 
    local ret =''
	-- os.time() is precise to second
	-- math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)) + ngx.crc32_short(seed or ""))
		-- math.randomseed(os.time() + ngx.crc32_short(seed or ""))
	math.randomseed(os.time() * 1000 + ngx.crc32_short(seed or ""))
    for i=1 ,l do
        local pos = math.random(1, string.len(s))
        ret = ret .. string.sub(s, pos, pos)
    end
 
    return ret
end
function _M.exists(name)
    if type(name)~="string" then return false end
    return os.rename(name,name) and true or false
end

function _M.isFile(name)
    if type(name)~="string" then return false end
    if not exist(name) then return false end
    local f = io.open(name)
    if f then
        f:close()
        return true
    end
    return false
end

function _M.isDir(name)
    return (exist(name) and not isFile(name))
end

function _M.split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

function _M.mkdirs(base, subdir)
    local _subs = _M.split(subdir, "/")
	if not _M.exists(base) then
		lfs.mkdir(base)
	end
	for _, s in ipairs(_subs) do
		base = base .. "/" .. s
		if not _M.exists(base) then
			if not lfs.mkdir(base) then
				ngx.log(ngx.ERR, "failed to mkdir()", base)
			end
		end
	end
end

function _M.splitext(f)
	local t = unpack(_M.split(f, "."))
	return t[#t]
end

function _M.popen(cmd, raw)
    local handle = assert(io.popen(cmd, 'r'))
	local output = assert(handle:read('*a'))
	--http://stackoverflow.com/questions/7607384/getting-return-status-and-program-output
	-- This will get a table with some return stuff
	-- rc[1] will be true, false or nil
	-- rc[3] will be the signal
	local rc = {handle:close()}
	
	if raw then 
		return output 
	end
	
	output = string.gsub(
        string.gsub(
            string.gsub(output, '^%s+', ''), 
            '%s+$', 
            ''
        ), 
        '[\n\r]+',
        ' '
    )
   return output, rc
end

function _M.table_count(tb,tag,match_str)
	local count = 0
	for index,item in pairs(tb) do
		if (item[tag[1]] == match_str[1]) and (item[tag[2]] == match_str[2]) then
			count = count + 1
		end
	end
	return count
end

function _M.parse_multipart()
	local upload = require "resty.upload"
	local cjson = require "cjson"

	local chunk_size = 4096 

	local form, err = upload:new(chunk_size)
	if not form then
		ngx.log(ngx.ERR, "failed to new upload: ", err)
		ngx.exit(500) --TODO friendly error
	end

	form:set_timeout(1000) 
	
	local form_val = {}
	
	local is_binary = false
	local last_key  -- form key
	local text_buf = '' -- buffering plain text
	local temp_filename -- temp filename to save binary data
	local temp_file  -- temp file to save binary data
	while true do
		local typ, res, err = form:read()
		if not typ then
			return
		end
		if typ == 'header' then
			if res[1] == 'Content-Disposition' then
				last_key = string.match(res[2], 'name=[\'\"]([^\'\"]+)[\'\"]')
				if last_key == nil then
					ngx.exit(500) --TODO friendly error
				end
				-- not fetching filename
			end
			if res[1] == 'Content-Type' then -- or is plain text
				is_binary = true
			end
		end
		
		if typ == 'body' then
			if is_binary then
				if temp_filename == nil then
					temp_filename =  ngx.md5(_M.random_str(24, ngx.var.remote_addr))
					temp_file = io.open(config.UPLOAD_TEMP_DIR .. "/" ..temp_filename, "wb")
				end
				temp_file:write(res)
			else
				text_buf = text_buf .. res
			end
		end
		
		if typ == 'part_end' then
			if is_binary then
				form_val[last_key] = {f = temp_filename}
				temp_file:close()
				temp_file = nil
				temp_filename = nil
			else
				form_val[last_key] = text_buf
				text_buf = ""
			end
			is_binary = false -- restore
		end

		if typ == "eof" then
			break
		end
	end

	return form_val
end

return _M
