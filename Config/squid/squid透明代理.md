# 修改squid.conf配置文件，添加透明代理支持
```
vim /etc/squid/squid.conf

#transparent为透明代理
http_port 3128 transparent 

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

#日志
logformat combined client_ip:%>a local_ip:%la %tr %ui %un "%rm %ru HTTP/%rv" %Hs %<st "%{Referer}>h" "%{User-Agent}>h" %Ss:%Sh

access_log /data/logs/access.log combined

#日志清理(log轮循 60天, cache目录使用量大于95%时，开始清理旧的cache, cache目录清理到90%时停止)
logfile_rotate 60
cache_swap_high 95
cache_swap_low 90

#定义网络 local_test 允许访问,其他的全部拒绝
acl local_test src 192.168.1.0/24 
http_access allow local_test 
http_access deny all

#设置squid服务器主机名
visible_hostname squid.test.dev 

#设置管理员邮箱
cache_mgr squid_test@qq.com
```


# ####重启服务
```
systemctl enable squid
systemctl restart squid
systemctl status squid
```
 
# #### iptables 安装
```
yum install -y iptables iptables-services 


systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld


####允许ssh
iptables -A INPUT -s 0.0.0.0/0 -p tcp --dport 22 -j ACCEPT



##### squid 服务器 添加iptables规则，把内部的http请求重定向到3128端口
iptables -t nat -I PREROUTING -i eth0 -s 192.168.1.0/24 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -I PREROUTING -i eth0 -s 192.168.1.0/24 -p tcp --dport 443 -j REDIRECT --to-port 3128


service iptables save
systemctl restart iptables.service
```

# #### 修改客户端IP地址
将默认网关设置为squid 服务器的内网ip地址 192.168.1.251
如: GATEWAY=192.168.1.251
