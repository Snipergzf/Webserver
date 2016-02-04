-- Copyright (C) 2015 fffonion
-- access control module

local common = require('common')
local const = require('const')

local _M = {
	_VERSION = '0.01',
	ACL_PASS = 0,
	ACL_DENIED = 1,
}

function _M.rule_always_pass(self)
	return _M.ACL_PASS
end

function _M.rule_always_deny(self)
	return _M.ACL_DENIED
end

function _M.rule_check_token(query)
	if query == nil then
		return _M.ACL_DENIED
	end
    local token = query['token'] or ngx.req.get_headers()['Authorization']
	local uid = query['uid']
	if uid == nil or token == nil then
		return _M.ACL_DENIED
	end
	local db = common.get_dbconn()
	if not db then
		ngx.log(ngx.ERR, "[LI] failed to connect: ", err, ": ", errno, " ", sqlstate)
		return _M.ACL_DENIED
	end
	-- NOTE ngx.quote_sql_str will add '' to var, DON'T ADD IT MANUALLY
	res, err, errno, sqlstate =
		db:query("SELECT uid FROM Token WHERE token="..ngx.quote_sql_str(token) .." AND uid="..ngx.quote_sql_str(uid), 10)
	if not res or not res[1] then
		return _M.ACL_DENIED
	end
	
	return _M.ACL_PASS
end



function _M.rule_ip()
	local ip = ngx.var.remote_addr
	-- DO SOMETHING like ban ip
	return _M.ACL_PASS
end


function _M.check_acl(arg, func)
	if func == nil then
		ngx.log(ngx.ERR ,"[LI] acl", "passing nil function to check_acl()")
		return false
	end
	local ret = func(arg)
	if ret ~= nil and ret == _M.ACL_PASS then
		return true
	end
	return false
end

-- the access control list, default rule is rule_check_token() (returned by _get_default())
-- !! has to put this behind all the functions !!
_M.acl_list = setmetatable({
	['error'] = _M.rule_always_pass,
	['user/login'] = _M.rule_always_pass,
	['user/register'] = _M.rule_always_pass,
	['user/reset_pwd'] = _M.rule_always_pass,
	['user/get_avatar'] = _M.rule_always_pass,
	['user/search'] = _M.rule_always_pass,
	['user/get_info'] = _M.rule_always_pass,
	['comment/get'] = _M.rule_always_pass,
	['course/searchOne'] = _M.rule_always_pass,
	['course/searchAll'] = _M.rule_always_pass,
	['event/search'] = _M.rule_always_pass,
	['event/search_off'] = _M.rule_always_pass,
	['group/search_member'] = _M.rule_always_pass,
	['group/check_info'] = _M.rule_always_pass,
	['web/register'] = _M.rule_always_pass,
	['web/login'] = _M.rule_always_pass,
	['web/course/searchAll'] = _M.rule_always_pass,
	['web/course/searchOne'] = _M.rule_always_pass,
	['web/course/delete'] = _M.rule_always_pass,
	['web/course/insert'] = _M.rule_always_pass,
	['web/event/push_img'] = _M.rule_always_pass,
	['web/event/delete_img'] = _M.rule_always_pass,
	['web/event/insert'] = _M.rule_always_pass,
	['web/event/search_tmp'] = _M.rule_always_pass,
	['web/event/search_time'] = _M.rule_always_pass,
	['web/event/search_owner'] = _M.rule_always_pass,
	['web/event/search_name'] = _M.rule_always_pass,
	['web/event/move'] = _M.rule_always_pass,
	['web/event/delete_tmp'] = _M.rule_always_pass,
	-- ['event/feedback_add'] = _M.rule_always_pass,
	-- ['event/feedback_del'] = _M.rule_always_pass,
	-- ['event/update'] = _M.rule_always_pass,
	-- ['friend/search'] = _M.rule_always_pass,
}, {
	__index = function() return _M.rule_check_token end
})

return _M
