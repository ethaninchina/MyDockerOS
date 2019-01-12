   # 默认路由走  114.114.114.114 ,匹配post规则后 走 8.8.8.8
   ###
   ```
    upstream MY-DEFAULT {
    server 114.114.114.114:1234;
    }
    upstream MY-IMAGE {
    server 8.8.8.8:1234;
    }

    server {
            listen       17000;
            server_name  10.186.45.51;

            access_log  /var/log/nginx/access.log  main;
            error_log  /var/log/nginx/error.log debug;

            location / {
                proxy_pass http://MY-DEFAULT;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
                proxy_ignore_client_abort on;
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                            }

            location /MyService.asmx {
                    #default_type 'text/plain';
                    set $dyna_upstream ""; #设置upstream路由变量
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
                    proxy_ignore_client_abort on;
                    proxy_http_version 1.1;
                    proxy_set_header Connection "";
                    proxy_pass $scheme://$dyna_upstream; #匹配规则后走到 对应的$dyna_upstream路由
                    rewrite_by_lua '
                        if ngx.var.request_method == "POST" then
                            ngx.req.read_body()
                            local body_data = ngx.req.get_body_data()
                            local A = string.find(body_data, "</UploadImagev1>")
                            local B = string.find(body_data, "</UploadImagev2>")
                            local C = string.find(body_data, "</UploadImage_v3>")
                            local F = string.find(body_data, "</ooxx_abcdesXf>")
                            local D = string.find(body_data, "</UploadImage_v4>")
                            local E = string.find(body_data, "</UploadImage_v5>")
                            -- 匹配规则 不为空,调用 $dyna_upstream 路由
                            if A ~= nil then 
                                ngx.var.dyna_upstream="PDA-IMAGE";
                            elseif B ~= nil then
                                ngx.var.dyna_upstream="PDA-IMAGE";
                            elseif c ~= nil then
                                ngx.var.dyna_upstream="PDA-IMAGE";
                            elseif D ~= nil then
                                ngx.var.dyna_upstream="PDA-IMAGE";
                            elseif E ~= nil then
                                ngx.var.dyna_upstream="PDA-IMAGE";
                            elseif F ~= nil then
                                ngx.var.dyna_upstream="PDA-IMAGE";
                            else
                                ngx.var.dyna_upstream ="MY-DEFAULT";
			    end
			else
			    ngx.var.dyna_upstream ="MY-DEFAULT";
                        end ';
                }
    }

```
