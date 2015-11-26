-- Copyright (C) 2015 fffonion

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
	self.event_id = tonumber(arg.event_id or '-') -- '-' is placeholder in case of arg.event_id==nil
	self.pos = tonumber(arg.pos or '0')
	self.count = tonumber(arg.count or '20')
	if self.count > 20 then
		self.count =20
	end
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('comments')
	local _tb = {action="get_comments"}
	while true do
		if not self.event_id then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result, comments = self:get()
		if result == const.API_STATUS_OK then
			_tb.comments = comments or {}
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


local function get(self)
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("cEvent")
	local r = col:find_one({_id = self.event_id}, {cEvent_comment={['$slice'] = common.zero_index_array({-self.pos-self.count+1, self.count})}, _id=1})
	if not r then
		return const.API_STATUS_OK, nil
	end
	return const.API_STATUS_OK, r
end
_M.get = get

return _M
