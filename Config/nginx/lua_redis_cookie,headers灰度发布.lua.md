```
-- 基于 session,token,userid 和redis对象列表 redisList 变量比对 走灰度,没有值的 走默认 线上
-- 定义redis变量
local redisIp = "127.0.0.1"
local redisPort = "6379"
local redisPasswd = "12345"
local redisList = "__grayconfiguration"
-- 默认是走线上,不走灰度
local isGray = false

--获取headers
local headers = ngx.req.get_headers()
-- id从header中获取
local id = headers["sessionid"]

-- 如果id 为空
if id == nil then
    -- id值 为 headers中获取token值
    id = headers["token"]
end

-- 如果id 为空
if id == nil then
    -- id值 为 headers中获取userid值
    id = headers["userid"]
end

if id == nil then
    --如果继续为空则id 值为 cookie中获得sessionid值
    id = ngx.var.cookie_sessionid
end

if id == nil then
    --如果继续为空则id值为cookie中获得token值
    id = ngx.var.cookie_token
end

 --headers,cookie 中的值都为空,走线上
if id == nil then
    ngx.exec("@product_env")
    return
end

-- token,sessionid 如果为空,则读取redis 存储对象
-- redis lua访问
local redis = require "resty.redis" 
local cache = redis.new()
--超时60秒
cache:set_timeout(60000)
local ok, err = cache.connect(cache, redisIp, redisPort) 
if not ok then 
    ngx.exec("@product_env")
    return 
end 
-- redis连接认证,密码为 12345
local red, err = cache:auth(redisPasswd)
if not red then
    ngx.exec("@product_env")
    return
end

-- 定义 rds_id 值为 从redis列表中获取
local rds_len = cache:llen(redisList)   --先获取列表长度
local rdsid_list = cache:lrange(redisList,"0",rds_len)  -- 利用redis命令lrange 列出列表所有值的信息
if rdsid_list == nil then
    ngx.exec("@product_env")
    return
end

-- 暂放
--local userinfo = cache:get(id)
--if userinfo == nil then
--    ngx.exec("@product_env")
--    return
--end

for k, v in pairs(rdsid_list) do
    -- 如果值相等,说明redis中存在此值,就发布到灰度
    if id == v then
        isGray = true  -- 当id变量匹配到rdsid_list列表内的值时,打开灰度,默认是关闭的
        break
    end
end


--关闭redis
local ok, err = cache:close() 

-- 判断灰度是开启还是关闭
if isGray then
    ngx.exec("@gray_env")
else
    ngx.exec("@product_env")
end

```
