-- Copyright (C) 2015 fffonion

-- server variables configuration

local _C = {
	--MYSQL_HOST = "127.0.0.1",
	MYSQL_UNIX_SOCKET = "/run/mysqld/mysqld.sock",
	MYSQL_USER_NAME = "root",
	MYSQL_USER_PASS = "gzfisme",
	
	MONGO_HOST = "127.0.0.1",
	MONGO_PORT = 12345,
	MONGO_USER_NAME = "testu",
	MONGO_USER_PASS = "u123456",
	MONGO_COLLECTION = "core",
	
	UPLOAD_TEMP_DIR = "/tmp",
	AVATAR_DIR = "/home/www/lua/images/avatar",
	EVENT_IMG_DIR = "/home/www/lua/images/event",
	AVATAR_DIR_DEPTH = 3,
	EVENT_IMG_DIR_DEPTH = 3,
	AVATAR_DEFAULT_FILE = "default_avatar.jpg",
	
	-- HOST = "http://123.56.142.241",
	HOST = "http://api.eventer.com.cn",
	
	-- whether send debug info to client, should turn off on production environment
	DEBUG = true,
}

return _C
