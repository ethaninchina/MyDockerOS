# 前置机 nginx 或者客户端 :
## 一、增加header
##### server1: 老机器
```
add_header pda-sr pda-old; 
```
#### server2: 新机器
```
add_header pda-sr pda-new;
```

## 二、代理层nginx  根据header 转发
#### server3: proxy机器
```
server {
        listen       17008;
        #underscores_in_headers on;  #开启header的下划线支持 (日过header中有下划线需要开启此项,尽量不要用下划线)
        
        charset utf-8;
        #add_header pda-sr pda-new;	 #显示header信息时打开 (供测时查看header信息)

        location / {
		# header 为空 ,禁止访问 (安全访问)
                if ($http_pda_sr = "") {
                        return 403;
                        }

                # 判断header 
                if ($http_pda_sr = "pda-old") {
                    proxy_pass http://www.baidu.com;
                        }

                # 判断header
                    if ($http_pda_sr = "pda-new") {
                    proxy_pass http://www.163.com;
                        }
                }

}

```

# 三、测试
```
[root@myos vhost]# curl --head -s -H "pda-sr:pda-new" http://localhost:17008 |grep -E "HTTP\/|http-pda-sr"
HTTP/1.1 200 OK
http-pda-sr: pda-new

[root@myos vhost]# curl --head -s -H "pda-sr:pda-old" http://localhost:17008 |grep -E "HTTP\/|http-pda-sr"
HTTP/1.1 200 OK
http-pda-sr: pda-old

```
