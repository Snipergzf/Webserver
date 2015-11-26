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
	local c=require('cjson')
	--ngx.say("er", c.encode(arg))
	self.uid = arg['uid']
	self.friend_id = arg['friend_id']
	self.certificate = arg['certificate']
	self.expiration_time = arg['expiration_time']
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('user_action')
	local _tb = {action="add_friend"}
	while true do
		if not self.uid or not self.friend_id or not self.certificate or not self.expiration_time then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG, errmsg = const[const.ERR_API_MISSING_ARG]}
			break
		end
		
		local result = self:add_friend()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
		else -- >0
			_tb.code = result
			_tb.errmsg = const[result]
		end
		--ngx.say(tostring(_)..'+'..tostring(_em))
		break
	end
	local em = _em:new(_tb)
	local _, _v = common.try_load_view('json_resp')
	local jv = _v:new(em.data, em.http_status)
	common.send_resp(jv)
end


local function add_friend(self)
	local db = common.get_dbconn()
	if not db then
		ngx.log(ngx.ERR, "[LI] failed to connect: ", err, ": ", errno, " ", sqlstate)
		return const.ERR_API_DATABASE_DOWN, nil
	end
	-- NOTE ngx.quote_sql_str will add '' to var, DON'T ADD IT MANUALLY
	res, err, errno, sqlstate =
		db:query("INSERT INTO add_friends (`uid`, `friend_id`,`certificate`,`expiration_time`) VALUES ("..
			ngx.quote_sql_str(self.uid)..", "..ngx.quote_sql_str(self.friend_id)..", "..
			ngx.quote_sql_str(self.certificate)..", "..ngx.quote_sql_str(self.expiration_time)..")"
		, 10)
	ngx.log(ngx.ERR, "[LI] result: ", err, ": ", errno, ": ", sqlstate, ".")
	
	if errno ~= nil and errno > 0 then
		return const.ERR_API_ADD_FRIEND_FAILED, nil
	end
	
	return const.API_STATUS_OK
end
_M.add_friend = add_friend

return _M