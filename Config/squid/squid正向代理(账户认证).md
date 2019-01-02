##### 安装 htpasswd
```
yum -y install httpd 
```
##### 设置
```
htpasswd -c /etc/squid/squid_user.txt 
```

#编辑squid配置
```
vim /etc/squid/squid.conf
```
```
#日志
logformat combined client_ip:%>a local_ip:%la %tr %ui %un "%rm %ru HTTP/%rv" %Hs %<st "%{Referer}>h" "%{User-Agent}>h" %Ss:%Sh
access_log /data/logs/access.log combined

###安全认证/账户,密码
#选择的认证方式为basic
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/squid_user.txt
#认证程序的进程数
auth_param basic children 5
#授权时间 5小时重新认证
#auth_param basic credentialsttl 5 hours
acl auth_user proxy_auth REQUIRED
http_access allow auth_user

#定义内网
acl local_test src 10.125.20.0/24

#允许内网访问
http_access allow local_test

#拒绝其他所有访问 ###
http_access deny all

#关闭缓存功能
#acl NCACHE method GET
#no_cache deny NCACHE


#监听端口
http_port 9995

#缓存使用内存大小
cache_mem 4000 MB
#超过50M的不存入硬盘
maximum_object_size 50 MB
#设置squid磁盘缓存最小文件
minimum_object_size 0 KB
#设置squid内存缓存最大文件，超过4M的文件不保存到内存
maximum_object_size_in_memory 4096 KB
#缓存存放目录4000MB ,一级目录,二级目录 
cache_dir ufs /data/cache/squid 4000 16 256
#日志清理(log轮循 60天, cache目录使用量大于95%时，开始清理旧的cache, cache目录清理到90%时停止)
logfile_rotate 60
cache_swap_high 95
cache_swap_low 90
#定义dump的目录
coredump_dir /data/backup/squid


#默认情况下，Squid 会把主机相关的信息发送出去，并显示在错误页面。加上下面两句去掉这些信息：
httpd_suppress_version_string on

#设置squid服务器主机名
visible_hostname squid.test.dev 

#设置管理员邮箱
cache_mgr squid_test@china.cns

#默认情况下，Squid 会添加很多和客户信息相关的 HTTP 头，如 X-Forwarded-For 这类。如果想要做到高度匿名，需要将这些头去掉。在 squid.conf 里面添加如下的配置：
forwarded_for off
request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all
```


#####client 客户端设置
#####客户端linux机器上设置代理  
```
echo "export http_proxy=http://112.230.35.42:9995" >> /etc/profile
echo "export https_proxy=http://112.230.35.42:9995" >> /etc/profile
```

#####客户端linux机器上网
cur baidu.com 就会通过代理服务器上网
