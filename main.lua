local route = require 'route'
local common = require 'common'

local method = ngx.req.get_method()


local content_type = ngx.req.get_headers()['content-type']
if content_type and type(header) == "table" then
	content_type = content_type[0]
end
if content_type ~= nil and string.match(content_type, "multipart/form%-data") then
	method = 'FILE' --different from normal POST handler
else
	ngx.req.read_body()
end

-- map HTTP method to corresponding handler functions
local parse_arg_call_tbl = {
	['GET']  = {ngx.req.get_uri_args},
	['POST'] = {ngx.req.get_uri_args, ngx.req.get_post_args},
	['FILE'] = {ngx.req.get_uri_args, common.parse_multipart},
	['PUT']  = {ngx.req.get_uri_args, ngx.req.get_body_data}
}


local r = route:new()
route:do_route(ngx.var.cmd, parse_arg_call_tbl[method])
common.cleanup()
