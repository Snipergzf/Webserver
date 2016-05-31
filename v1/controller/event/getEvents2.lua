-- Copyright (C) 2015 gzf
-- event controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
local _M = {_VERSION = '0.01'}
local _debug = require('_debug')

function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.imei = arg.imei
	self.class = arg.class or ""
	self.pos = tonumber(arg.pos or '0')
	self.count = tonumber(arg.count or '10')
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="get_event"}
	while true do
		if not self.imei or common.trim(self.imei) == "" then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end

		local result, event = self:getEvent()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.event = event or {}
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


local function getEvent(self)
	local mysql_db = common.get_dbconn()
	if not mysql_db then
		return const.ERR_API_DATABASE_DOWN
	end
	res, err, errno, sqlstate =
		mysql_db:query("SELECT onlinetime from Tourists WHERE imei="..ngx.quote_sql_str(self.imei), 10)
	if res == nil or res[1] == nil then
		res, err, errno, sqlstate =
			mysql_db:query("INSERT INTO Tourists (`onlinetime`,`imei`) VALUES("..tostring(ngx.now())..","..ngx.quote_sql_str(self.imei)..")", 10)
	elseif tonumber(res[1]['onlinetime'])==ngx.now() then
		--ngx.log(ngx.ERR,type(res[1]['onlinetime']),": ",type(ngx.time()))
		return ERR_API_REQUEST_FREQUENTLY
	else
		res, err, errno, sqlstate =
			mysql_db:query("UPDATE Tourists SET onlinetime="..tostring(ngx.now()).." WHERE imei="..ngx.quote_sql_str(self.imei), 10)
	end
	
	local id_list = {}
	local event_list = {}
	local red = common.get_redis()
	if not red then
		return const.ERR_API_REDIS_DOWN, nil
	end
	local res, err = red:zrange(self.class, self.pos, self.pos+self.count-1)
	--if select range over the max length of the list in the redis
	-- there will get a empty table, nothing about err(will get a nil)
	for k,v in pairs(res) do
		id_list[k] = v
	end
	for k,v in pairs(id_list) do
		local res, err = red:get(v)
		if res then
			event_list[k] = res
		end
	end
	return const.API_STATUS_OK, event_list
end
_M.getEvent = getEvent

return _M