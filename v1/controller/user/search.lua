-- Copyright (C) 2015 gzf
-- User controller

local common = require('common')
local const = require('const')
local _, super = common.try_load_controller('_base')
local config = require('config')
local _M = {_VERSION = '0.01'}

function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.uid = arg.uid
	return self
end

function _M.response(self)
	local _,_em = common.try_load_model('user_action')
	local _tb = {action = "search"}
	while true do
		if not self.uid or self.uid == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		local result, info = self:search_by_uid()
		if result == const.API_STATUS_OK then
			_tb.result = "succeed"
			_tb.info = info
		else 
			_tb.code = result
		end
		break
	end
	local em = _em:new(_tb)
	local _,_v = common.try_load_view('json_resp')
	local jv = _v:new(em.data,em.http_status)
	common.send_resp(jv)
end

local function search_by_uid(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	res, err, errno, sqlstate = 
		db:query("SELECT name,email,user_rank,school,grade,major,class,avatar,phone,sex FROM User WHERE id ="..
			ngx.quote_sql_str(self.uid)
		, 10)
	
	if not res or not res[1] then
		return const.ERR_API_NO_SUCH_USER, nil
	end
	
	if errno ~= nil and errno > 0 then
		return const.ERR_API_SEARCH_USER_FAILED,nil
	end
	
	--if res[1] == nil then
		--return const.ERR_API_SEARCH_USER_FAILED_, nil
	--end
	local tb = {}
	tb.name = res[1]['name']
	tb.email = res[1]['email']
	tb.user_rank = res[1]['user_rank']
	tb.school = res[1]['school']
	tb.major = res[1]['major']
	tb.grade = res[1]['grade']
	tb.class = res[1]['class']
	if not res[1]['avatar'] or res[1]['avatar'] == ngx.null then
		tb.avatar = 'default'
	else
		tb.avatar = config.HOST .. "/images/avatar/"..res[1]['avatar']
	end
	--tb.phone = res[1]['phone']
	tb.sex = res[1]['sex']
	return const.API_STATUS_OK,tb
end
_M.search_by_uid = search_by_uid
return _M



