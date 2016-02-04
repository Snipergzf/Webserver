-- Copyright (C) 2015 gzf

-- event controller

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
	-- self.count = tonumber(arg.count or '20')
	-- if self.count > 20 then
		-- self.count =20
	-- end
	self.start_time = arg.start_time
	self.end_time = arg.end_time
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="search_by_time"}
	while true do
		-- if not self.uid or self.uid == "" then
			-- _, _em = common.try_load_model('error')
			-- _tb = {code = const.ERR_API_MISSING_ARG}
			-- break
		-- end

		local result, event = self:search()
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


local function search(self)
	local tb = {}
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("cEvent")
	-- local r = col:find_one({_id = self.event_id},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
		-- cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1})
	local cursor = col:find({},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
		cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1,cEvent_owner=1})
	for index, item in cursor:pairs() do
		-- local time_length = table.getn(item["cEvent_time"])
		if (tonumber(self.start_time)<item["cEvent_time"][1]) and (item["cEvent_time"][1]<tonumber(self.end_time)) then
			table.insert(tb,index,item)
		end
	end
	if #tb == 0 then
		return const.ERR_API_NO_SUCH_EVENT,nil
	end
	return const.API_STATUS_OK, tb
end
_M.search = search

return _M