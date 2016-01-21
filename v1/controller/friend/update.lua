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
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('friend_action')
	local _tb = {action="update_friend"}
	while true do
		if not self.uid or self.uid == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result, friends = self:update_friend()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.friends = friends
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


local function update_friend(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	-- NOTE ngx.quote_sql_str will add '' to var, DON'T ADD IT MANUALLY
	-- res, err, errno, sqlstate =
		-- db:query("SELECT count(*) as count FROM Friends WHERE uid = "..ngx.quote_sql_str(self.uid), 10)
	
	-- if res[1]['count'] == "0" then
		-- return const.ERR_API_UPDATE_FRIEND_FAILED, nil
	-- end
	
	res, err, errno, sqlstate =
		db:query("SELECT friend_id FROM Friends WHERE uid = "..ngx.quote_sql_str(self.uid), 10)

	if not res or not res[1] then 
		return const.ERR_API_UPDATE_FRIEND_FAILED, nil
	end
		
	if errno ~= nil and errno > 0 then
		return const.ERR_API_UPDATE_FRIEND_FAILED_, nil
	end
	
	local result = {}
	for k,v in pairs(res) do
		table.insert(result,k,v['friend_id'])
	end
	
	return const.API_STATUS_OK,result
end
_M.update_friend = update_friend

return _M