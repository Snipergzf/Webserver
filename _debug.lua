-- Copyright (C) 2015 fffonion

-- debugging tools

local _M = {_VERSION = '0.01'}

function _M.print_r(tbl, pref)
	for k,v in pairs(tbl) do 
		if type(v) == 'table' then
			ngx.say((pref or "|-"), k, "\t", "<table>")
			_M.print_r(v, "  "..(pref or "|-"))
		else
			if type(v) == 'function' then
				v = "   <function>"
			end
			ngx.say((pref or "|-"), k, "\t", v)
		end
	end
end

return _M