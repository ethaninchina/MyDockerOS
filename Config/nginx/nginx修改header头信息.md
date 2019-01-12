# 原header头信息 (这里修改 X-Powered-By: ASP.NET 头信息)
```
[root@VM_45_51_centos vhost]# curl -I http://10.10.13.158:3000
HTTP/1.1 200 OK
Server: openresty
Date: Sat, 12 Jan 2019 06:36:11 GMT
Content-Type: text/html
Content-Length: 1
Connection: keep-alive
Last-Modified: Tue, 17 May 2016 15:08:27 GMT
Accept-Ranges: bytes
ETag: "f15046f74db0d11:0"
X-Powered-By: ASP.NET

```

# nginx 配置 修改header头
```
    server {
            listen       3000;
            server_name  /10.10.13.158;
            root html;
            
	          more_set_headers 'X-Powered-By: Golang.Google'; #设置修改的header头

    }
```

# 修改后 访问 
```
[root@VM_45_51_centos vhost]# curl -I http://10.10.13.158:3000
HTTP/1.1 200 OK
Server: openresty
Date: Sat, 12 Jan 2019 06:43:12 GMT
Content-Type: text/html
Content-Length: 1
Connection: keep-alive
Last-Modified: Tue, 17 May 2016 15:08:27 GMT
Accept-Ranges: bytes
ETag: "f15046f74db0d11:0"
X-Powered-By: Golang.Google
```
