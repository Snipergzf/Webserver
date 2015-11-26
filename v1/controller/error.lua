-- Copyright (C) 2015 fffonion

-- error controller

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
	self.arg = {
		code = arg.code,
		errmsg = arg.errmsg
	}
	if config.DEBUG and arg._debug then
		self.arg._debug = arg._debug
	end
	return self
end



function _M.response(self)
	local _, _em = common.try_load_model('error')
	--ngx.say(tostring(_)..'+'..tostring(_em))
	local em = _em:new(self.arg)
	local _, _v = common.try_load_view('json_resp')
	local jv = _v:new(em.data, em.http_status)
	common.send_resp(jv)
end

return _M