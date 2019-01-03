# 编辑配置
vim /etc/squid/squid.conf
```
# 日志
logformat combined client_ip:%>a local_ip:%la %tr %ui %un "%rm %ru HTTP/%rv" %Hs %<st "%{Referer}>h" "%{User-Agent}>h" %Ss:%Sh
access_log /data/logs/access.log combined

# 定义内网
acl test src 10.125.20.0/24

# 允许内网访问
http_access allow test
# 允许所有访问
http_access allow all

# 关闭缓存功能
#acl NCACHE method GET
#no_cache deny NCACHE


# 监听端口
http_port 9995

# 缓存使用内存大小
cache_mem 4000 MB
# 超过50M的不存入硬盘
maximum_object_size 50 MB
# 设置squid磁盘缓存最小文件
minimum_object_size 0 KB
# 设置squid内存缓存最大文件，超过4M的文件不保存到内存
maximum_object_size_in_memory 4096 KB
# 缓存存放目录4000MB ,一级目录,二级目录 
cache_dir ufs /data/cache/squid 4000 16 256
# 日志清理(log轮循 60天, cache目录使用量大于95%时，开始清理旧的cache, cache目录清理到90%时停止)
logfile_rotate 60
cache_swap_high 95
cache_swap_low 90
# 定义dump的目录
#coredump_dir /data/backup/squid

#默认情况下，Squid 会把主机相关的信息发送出去，并显示在错误页面。加上下面两句去掉这些信息：
httpd_suppress_version_string on

# 设置squid服务器主机名
visible_hostname squid.test.dev 

# 设置管理员邮箱
cache_mgr squid_test@qq.com

#默认情况下，Squid 会添加很多和客户信息相关的 HTTP 头，如 X-Forwarded-For 这类。如果想要做到高度匿名，需要将这些头去掉。在 squid.conf 里面添加如下的配置：
#以下是高匿的设置
forwarded_for delete
request_header_access Via deny all
request_header_access X-Forwarded-For deny all

```


 

##### 客户端linux机器上设置代理
```
echo "export http_proxy=http://112.130.53.192:9995" >> /etc/profile
echo "export https_proxy=http://112.130.53.192:9995" >> /etc/profile
```
##### 客户端linux机器上网
```
cur baidu.com 就会通过代理服务器上网
```
