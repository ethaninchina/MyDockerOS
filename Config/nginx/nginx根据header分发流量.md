# 前置机 nginx 或者客户端 :
## 增加header
##### server1: 老机器
```
add_header pda-sr pda-old; 
```
#### server2: 新机器
```
add_header pda-sr pda-new;
```

## 代理层nginx  根据header 转发
```
server {
        listen       17008;
        #underscores_in_headers on;  #开启header的下划线支持 (日过header中有下划线需要开启此项,尽量不要用下划线)

        location / {
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

# 测试
```
curl --head -H "pda-sr:pda-new" http://localhost:17008

curl --head -H "pda-sr:pda-old" http://localhost:17008
```
