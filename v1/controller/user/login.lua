-- Copyright (C) 2015 fffonion

-- login controller

local common = require('common')
local const = require('const')
local _, super = common.try_load_controller('_base')

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
	local _tb = {action="login"}
	while true do
		if not self.phone or not self.pwd then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		local result, token, uid = self:check()
		if result == const.API_STATUS_OK then
			_tb.token = token
			_tb.uid = uid
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

local function check(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	-- NOTE ngx.quote_sql_str will add '' to var, DON'T ADD IT MANUALLY
	res, err, errno, sqlstate =
		db:query("SELECT id, pwd FROM User WHERE phone = "..ngx.quote_sql_str(self.phone), 10)
	local cjson = require "cjson"

	if not res or not res[1] then
		return const.ERR_API_NO_SUCH_USER, nil
	end
	
	if res[1]['pwd'] ~= self.pwd then
		return const.ERR_API_LOGIN_FAILED_WRONG_PWD, nil
	end
	
	local uid = res[1]['id']
	local token = common.random_str(32, tostring(self.phone))
	res, err, errno, sqlstate =
		db:query("INSERT INTO Token SET uid='"..uid.."', token='"..token.."', timeout="..(ngx.time() + const.SESSION_EXPIRE) .." "..
		"ON DUPLICATE KEY UPDATE token ='"..token.."', timeout="..(ngx.time() + const.SESSION_EXPIRE), 10)
	if not res then
		ngx.log(ngx.ERR, "[LI] bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return const.ERR_API_TOKEN_GENERATION_FAILED, nil
	end
	return const.API_STATUS_OK, token, uid
end
_M.check = check

return _M
