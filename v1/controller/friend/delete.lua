-- Copyright (C) 2015 gzf

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
	self.friend_id = arg.friend_id
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('friend_action')
	local _tb = {action="delete_friend"}
	while true do
		if not self.uid or not self.friend_id then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result = self:delete_friend()
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


local function delete_friend(self)
	local db = common.get_dbconn()
	if not db then
		ngx.log(ngx.ERR, "[LI] failed to connect: ", err, ": ", errno, " ", sqlstate)
		return const.ERR_API_DATABASE_DOWN, nil
	end
	
	res,err,errno,sqlstate = 
		db:query("SELECT COUNT(*) AS count FROM Friends WHERE uid = "..ngx.quote_sql_str(self.uid).."AND friend_id = "..ngx.quote_sql_str(self.friend_id),10)
		
	if res[1]['count'] == "0" then
		return const.ERR_API_DELETE_FRIEND_FAILED, nil
	end
	
	-- NOTE ngx.quote_sql_str will add '' to var, DON'T ADD IT MANUALLY
	res, err, errno, sqlstate =
		db:query("DELETE FROM Friends WHERE uid = "..
			ngx.quote_sql_str(self.uid).."AND friend_id = "..ngx.quote_sql_str(self.friend_id), 10)
	ngx.log(ngx.ERR, "[LI] result: ", err, ": ", errno, ": ", sqlstate, ".")
	
	return const.API_STATUS_OK
end
_M.delete_friend = delete_friend

return _M