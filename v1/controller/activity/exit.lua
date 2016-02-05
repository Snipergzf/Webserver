-- Copyright (C) 2015 gzf

-- activity controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
local cjson = require('cjson')
local _M = {_VERSION = '0.01'}

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
	local _tb = {action="exit"}
	while true do
		if not self.uid or self.uid == '' or not self.a_id or self.a_id == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result = self:exit_()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
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

local function exit_(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN
	end
	res, err, errno, sqlstate =
		db:query("SELECT participants FROM Activity WHERE a_id="..ngx.quote_sql_str(self.a_id), 10)
	if errno ~= nil and errno > 0 then
		return const.ERR_API_SEARCH_ACTIVITY
	end
	
	local participants = res[1]['participants']
	local tb = common.split(participants,";")
	local tb_ = common.table_element_delete(tb,self.uid)
	local participants_ = common.tabletostring(tb_,";")
	res, err, errno, sqlstate =
		db:query("UPDATE Activity SET participants ='"..participants_.."' WHERE a_id="..ngx.quote_sql_str(self.a_id), 10)
	if errno ~= nil and errno > 0 then
		return const.ERR_API_UPDATE_ACTIVITY
	end
	
	return const.API_STATUS_OK
end
_M.exit_ = exit_

return _M
