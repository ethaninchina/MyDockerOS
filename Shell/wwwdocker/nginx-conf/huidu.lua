local redis = require "resty.redis" 
local cache = redis.new() 
cache:set_timeout(60000)

local ok, err = cache.connect(cache, '127.0.0.1', 6379) 
if not ok then 
    ngx.say("failed to connect:", err) 
    return 
end 

local red, err = cache:auth("zz520ll")
if not red then
    ngx.say("failed to authenticate: ", err)
    return
end

local local_ip = ngx.req.get_headers()["X-Real-IP"]
if local_ip == nil then
    local_ip = ngx.req.get_headers()["x_forwarded_for"]	
end

if local_ip == nil then
    local_ip = ngx.var.remote_addr
end

local intercept = cache:get(local_ip) 


if intercept == local_ip then
    ngx.exec("@test")
    return
end

ngx.exec("@online")

local ok, err = cache:close() 
 
if not ok then 
    ngx.say("failed to close:", err) 
    return 
end
