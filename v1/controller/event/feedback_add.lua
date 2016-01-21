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
	self.event_id = arg.event_id
	self.share_num = arg.share_num
	self.click_num = arg.click_num
	self.participate_num = arg.participate_num
    return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="feedback_add"}
	while true do
		if not self.event_id  then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result = self:feedback_add()
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


local function feedback_add(self)
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("cEvent")
	if self.share_num and self.share_num ~= "null" and self.share_num ~= ngx.null and self.share_num ~= '' then
		local n, err = col:update({_id = self.event_id},{["$inc"] = {share_num = 1}})
		if err then
			ngx.log(ngx.ERR, "[LI] feedback failed: ", n, " ", err)
			return const.ERR_API_FEEDBACK_FAILED
		end
	end
	
	if self.click_num and self.click_num ~= "null" and self.click_num ~= ngx.null and self.click_num ~= '' then
		local n, err = col:update({_id = self.event_id},{["$inc"] = {click_num = 1}})
		if err then
			return const.ERR_API_FEEDBACK_FAILED
		end
	end
	
	if self.participate_num and self.participate_num ~= "null" and self.participate_num ~= ngx.null and self.participate_num ~= '' then
		local n, err = col:update({_id = self.event_id},{["$inc"] = {participate_num = 1}})
		if err then
			return const.ERR_API_FEEDBACK_FAILED
		end
	end
	
	return const.API_STATUS_OK
end
_M.feedback_add = feedback_add

return _M
