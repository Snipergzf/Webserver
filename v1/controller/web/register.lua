-- Copyright (C) 2015 fffonion

-- register controller

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
	self.account = arg.account
	self.pwd = arg.pwd
	return self
end


function _M.response(self)
	local _, _em = common.try_load_model('web_action')
	local _tb = {action="register"}
	while true do
		if not self.account or not self.pwd or common.trim(self.account) == '' or common.trim(self.pwd) == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		local result = self:reg()
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



local function reg(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN
	end
	-- NOTE ngx.quote_sql_str will add '' to var, DON'T ADD IT MANUALLY
	res, err, errno, sqlstate =
		db:query("INSERT INTO Admin (`account`, `pwd`) VALUES ("..
			ngx.quote_sql_str(self.account)..", "..ngx.quote_sql_str(self.pwd)..")"
		, 10)
	
	if errno ~= nil and errno > 0 then
		return const.ERR_API_REG_FAILED_USER_EXISTS
	end
	
	return const.API_STATUS_OK
end
_M.reg = reg

return _M
