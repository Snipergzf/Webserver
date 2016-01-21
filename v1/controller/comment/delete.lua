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
	self.uid = tonumber(arg.uid or '-')
	self.comment_id = arg.comment_id
	-- self.event_id = tonumber(arg.event_id or '-')
	self.event_id = arg.event_id or '-'
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('comments')
	local _tb = {action="delete_comments"}
	while true do
		if not self.event_id or not self.comment_id or not self.uid then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result = self:get()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
		else -- >0
			_tb.result="failed"
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
		return const.ERR_API_DATABASE_DOWN
	end
	local col = db:get_col("cEvent")
	--update({_id:3},{$pull:{cEvent_comment:{speaker_id:12}}})
	--[[ local n, err = col:update({_id = self.event_id}, {["$pull"] = {cEvent_comment = {comment_id = self.comment_id}}}, 0, 0, 1)
	if n == nil or n < 1 then
		ngx.log(ngx.ERR, "[LI] del comment failed: ", n, " ", err)
		return const.ERR_API_DEL_COMMENT_FAILED
	end]]--
	local r = col:find_one({_id = self.event_id, cEvent_comment={['$elemMatch']={comment_id = self.comment_id}}}, {cEvent_comment = 1, _id = 0})
	if not r then
		return const.ERR_API_DEL_COMMENT_FAILED
	end
	local n, err, dt = col:update({_id = self.event_id}, {["$pull"] = {cEvent_comment = {comment_id = self.comment_id, speaker_id = self.uid}}}, 0, 0, 0)
	-- n always returns 1 here, for http://stackoverflow.com/questions/26144405/mongodb-update-pull-always-return-1
	-- so we can only try to find it
	local r = col:find_one({_id = self.event_id, cEvent_comment={['$elemMatch']={comment_id = self.comment_id}}}, {cEvent_comment = 1, _id = 0})
	if not r then
		return const.API_STATUS_OK
	end
	return const.ERR_API_DEL_COMMENT_FAILED
end
_M.get = get

return _M
