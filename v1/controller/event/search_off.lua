-- Copyright (C) 2015 gzf

-- event controller

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
	self.event_id = arg.event_id
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="search_event"}
	while true do
		if not self.uid or self.uid == "" then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end

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
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("cEvent_off")
	local r = col:find_one({_id = self.event_id},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
		cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1})
	if not r then
		return const.ERR_API_NO_SUCH_EVENT,nil
	end
	return const.API_STATUS_OK, r
end
_M.search = search

return _M