-- Copyright (C) 2015 fffonion

-- login controller

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
	self.uid = arg.uid
	self.upload = arg.upload
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('user_action')
	local _tb = {action="set_avatar"}
	while true do
		if not self.uid or type(self.uid) ~= "string"  or  
			not self.upload or not self.upload.f then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result, avatar_path = self:update_avatar()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.avatar=avatar_path
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


local function update_avatar(self)
	local avatar_dest_path = ""
	-- generate B-TREE prefix
	for i=1, config.AVATAR_DIR_DEPTH do
		avatar_dest_path = avatar_dest_path .. string.sub(self.upload.f, i, i) .."/"
	end
	-- make all parent directories
	common.mkdirs(config.AVATAR_DIR, avatar_dest_path)
	-- hard coded
	-- this is filename
	avatar_dest_path = config.AVATAR_DIR .. "/" .. avatar_dest_path..self.upload.f
	-- move to destination
	local ret, msg = os.rename(config.UPLOAD_TEMP_DIR.. "/" ..self.upload.f, avatar_dest_path..".jpg")
	if not ret then
		ngx.log(ngx.ERR, "failed to rename:", msg, config.UPLOAD_TEMP_DIR.. "/" ..self.upload.f, avatar_dest_path)
		return const.ERR_API_FAILED_SAVING_AVATAR
	end
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	res, err, errno, sqlstate =
		db:query("SELECT avatar FROM User WHERE id="..ngx.quote_sql_str(self.uid), 10)
	if res and res[1] and res[1]['avatar'] ~= ngx.null then
		local p = config.AVATAR_DIR .. "/"
		for i=1, config.AVATAR_DIR_DEPTH do
			p = p .. string.sub(res[1]['avatar'], i, i) .."/"
		end
		os.remove(p..res[1]['avatar'])
	end
	res, err, errno, sqlstate =
		db:query("UPDATE User SET avatar = '"..self.upload.f..".jpg' WHERE id="..ngx.quote_sql_str(self.uid), 10)
	return const.API_STATUS_OK, config.HOST .. "/images/avatar/"..self.upload.f..".jpg"
end
_M.update_avatar = update_avatar

return _M