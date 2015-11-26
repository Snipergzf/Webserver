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
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('user_action')
	local _tb = {action="get_avatar"}
	while true do
		if not self.uid then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result, filepath = self:get()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.avatar = filepath
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


local function get(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	res, err, errno, sqlstate =
		db:query("SELECT avatar FROM User WHERE id="..ngx.quote_sql_str(self.uid), 10)
	if not res or not res[1] then
		return const.ERR_API_NO_SUCH_USER, nil
	end
	if res[1]['avatar'] == ngx.null then
		return const.API_STATUS_OK, config.HOST .. "/images/avatar/"..config.AVATAR_DEFAULT_FILE
	end
	return const.API_STATUS_OK, config.HOST .. "/images/avatar/"..res[1]['avatar']
end
_M.get = get

return _M