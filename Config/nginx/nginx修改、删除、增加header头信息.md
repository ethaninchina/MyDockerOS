### 原header头信息 (这里修改 X-Powered-By: ASP.NET 头信息)
##### 该模块的指示适用于所有的状态码，包括4xx和5xx的。不像标准头模块 如 add_header 只适用于200，201，204，206，301，302，303，304，或307。

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

##### nginx 配置 修改header头
```
    server {
            listen       3000;
            server_name  /10.10.13.158;
            root html;
            	  #more_clear_headers 'X-Powered-By'; #删除 header头信息
	          more_set_headers 'X-Powered-By: Golang.Google'; #单个指定设置 增加/修改 header的单个输出头
		  more_set_headers 'Foo: bar' 'Baz: bah'; # 单个指令可以设置/添加 header多个输出头

    }
```

##### 修改后 访问 
```
[root@VM_45_51_centos vhost]# curl -I http://10.10.13.158:3000
HTTP/1.1 200 OK
Server: openresty
Date: Sat, 12 Jan 2019 06:59:00 GMT
Content-Type: text/html
Content-Length: 1
Connection: keep-alive
Last-Modified: Tue, 17 May 2016 15:08:27 GMT
Accept-Ranges: bytes
ETag: "f15046f74db0d11:0"
X-Powered-By: ASP.NET
FX-Powered-By: Golang.Google
Foo: bar
Baz: bah

```
##### 可以允许你使用-s选项指定HTTP状态码，使用-t选项指定内容类型，通过more_set_headers 和 more_clear_headers 指令来修改输出头信息。(在单一指令中，选项可以多次出现)如：
```
more_set_headers -s 404 -t 'text/html' 'X-Error: status=404';
#more_set_headers -s '404 500 503' 'X-Error: status is bad';
```
```
[root@VM_45_51_centos vhost]# curl -I http://10.10.13.158:3000
HTTP/1.1 200 OK
Server: openresty
Date: Sat, 12 Jan 2019 07:01:53 GMT
Content-Type: text/html
Content-Length: 1
Connection: keep-alive
Last-Modified: Tue, 17 May 2016 15:08:27 GMT
Accept-Ranges: bytes
ETag: "f15046f74db0d11:0"
X-Powered-By: ASP.NET
FX-Powered-By: Golang.Google
Foo: bar
Baz: bah

[root@VM_45_51_centos vhost]# curl -I http://10.10.13.158:3000/123
HTTP/1.1 404 Not Found
Server: openresty
Date: Sat, 12 Jan 2019 07:02:01 GMT
Content-Type: text/html
Content-Length: 1163
Connection: keep-alive
Vary: Accept-Encoding
X-Powered-By: ASP.NET
FX-Powered-By: Golang.Google
Foo: bar
Baz: bah
X-Error: status=404
```



