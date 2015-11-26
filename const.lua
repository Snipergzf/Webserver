-- Copyright (C) 2015 fffonion

-- constants


local _C = {
	API_STATUS_OK = 0,
	
	--[[
	HTTP status code generation:
	http_status = math.floor(code/100) + 200
	but 1~9999 is all http code 200
	]]--
	-- api error (200) 1~9999
	ERR_API_NO_SUCH_USER = 1, [1] = 'no such user',
	ERR_API_LOGIN_FAILED_WRONG_PWD = 2, [2] = 'login failed! password mismatch',
	ERR_API_REG_FAILED_USER_EXISTS = 3, [3] = 'reg failed! username is already registered',
	ERR_API_ADD_FRIEND_FAILED = 4, [4] = 'add friend failed! you have sended the require to add friend',
	ERR_API_COMMIT_FRIEND_FAILED_EXISTS = 5, [5] = 'add friend failed! you have been friends',
	ERR_API_COMMIT_FRIEND_FAILED_REQUIRE_NOT_EXISTS = 6, [6] = 'add friend failed! this require of add friend not exists',
	ERR_API_ADD_SELF_WRONG = 7, [7] = 'add friend faild! you can not add yourself to be your friend',
	ERR_API_DELETE_FRIEND_FAILED = 8, [8] = 'delete friend failed! you are not friends',
	ERR_API_ADD_COMMENT_FAILED = 10, [10] = 'failed to add comment',
	ERR_API_DEL_COMMENT_FAILED = 11, [11] = 'failed to del comment',
	ERR_API_GET_COURSE_FAILED = 11, [11] = 'invaild uid',
	
	-- client fail (40x)
	-- 400 20000~20099
	ERR_API_MISSING_ARG = 20000, [20000] = 'your request is missing requst arguments, check our document and try again',
	ERR_INVALID_TOKEN = 20001, [20001] = 'invalid token',
	-- 404 20400~20499
	ERR_API_NOT_FOUND = 20400, [20400] = 'API call not found',
	
	-- server fail (50x)
	-- 500 30000~30099
	ERR_API_UNAVALIABLE = 30000, [30000] = 'API is temporarily unavailable',
	ERR_API_TOKEN_GENERATION_FAILED = 30001, [30001] = 'token generation faild',
	ERR_API_DATABASE_DOWN = 30001, [30001] = 'database is down',
	ERR_API_FAILED_SAVING_AVATAR = 30002, [30002] = 'failed to save avatar',
	
	
	SESSION_EXPIRE = 3600,--1h
}

return _C