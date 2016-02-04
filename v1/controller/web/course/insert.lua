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
	self.account = arg.account
	self.course_id = arg.course_id
	self.course = arg.course
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('course_action')
	local _tb = {action="insert_course"}
	while true do
		if not self.account or self.account == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result= self:insert_course()
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

local function insert_course(self)
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN
	end
	local col = db:get_col("course")
	
	local r = col:find_one({_id = self.course_id},{})
	if r then
		return const.ERR_API_INSERT_COURSE_EXIST
	end
	--ngx.log(ngx.ERR,"here: ",self.course_id)
	local course_doc = cjson.decode(self.course)
	local n,err = col:insert({course_doc},1,1)
	--ngx.log(ngx.ERR,"err: ",not err,err)
	if err then
		return const.ERR_API_INSERT_COURSE
	end
	
	return const.API_STATUS_OK
end
_M.insert_course = insert_course

return _M
