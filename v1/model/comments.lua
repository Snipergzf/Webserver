-- Copyright (C) 2015 fffonion

-- comment model

local common = require('common')
local const = require('const')
local _, super = common.try_load_model('_base')

local _M = {_VERSION = '0.01'}

function _M.new(_, arg)

    local self = setmetatable(
		super:new(arg.code, arg.errmsg)
		, { __index = _M} 
	)
	self.data.comment = {
		action = arg.action,
		result = arg.result,
		comments = arg.comments,
		sum = arg.sum
	}
	return self
end

function _M.add_one(self, arg)
	if type(arg) ~= "table" then
		ngx.log(ngx.ERR, "[LI] commend.add_one() adding non-table arg: ", type(arg))
	end
	if self.data.comment.comments == nil then
		self.data.comment.comments = {}
	end
	table.insert(self.data.comment.comments, arg)
end


return _M