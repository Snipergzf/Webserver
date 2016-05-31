-- Copyright (C) 2015 gzf

-- event controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
local _M = {_VERSION = '0.01'}
-- local _debug = require('_debug')

function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.imei = arg.imei
	self.class = arg.class or ""
	self.pos = tonumber(arg.pos or '0')
	self.count = tonumber(arg.count or '10')
	self.size = tonumber(arg.size or '0')
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

		local result, event, dbsize = self:getEvent()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.event = event or {}
			_tb.dbsize = dbsize or 0
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
	if res[1] == nil then
		res, err, errno, sqlstate =
			mysql_db:query("INSERT INTO Tourists (`onlinetime`,`imei`) VALUES("..tostring(ngx.now())..","..ngx.quote_sql_str(self.imei)..")", 10)
	elseif tonumber(res[1]['onlinetime'])==ngx.now() then
		--ngx.log(ngx.ERR,type(res[1]['onlinetime']),": ",type(ngx.time()))
		return ERR_API_REQUEST_FREQUENTLY
	else
		res, err, errno, sqlstate =
			mysql_db:query("UPDATE Tourists SET onlinetime="..tostring(ngx.now()).." WHERE imei="..ngx.quote_sql_str(self.imei), 10)
	end
	
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("cEvent")
	local dbsize = col:count({})
	local delta = 0
	local count = 0
	local pos = 0
	if self.size ~= 0 then
		delta = dbsize-self.size
	end
	pos = self.pos+delta
	if pos>=dbsize then
		return const.ERR_API_NO_MORE_EVENTS, nil
	end
	if (pos+self.count)>=dbsize then
		count = dbsize-pos
	else
		count = self.count
	end
	if self.class == "" then
		-- local result = col:find({},{cEvent_publish=1}):sort({cEvent_publish=-1})
		local result = col:find({},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
			cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1}):sort({cEvent_publish=-1})
		local r = {}
		for var=1,count,1 do
			r[var] = result[pos+var]
		end
		-- _debug.print_r(r)
		return const.API_STATUS_OK, r, dbsize
	else
		local result = col:find({cEvent_theme=self.class},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
			cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1}):sort({cEvent_publish=-1})
		local r = {}
		for var=1,count,1 do
			r[var] = result[pos+var]
		end
		return const.API_STATUS_OK, r, dbsize
	end
	-- use query() to query the specific events while find() can not do that
	-- if self.class == "" then
		-- local cursorID, r, t = col:query({},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
			-- cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1},self.pos,self.count)
		-- if not r then
			-- return const.ERR_API_NO_SUCH_EVENT,nil
		-- end
		-- return const.API_STATUS_OK, r
	-- else
		-- local cursorID, r, t = col:query({cEvent_theme=self.class},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
			-- cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1},self.pos,self.count)
		-- if not r then
			-- return const.ERR_API_NO_SUCH_EVENT,nil
		-- end
		-- return const.API_STATUS_OK, r
	-- end

end
_M.getEvent = getEvent

return _M