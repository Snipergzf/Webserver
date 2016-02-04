-- Copyright (C) 2015 gzf

-- course controller

local common = require('common')
local const = require('const')
local config = require('config')
-- local _debug = require('_debug')
local _, super = common.try_load_controller('_base')

local _M = {_VERSION = '0.01'}


function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
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
		if not self.s_grade or not self.s_faculty or not self.s_specialty or not self.s_class then
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
	-- local cursor = col:find({s_grade = ngx.unescape_uri(ngx.quote_sql_str(self.s_grade)),s_faculty = ngx.unescape_uri(ngx.quote_sql_str(self.s_faculty)),s_specialty = ngx.unescape_uri(ngx.quote_sql_str(self.s_specialty)),s_class = ngx.unescape_uri(ngx.quote_sql_str(self.s_class))},{c_name=1,t_name=1,c_detail=1,s_grade=1,s_specialty=1,s_faculty=1,s_class=1})
	local cursor = col:find({s_grade = ngx.unescape_uri(self.s_grade),s_faculty = ngx.unescape_uri(self.s_faculty),s_specialty = ngx.unescape_uri(self.s_specialty),s_class = ngx.unescape_uri(self.s_class)},{c_name=1,t_name=1,c_detail=1,s_grade=1,s_specialty=1,s_faculty=1,s_class=1})
	for index, item in cursor:pairs() do
		table.insert (tb,index,item)
	end
	if #tb == 0 then
		return const.ERR_API_NO_COURSE, nil
	end
	return const.API_STATUS_OK,tb
end
_M.get_course_all = get_course_all

return _M
