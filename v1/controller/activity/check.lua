-- Copyright (C) 2015 gzf
-- activity controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
local cjson = require('cjson')
local _M = {_VERSION = '0.01'}
local _debug = require('_debug')
function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.uid = arg.uid
	self.a_id = arg.a_id
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('activity_action')
	local _tb = {action="check"}
	while true do
		if not self.uid or self.uid == '' or not self.a_id or self.a_id == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result,activity = self:check()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.activity=activity
		else -- >0
			_tb.code = result
		end
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
		return const.ERR_API_DATABASE_DOWN,nil
	end
	res, err, errno, sqlstate =
		db:query("SELECT * FROM Activity WHERE a_id="..ngx.quote_sql_str(self.a_id), 10)
	if not res or not res[1] or res[1] == ngx.null then
		return const.ERR_API_SEARCH_ACTIVITY,nil
	end
	
	return const.API_STATUS_OK,res[1]
end
_M.check = check

return _M
