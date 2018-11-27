###Openresty部分配置如下
```
upstream online { 
        server 127.0.0.1:8080;  #生产服务器
    }
upstream yfb {
        server 127.0.0.1:8090;  #预发布服务器
    }

    server {
        listen       8080;
        server_name  127.0.0.1;
	    port_in_redirect off; #告知nginx在redirect的时候不要带上port，如果没有配置，默认该值为true
	
        location / {
            root   html;
            index  index.html index.htm;
        }
    }

    server {
        listen       8090;
        server_name  127.0.0.1;
	    port_in_redirect off;#前后端端口不同时使用此参数,告知nginx在redirect的时候不要带上port，如果没有配置，默认该值为true

        location / {
            root   html2;
            index  index.html index.htm;
        }
    }


    server {
        listen       80;
        server_name  localhost;
        
        location ^~ /test {
            content_by_lua_file conf/huidu.lua; #lua脚本
            }
        
        location @online{
                proxy_pass http://online;
		        proxy_redirect     off; #proxy_redirect 功能的用是对发送给客户端的URL进行修改,这里选择关闭修改,不暴露后端连接
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            }
        location @yfb{
                proxy_pass http://yfb;
                proxy_redirect     off;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            }
    }

```

###lua配置文件 huidu.lua
```
#Lua脚本内容如下：
local redis = require "resty.redis" 
local cache = redis.new()
--超时60秒
cache:set_timeout(60000)
-- 定义redis连接
local ok, err = cache.connect(cache, '127.0.0.1', 6379) 
if not ok then 
    ngx.say("failed to connect:", err) 
    return 
end 
-- redis连接认证,密码为 12345
local red, err = cache:auth("12345")
if not red then
    ngx.say("failed to authenticate: ", err)
    return
end
-- 定义获取客户端IP
local local_ip = ngx.req.get_headers()["X-Real-IP"]
if local_ip == nil then
    local_ip = ngx.req.get_headers()["x_forwarded_for"]
end

if local_ip == nil then
    local_ip = ngx.var.remote_addr
end

local intercept = cache:get(local_ip) 

if intercept == local_ip then
    ngx.exec("@yfb")
    return
end

ngx.exec("@online")

local ok, err = cache:close() 
 
if not ok then 
    ngx.say("failed to close:", err) 
    return 
end
```

### redis操作
```
键入访问预发布访问的IP

set 192.168.100.33 192.168.100.33
set 172.168.10.58 172.168.10.58


#删除预发布访的IP
del 192.168.100.33
del 172.168.10.58
```
