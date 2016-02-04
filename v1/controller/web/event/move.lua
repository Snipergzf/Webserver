	-- Copyright (C) 2015 gzf

-- event controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
local cjson = require('cjson')
local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.event_id = arg.event_id
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="move"}
	while true do
		local result = self:move()
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

local function move(self)
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN
	end
	local col = db:get_col("cEvent_tmp")
	local r = col:find_one({_id = self.event_id},{})
	if not r then
		return const.ERR_API_NO_SUCH_EVENT
	end
	
	local col = db:get_col("cEvent")
	-- the method insert returns 0 for success, or nil with error message
	local n, err = col:insert({r},1,1)
	if not n then
		return const.ERR_API_INSERT_EVENT_
	end
	
	local col = db:get_col("cEvent_tmp")
	local n, err = col:delete({_id = self.event_id},1,1)
	if n==0 then
		return const.ERR_API_DELETE_EVENT
	end
	return const.API_STATUS_OK
end
_M.move = move

return _M
