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
	self.uid = arg.uid
	self.class = arg.class or ""
	self.pos = tonumber(arg.pos or '0')
	self.count = tonumber(arg.count or '10')
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="get_event"}
	while true do
		if not self.uid or common.trim(self.uid) == "" then
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
		break
	end
	local em = _em:new(_tb)
	local _, _v = common.try_load_view('json_resp')
	local jv = _v:new(em.data, em.http_status)
	common.send_resp(jv)
end


local function getEvent(self)
	local id_list = {}
	local event_list = {}
	local red = common.get_redis()
	if not red then
		return const.ERR_API_REDIS_DOWN, nil
	end
	while true do
		if self.class == "recom" then
			local db = common.get_mongo()
			if not db then
				return const.ERR_API_DATABASE_DOWN, nil
			end
			local col = db:get_col("cUser")
			-- local recom_events = col:find_one({_id=self.uid},{pushed_event=1})
			-- if recom_events == nil or recom_events['pushed_event'] == nil then
				-- break
			-- end
			-- for var = 1,self.count,1 do
				-- id_list[var] = recom_events['pushed_event'][self.pos+var-1]
			-- end
			-- break
			local recom_events = col:find_one({_id=self.uid},{recom_event=1})
			if recom_events == nil or recom_events['recom_event'] == nil then
				break
			end
			local tmp_list = recom_events['recom_event']
			for var = 1,self.count,1 do
				id_list[var] = tmp_list[self.pos+var-1]
			end
			break
			
		else
			local res, err = red:zrange(self.class, self.pos, self.pos+self.count-1)
			--if select range over the max length of the list in the redis
			-- there will get a empty table, nothing about err(will get a nil)
			for k,v in pairs(res) do
				id_list[k] = v
			end
			break
		end
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