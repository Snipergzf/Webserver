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
	self.admin_account = arg.admin_account
	self.delete = arg.delete
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('event_action')
	local _tb = {action="delete_img_action"}
	while true do
		if not self.admin_account or type(self.admin_account) ~= "string" or not self.delete then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end

		local result = self:delete_img()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
		end
		--ngx.say(tostring(_)..'+'..tostring(_em))
		break
	end
	local em = _em:new(_tb)
	local _, _v = common.try_load_view('json_resp')
	local jv = _v:new(em.data, em.http_status)
	common.send_resp(jv)
end

local function delete_img(self)
	local p = config.EVENT_IMG_DIR .. "/"
	for i=1, config.EVENT_IMG_DIR_DEPTH do
		p = p .. string.sub(self.delete, i, i) .."/"
	end
	os.remove(p..self.delete)
	return const.API_STATUS_OK
end

_M.delete_img = delete_img

return _M