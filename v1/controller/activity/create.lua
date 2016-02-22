-- Copyright (C) 2015 gzf

-- activity controller

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
	self.uid = arg.uid
	self.a_name = arg.a_name
	self.a_time = arg.a_time
	self.a_place = arg.a_place
	self.a_desc = arg.a_desc
	return self
end

function _M.response(self)
	local _, _em = common.try_load_model('activity_action')
	local _tb = {action="create"}
	while true do
		if not self.uid or self.uid == '' then
			_, _em = common.try_load_model('error')
			_tb = {code = const.ERR_API_MISSING_ARG}
			break
		end
		
		local result, a_id = self:create()
		if result == const.API_STATUS_OK then
			_tb.result="succeed"
			_tb.a_id=a_id
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

local function create(self)
	local db = common.get_dbconn()
	if not db then
		return const.ERR_API_DATABASE_DOWN, nil
	end
	local a_id = common.get_aid(self.uid)
	res, err, errno, sqlstate =
		db:query("INSERT INTO Activity (`uid`, `a_id`, `participants`, `a_name`, `a_time`, `a_place`, `a_desc`) VALUES ("..
			ngx.quote_sql_str(self.uid)..",'"..a_id.."', "..ngx.quote_sql_str(self.uid)..", "..ngx.quote_sql_str(self.a_name)..", "..ngx.quote_sql_str(self.a_time)..", "..ngx.quote_sql_str(self.a_place)..
			", "..ngx.quote_sql_str(self.a_desc)..")", 10)
	if errno ~= nil and errno > 0 then
		return const.ERR_API_CREATE_ACTIVITY, nil
	end
	return const.API_STATUS_OK,a_id
end
_M.create = create

return _M
