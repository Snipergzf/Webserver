-- Copyright (C) 2015 fffonion

-- base view

local _M = { _VERSION = '0.01' }


function _M.new(self)
    return setmetatable(
		{
			http_status = 200
		}
		, { __index = _M }
	)
end

return _M