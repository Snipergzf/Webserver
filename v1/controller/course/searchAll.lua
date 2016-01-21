-- Copyright (C) 2015 gzf

-- course controller

local common = require('common')
local const = require('const')
local config = require('config')
--local _debug = require('_debug')
local _, super = common.try_load_controller('_base')

local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.uid = arg.uid
	self.s_grade = arg.s_grade
	self.s_faculty = arg.s_faculty
	self.s_specialty = arg.s_specialty
	self.s_class = arg.s_class
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('course_action')
	local _tb = {action="search_all_course"}
	while true do
		if not self.uid or self.uid == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_GET_COURSE_FAILED}
			break
		end
		
		local result,_course = self:get_course_all()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"			
			_tb.course = _course or {}
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

local function get_course_all(self)
	local tb = {}
	local db = common.get_mongo()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local col = db:get_col("course")
	--local cursor = col:find({t_name = ngx.unescape_uri(self.search_name)},{c_name=1,t_name=1,c_detail=1})
	--local r = col:find_one({["s_detail.s_garde"] =  ngx.unescape_uri(self.c_grade),["s_detail.s_faculty"] = ngx.unescape_uri(self.c_faculty),["s_detail.s_specialty"] = ngx.unescape_uri(self.c_specialty),["s_detail.s_class"] = ngx.unescape_uri(self.c_class)},{})
	local cursor = col:find({s_grade = ngx.unescape_uri(self.s_grade),s_faculty = ngx.unescape_uri(self.s_faculty),s_specialty = ngx.unescape_uri(self.s_specialty),s_class = ngx.unescape_uri(self.s_class)},{c_name=1,t_name=1,c_detail=1,s_grade=1,s_specialty=1,s_faculty=1,s_class=1})
	for index, item in cursor:pairs() do
		table.insert (tb,index,item)
	end
	if not tb then
		return const.ERR_API_NO_COURSE, nil
	end
	return const.API_STATUS_OK,tb
end
_M.get_course_all = get_course_all

return _M
