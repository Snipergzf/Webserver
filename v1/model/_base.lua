-- Copyright (C) 2015 fffonion

-- base response model

local const = require('const')

local _M = { _VERSION = '0.01' }


function _M.new(self, status, errmsg)
    return setmetatable(
		{
			data = {
				status = status or 0,
				errmsg = errmsg or const[status],
			}
		}
		, {
		__index = _M,
		__newindex = function(t, k, v)
            error('attempt to set undefined var')
		end
	   }
	)
end

return _M