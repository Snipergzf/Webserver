-- Copyright (C) 2015 gzf

-- friend controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
local _debug = require('_debug')
local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.uid = arg.uid
	self.search_name = arg.search_name
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('friend_action')
	local _tb = {action="search_friend"}
	while true do
		if not self.uid or not self.search_name then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result,_id,_name,_user_rank,_avatar = self:search_friend()
		if result == const.API_STATUS_OK then
			_tb.result = "succeed"
			_tb.uid = _id
			_tb.name = _name
			_tb.user_rank = _user_rank
			_tb.avatar = _avatar
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


local function search_friend(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	
	res,err,errno,sqlstate = 
		db:query("SELECT id,name,user_rank,avatar FROM User WHERE phone = "..ngx.quote_sql_str(self.search_name),10)
	--ngx.log(ngx.ERR,"query result: ",err,": ",errno,": ",res)
	--_debug.print_r(res)
	if res[1] == nil then
		return const.ERR_API_SEARCH_FRIEND_FAILED, nil
	end
	local id = res[1]['id']
	local name = res[1]['name']
	local user_rank = res[1]['user_rank']
	local avatar = res[1]['avatar']
	return const.API_STATUS_OK,id,name,user_rank,avatar
end
_M.search_friend = search_friend

return _M