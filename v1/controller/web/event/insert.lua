	-- Copyright (C) 2015 gzf

-- event controller

local common = require('common')
local const = require('const')
local config = require('config')
local _debug = require('_debug')
local _, super = common.try_load_controller('_base')
local cjson = require('cjson')
local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.admin_account = arg.admin_account
	self.event_id = arg.event_id
	-- self.cEvent_name = arg.cEvent_name
	-- self.cEvent_time = arg.cEvent_time
	-- self.cEvent_content = arg.cEvent_content
	-- self.cEvent_theme = arg.cEvent_theme
	-- self.cEvent_place = arg.cEvent_place
	-- self.cEvent_provider = arg.cEvent_provider
	self.detail = arg.detail
	-- self.event_detail = arg.event_detail
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="insert"}
	while true do
		if not self.admin_account or self.admin_account == '' or not self.event_id or self.event_id == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result = self:insert()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
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

local function insert(self)
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN
	end
	local col = db:get_col("cEvent_tmp")
	local r = col:find_one({_id = self.event_id},{})
	if r then
		return const.ERR_API_INSERT_EVENT
	end
	local event_doc = cjson.decode(self.detail)
	local n,err = col:insert({event_doc},1,1)
	-- local r = col:find_one({_id=self.event_id})
	-- local n,err = col:insert({{_id = self.event_id, cEvent_name = self.cEvent_name,cEvent_time=self.cEvent_time,
		-- cEvent_content=self.cEvent_content,cEvent_theme=self.cEvent_theme,cEvent_place=self.cEvent_place,
		-- cEvent_provider=self.cEvent_provider}},1,1)
	
	if err then
		return const.ERR_API_INSERT_EVENT_
	end
	
	return const.API_STATUS_OK
end
_M.insert = insert

return _M
