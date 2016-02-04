-- Copyright (C) 2015 gzf

-- event controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')

local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.admin_account = arg.admin_account
	self.upload = arg.upload
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="push_img_action"}
	while true do
		if not self.admin_account or type(self.admin_account) ~= "string" or  
			not self.upload or not self.upload.f then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end

		local result, event_img_path = self:push_img()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.event_img=event_img_path
		else -- >0
			_tb.code = result
		end
		--ngx.say(tostring(_)..'+'..tostring(_em))
		break
	end
	local em = _em:new(_tb)
	local _, _v = common.try_load_view('json_resp')
	local jv = _v:new(em.data, em.http_status)
	common.send_resp(jv)
end


local function push_img(self)

	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	res, err, errno, sqlstate =
		db:query("SELECT * FROM Admin WHERE account ="..ngx.quote_sql_str(self.admin_account), 10)
	if not res[1] then
		return const.ERR_API_NO_SUCH_USER,nil
	end
	
	local event_img_dest_path = ""
	-- generate B-TREE prefix
	for i=1, config.EVENT_IMG_DIR_DEPTH do
		event_img_dest_path = event_img_dest_path .. string.sub(self.upload.f, i, i) .."/"
	end
	-- make all parent directories
	common.mkdirs(config.EVENT_IMG_DIR, event_img_dest_path)
	-- hard coded
	-- this is filename
	event_img_dest_path = config.EVENT_IMG_DIR .. "/" .. event_img_dest_path..self.upload.f
	-- move to destination
	local ret, msg = os.rename(config.UPLOAD_TEMP_DIR.. "/" ..self.upload.f, event_img_dest_path..".jpg")
	if not ret then
		ngx.log(ngx.ERR, "failed to rename:", msg, config.UPLOAD_TEMP_DIR.. "/" ..self.upload.f, event_img_dest_path)
		return const.ERR_API_FAILED_SAVING_EVENT_IMG,nil
	end
	
	return const.API_STATUS_OK, config.HOST .. "/images/event/"..self.upload.f..".jpg"
	-- res, err, errno, sqlstate =
		-- db_:query("SELECT avatar FROM User WHERE id="..ngx.quote_sql_str(self.uid), 10)
	-- if res and res[1] and res[1]['avatar'] ~= ngx.null then
		-- local p = config.AVATAR_DIR .. "/"
		-- for i=1, config.AVATAR_DIR_DEPTH do
			-- p = p .. string.sub(res[1]['avatar'], i, i) .."/"
		-- end
		-- os.remove(p..res[1]['avatar'])
	-- end
	-- res, err, errno, sqlstate =
		-- db:query("UPDATE User SET avatar = '"..self.upload.f..".jpg' WHERE id="..ngx.quote_sql_str(self.uid), 10)
end
_M.push_img = push_img

return _M
