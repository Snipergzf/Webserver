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
	self.uid = tonumber(arg.uid or '-')
	self.content = arg.content
    return self
end

function _M.response(self)
	local _, _em = common.try_load_model('comments')
	local _tb = {action="add_comments"}
	while true do
		if not self.event_id or not self.uid or not self.content then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result, cmt = self:get()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.comments = {[0] = cmt}
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
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("cEvent")
	local cmt = {
		speaker_id = self.uid,
		content = self.content,
		comment_time = ngx.time(),
		comment_id = common.random_str(20, tostring(self.uid).."-comment")
	}
	local n, err = col:update({_id = self.event_id}, {["$push"] = {
			cEvent_comment = cmt
		}}, 0, 0, 1)
	if n == nil or n < 1 then
		ngx.log(ngx.ERR, "[LI] add comment failed: ", n, " ", err)
		return const.ERR_API_ADD_COMMENT_FAILED
	end
	return const.API_STATUS_OK, cmt
end
_M.get = get

return _M
