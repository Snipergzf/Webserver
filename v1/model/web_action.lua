-- Copyright (C) 2015 fffonion

-- user_action model

local common = require('common')
local _, super = common.try_load_model('_base')

local _M = {_VERSION = '0.01'}

function _M.new(_, arg)

    local self = setmetatable(
		super:new(arg.code, arg.errmsg)
		, { __index = _M} 
	)
	self.data.web_action = {
		action = arg.action,
		result = arg.result or 'failed'
	}
	return self
end


return _M