-- Copyright (C) 2015 gzf

-- course_action model

local common = require('common')
local _, super = common.try_load_model('_base')

local _M = {_VERSION = '0.01'}

function _M.new(_, arg)

    local self = setmetatable(
		super:new(arg.code, arg.errmsg)
		, { __index = _M} 
	)
	self.data.course_action = {
		action = arg.action,
		result = arg.result or 'failed',
		course = arg.course
	}
	return self
end


return _M