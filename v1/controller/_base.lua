-- Copyright (C) 2015 fffonion

-- base controller


local _M = { _VERSION = '0.01' }

function _M.new(self, status, errmsg)
    return setmetatable(
		{}
		, { __index = _M }
	)
end


function _M.bbb(self)
    ngx.say('bbb')
end
return _M