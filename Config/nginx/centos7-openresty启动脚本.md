```
vim /usr/lib/systemd/system/nginx.service

[Unit]
Description=The nginx HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/openresty/nginx/logs/nginx.pid
ExecStartPre=/usr/local/openresty/nginx/sbin/nginx -t
ExecStart=/usr/local/openresty/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target

#保存退出



#增加环境变量到系统环境
echo 'export PATH=$PATH:/usr/local/openresty/nginx/sbin' >> /etc/profile
. /etc/profile


#设置开机启动
systemctl enable nginx.service

#启动
systemctl start nginx.service

```
