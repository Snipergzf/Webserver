-- Copyright (C) 2015 gzf

-- friend controller

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
	self.group_id = arg.group_id
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('group_action')
	local _tb = {action="check_group_info"}
	while true do
		if not self.uid or common.trim(self.uid) == '' or not self.group_id or common.trim(self.group_id) == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result,group_info = self:check_info()
		if result == const.API_STATUS_OK then
			_tb.result = "succeed"
			_tb.group_info = group_info
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


local function check_info(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	
	res,err,errno,sqlstate = 
		db:query("SELECT * FROM groups WHERE group_id = "..ngx.quote_sql_str(self.group_id),10)
	
	if not res or not res[1] then
		return const.ERR_API_NO_SUCH_GROUP, nil
	end
	
	return const.API_STATUS_OK,res[1]
end
_M.check_info = check_info

return _M
