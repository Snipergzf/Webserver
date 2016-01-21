-- Copyright (C) 2015 gzf
-- user controller

local common = require('common')
local const = require('const')
local _, super = common.try_load_controller('_base')
local cjson = require('cjson')
local _M = {_VERSION = '0.01'}

function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.phone = arg.phone
	self.pwd = arg.pwd
	return self
end


function _M.response(self)
	local _, _em = common.try_load_model('user_action')
	local _tb = {action="reset_pwd"}
	while true do
		if not self.phone or not self.pwd or self.phone == '' or self.pwd == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		local result = self:reset()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
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



local function reset(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN
	end
	-- NOTE ngx.quote_sql_str will add '' to var, DON'T ADD IT MANUALLY
	res, err, errno, sqlstate =
		db:query("UPDATE User SET pwd = "..ngx.quote_sql_str(self.pwd).." WHERE phone = "..ngx.quote_sql_str(self.phone),10)
	
	if errno ~= nil and errno > 0 then
		return const.ERR_API_RESET_PWD_FAILED
	end
	
	return const.API_STATUS_OK
end
_M.reset = reset

return _M
