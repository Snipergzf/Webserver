-- Copyright (C) 2015 gzf

-- event controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
-- local _debug = require('_debug')
local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.cEvent_name = arg.cEvent_name
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="search_by_time"}
	while true do
		if not self.cEvent_name or common.trim(self.cEvent_name) == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result, event, event_tmp = self:search()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.event = event or {}
			_tb.event_tmp = event_tmp or {}
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


local function search(self)
	local tb= {}
	local tb_tmp = {}
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("cEvent")
	local cursor = col:find({cEvent_name = {["$regex"] = ngx.unescape_uri(self.cEvent_name),["$options"] = 'i'}},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
		cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1,cEvent_owner=1})
	for index, item in cursor:pairs() do
			table.insert(tb,index,item)
	end
	local col = db:get_col("cEvent_tmp")
	local cursor = col:find({cEvent_name = {["$regex"] = ngx.unescape_uri(self.cEvent_name),["$options"] = 'i'}},{_id=1,cEvent_name=1,cEvent_time=1,cEvent_content=1,
		cEvent_theme=1,cEvent_place=1,cEvent_provider=1,cEvent_publish=1,share_num=1,click_num=1,participate_num=1,cEvent_owner=1})
	for index, item in cursor:pairs() do
		table.insert(tb_tmp,index,item)
	end
	if #tb ==0 and #tb_tmp == 0 then
		return const.ERR_API_NO_SUCH_EVENT,nil,nil
	end
	return const.API_STATUS_OK, tb, tb_tmp
end
_M.search = search

return _M