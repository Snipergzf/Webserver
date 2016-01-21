-- Copyright (C) 2015 fffonion

-- json response view

local common = require('common')
local _, super = common.try_load_view('_base')

local _M = {_VERSION = '0.01'}


function _M.new(_, data, code)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.data = data
	self.http_status = code or '200'
	self.content_type = "application/json"
    ngx.header['Access-Control-Allow-Origin'] = "*"
    return self
end

function _M.get_view(self)
	local cjson = require('cjson')
	return cjson.encode(self.data)
end


return _M
