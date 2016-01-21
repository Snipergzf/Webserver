-- Copyright (C) 2015 gzf
-- User controller

local common = require('common')
local const = require('const')
local _, super = common.try_load_controller('_base')

local _M = {_VERSION = '0.01'}

function _M.new(_, arg)
    local self = setmetatable(
		super:new()
		, { __index = _M} 
	)
	self.uid = arg.uid
	self.name = arg.name
	self.email = arg.email
	self.sex = arg.sex
	self.user_rank = arg.user_rank
	self.school = arg.school
	self.major = arg.major
	self.grade = arg.grade
	self.class = arg.class
	return self
end

function _M.response(self)
	local _,_em = common.try_load_model('user_action')
	local _tb = {action = "update"}
	while true do
		if not self.uid or self.uid == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		local result = self:update()
		if result == const.API_STATUS_OK then
			_tb.result = "succeed"
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

local function update(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local query_str = "UPDATE User SET "
	if self.name and self.name ~= '' then
		query_str = query_str..'name='..ngx.quote_sql_str(self.name)
	end
	
	if self.sex and self.sex ~= '' then
		if query_str ~= "UPDATE User SET " then
			query_str = query_str..',sex='..ngx.quote_sql_str(self.sex)
		else
			query_str = query_str..'sex='..ngx.quote_sql_str(self.sex)
		end
	end
	
	if self.email and self.email ~= '' then
		if query_str ~= "UPDATE User SET " then
			query_str = query_str..',email='..ngx.quote_sql_str(self.email)
		else
			query_str = query_str..'email='..ngx.quote_sql_str(self.email)
		end
	end
	
	if self.user_rank and self.user_rank ~= '' then
		if query_str ~= "UPDATE User SET " then
			query_str = query_str..',user_rank='..ngx.quote_sql_str(self.user_rank)
		else
			query_str = query_str..'user_rank='..ngx.quote_sql_str(self.user_rank)
		end
	end
	
	if self.school and self.school ~= '' then
		if query_str ~= "UPDATE User SET " then
			query_str = query_str..',school='..ngx.quote_sql_str(self.school)
		else
			query_str = query_str..'school='..ngx.quote_sql_str(self.school)
		end
	end
	
	if self.grade and self.grade ~= '' then
		if query_str ~= "UPDATE User SET " then
			query_str = query_str..',grade='..ngx.quote_sql_str(self.grade)
		else
			query_str = query_str..'grade='..ngx.quote_sql_str(self.grade)
		end
	end
	
	if self.major and self.major ~= '' then
		if query_str ~= "UPDATE User SET " then
			query_str = query_str..',major='..ngx.quote_sql_str(self.major)
		else
			query_str = query_str..'major='..ngx.quote_sql_str(self.major)
		end
	end
	
	if self.class and self.class ~= '' then
		if query_str ~= "UPDATE User SET " then
			query_str = query_str..',class='..ngx.quote_sql_str(self.class)
		else
			query_str = query_str..'class='..ngx.quote_sql_str(self.class)
		end
	end
	
	ngx.log(ngx.ERR,"query_str:",query_str)
	
	-- res, err, errno, sqlstate = 
		-- db:query("UPDATE User SET name="..ngx.quote_sql_str(self.name)..",email="..ngx.quote_sql_str(self.email)..",user_rank="..
		-- ngx.quote_sql_str(self.user_rank)..",school="..ngx.quote_sql_str(self.school)..",grade="..ngx.quote_sql_str(self.grade)..
		-- ",major="..ngx.quote_sql_str(self.major)..",class="..ngx.quote_sql_str(self.class)..",sex="..ngx.quote_sql_str(self.sex)..
		-- "WHERE id ="..ngx.quote_sql_str(self.uid), 10)
		
	res, err, errno, sqlstate = 
		db:query(query_str.."WHERE id ="..ngx.quote_sql_str(self.uid), 10)
		
	if errno ~= nil and errno > 0 then
		return const.ERR_API_UPDATE_USER_FAILED,nil
	end
	
	return const.API_STATUS_OK
end
_M.update = update
return _M



