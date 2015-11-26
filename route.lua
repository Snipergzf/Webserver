-- Copyright (C) 2015 fffonion

-- routing module

local common = require('common')
local const = require('const')
local acl = require('acl')

local _M = { _VERSION = '0.01' }

function _M.new(_)
    return setmetatable({}, { __index = _M })
end

function _M.load_controller(self, cmd, arg)
	local s, c = common.try_load_controller(cmd)
	--ngx.say(tostring(c))
	if not s then
		--ngx.log(ngx.ERR, "[LI] require() failed: ", c)
		return self:load_controller("error", {code=const.ERR_API_NOT_FOUND, _debug=c})
	end
	local acl_method = acl.acl_list[cmd]
	if acl_method ~= nil and acl.check_acl(arg, acl_method) ~= true then
		return self:load_controller("error", {code=const.ERR_INVALID_TOKEN})
	end
	local _c = c:new(arg)
	return _c:response()
end

function _M.do_route(self, cmd, arg_funcs)
	local arg = {}
	-- copy form variables to a lua table
	if arg_funcs then
		for _ = 1, #arg_funcs do
			local args = arg_funcs[_]()
			for key, val in pairs(args) do
				arg[key] = val
			end
		end
	end
	
	if cmd == 'error' then
		-- forbit direct error.lua call
		self:load_controller("error", {code=const.ERR_API_NOT_FOUND})
	else
		local s, c = pcall(_M.load_controller, self, cmd, arg)
		if not s then
			ngx.log(ngx.ERR, "[LI] load_controller() failed: ", c)
			local err_tb = {code=const.ERR_API_UNAVALIABLE}
			return self:load_controller("error", {code=const.ERR_API_UNAVALIABLE, _debug=c})
		end
	end

end

return _M
