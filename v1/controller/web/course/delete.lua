-- Copyright (C) 2015 gzf

-- course controller

local common = require('common')
local const = require('const')
local config = require('config')
local _, super = common.try_load_controller('_base')
local cjson = require('cjson')
local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.course_id = arg.course_id
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('course_action')
	local _tb = {action="delete_course"}
	while true do
		if not self.course_id or self.course_id == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result= self:delete_course()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
		else -- >0
			_tb.code = result
		end
		break
	end
	local em = _em:new(_tb)
	local _, _v = common.try_load_view('json_resp')
	local jv = _v:new(em.data, em.http_status)
	common.send_resp(jv)
end

local function delete_course(self)
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("course")
	local n,err = col:delete({_id = self.course_id},1,1)
	-- ngx.log(ngx.ERR,"n: ",n,"err: ",err)
	if n == 0 then
		return const.ERR_API_DELETE_COURSE
	end
	
	return const.API_STATUS_OK
end
_M.delete_course = delete_course

return _M
