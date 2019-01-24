##### 源服务器 配置
yum install rsync -y

##### 编辑配置
vim /etc/rsyncd.conf

```
uid = root
gid = root
port = 1873
use chroot = no
#最大客户连接数
max connections = 10 
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock

#要同步的模块名
[nginx_sync]
comment = nginx conf rsync
#要同步的目录
path = /usr/local/openresty/nginx/conf/  
#hosts allow = 10.186.45.51,10.186.45.52,10.186.45.53
#hosts deny = 192.168.1.4
auth users = root
secrets file = /etc/rsyncd.password
```

##### 设置auth 账户/密码
```
echo "root:rsyncrootpass">>/etc/rsyncd.password
chmod 600 /etc/rsyncd.password
```

##### 启动rsync,添加rsync到系统服务
```
#/usr/bin/rsync --daemon --config=/etc/rsyncd.conf

cat>/usr/lib/systemd/system/rsyncd.service<<EOF
[Unit]
Description=rsync service daemon
ConditionPathExists=/etc/rsyncd.conf
 
[Service]
EnvironmentFile=/etc/sysconfig/rsyncd
ExecStart=/usr/bin/rsync --daemon --no-detach "$OPTIONS"
 
[Install]
WantedBy=multi-user.target
EOF
```
```
chmod +x /usr/lib/systemd/system/rsyncd.service
systemctl daemon-reload
systemctl enable rsyncd.service
systemctl start rsyncd.service
systemctl status rsyncd.service
```
### 客户端 
``` 
yum install rsync -y
```
##### 配置客户端的密码,只需要密码即可
```
echo "rsyncrootpass">>/etc/rsyncd.txt
chmod 600 /etc/rsyncd.txt
```
##### 客户端启用rsync传输
```
/usr/bin/rsync --port=1873 -arvz --delete --password-file=/etc/rsyncd.txt root@10.123.3.51::nginx_sync /data/nginx/
```

