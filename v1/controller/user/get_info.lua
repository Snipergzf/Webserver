-- Copyright (C) 2015 gzf
-- User controller

local common = require('common')
local const = require('const')
local _, super = common.try_load_controller('_base')
local config = require('config')
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
	local _,_em = common.try_load_model('user_action')
	local _tb = {action = "get_info"}
	while true do
		if not self.uid or self.uid == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		local result, info = self:get_info()
		if result == const.API_STATUS_OK then
			_tb.result = "succeed"
			_tb.info = info
		else 
			_tb.code = result
		end
		break
	end
	local em = _em:new(_tb)
	local _,_v = common.try_load_view('json_resp')
	local jv = _v:new(em.data,em.http_status)
	common.send_resp(jv)
end

local function get_info(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	res, err, errno, sqlstate = 
		db:query("SELECT name,avatar FROM User WHERE id ="..ngx.quote_sql_str(self.uid), 10)
	
	if not res or not res[1] then
		return const.ERR_API_NO_SUCH_USER, nil
	end
	
	if errno ~= nil and errno > 0 then
		return const.ERR_API_SEARCH_USER_FAILED,nil
	end
	
	--if res[1] == nil then
		--return const.ERR_API_SEARCH_USER_FAILED_, nil
	--end
	local tb = {}
	tb.name = res[1]['name']
	if not res[1]['avatar'] or res[1]['avatar'] == ngx.null then
		tb.avatar = 'default'
	else
		tb.avatar = config.HOST .. "/images/avatar/"..res[1]['avatar']
	end
	return const.API_STATUS_OK,tb
end
_M.get_info = get_info
return _M



