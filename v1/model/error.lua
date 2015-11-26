-- Copyright (C) 2015 fffonion

-- error model

local common = require('common')
local _, super = common.try_load_model('_base')

local _M = {_VERSION = '0.01'}

function _M.new(_, arg)
    local self = setmetatable(
		super:new(arg.code, arg.errmsg)
		, { __index = _M} 
	)
	self.data._debug =  arg._debug
	local code = math.floor(arg.code/100) + 200
	if code >= 600 or (code < 200 and code ~= 100) then
		code = 500
	else
		-- 20000~29999 is all http code 200
		if code > 200 and code < 300 then
			code = 200
		end
	end
	self.http_status = code
	return self
end


return _M