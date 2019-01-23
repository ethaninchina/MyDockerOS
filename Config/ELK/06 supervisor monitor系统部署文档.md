## 一、supervisor安装配置

#1.安装supervisor
```shell
easy_install supervisor
mkdir /etc/supervisord.conf.d
```
#2.生成supervisord.conf配置文件
```shell
cat >/etc/supervisord.conf<<EOF
[unix_http_server]
file=/tmp/supervisor.sock   ; the path to the socket file
[inet_http_server]  
port=0.0.0.0:9001  
username=admin   
password=admin 
[supervisord]
logfile=/tmp/supervisord.log ; main log file; default $CWD/supervisord.log
logfile_maxbytes=50MB        ; max main logfile bytes b4 rotation; default 50MB
logfile_backups=10           ; # of main logfile backups; 0 means none, default 10
loglevel=info                ; log level; default info; others: debug,warn,trace
pidfile=/tmp/supervisord.pid ; supervisord pidfile; default supervisord.pid
nodaemon=false               ; start in foreground if true; default false
minfds=1024                  ; min. avail startup file descriptors; default 1024
minprocs=200                 ; min. avail process descriptors;default 200
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
[supervisorctl]
serverurl=unix:///tmp/supervisor.sock ; use a unix:// URL  for a unix socket
[include]  
files = /etc/supervisord.conf.d/*.conf 
EOF
```
#3.编辑服务文件
```shell
cat >/etc/init.d/supervisord<<EOF
#!/bin/sh  
#  
# /etc/rc.d/init.d/supervisord  
#  
# Supervisor is a client/server system that  
# allows its users to monitor and control a  
# number of processes on UNIX-like operating  
# systems.  
#  
# chkconfig: - 64 36  
# description: Supervisor Server  
# processname: supervisord  

# Source init functions  
. /etc/init.d/functions

RETVAL=0
prog="supervisord"
pidfile="/tmp/supervisord.pid"
lockfile="/var/lock/subsys/supervisord"

start()
{
        echo -n $"Starting $prog: "  
        daemon --pidfile $pidfile supervisord -c /etc/supervisord.conf
        RETVAL=$?
        echo  
        [ $RETVAL -eq 0 ] && touch ${lockfile}
}

stop()
{
        echo -n $"Shutting down $prog: "  
        killproc -p ${pidfile} /usr/bin/supervisord
        RETVAL=$?
        echo  
        if [ $RETVAL -eq 0 ] ; then
                rm -f ${lockfile} ${pidfile}
        fi
}
case "$1" in

  start)
    start
  ;;

  stop)
    stop
  ;;

  status)
        status $prog
  ;;

  restart)
    stop
    start
  ;;

  *)
    echo "Usage: $0 {start|stop|restart|status}"  
  ;;

esac
EOF
chmod +x /etc/init.d/supervisord
```
#4.生成测试文档
```shell
cat >/etc/supervisord.conf.d/test.conf <<EOF
[program:nginx]
command = /usr/local/nginx/sbin/nginx  -g 'daemon off;'
autostart=true
autorestart=true
startsecs=5
EOF
```

#5.服务设置
```shell
chkconfig supervisord on
service supervisord start
```

## 二、php安装
#1.安装依赖
```shell
yum install -y  m4  autoconf libmcrypt-devel net-snmp-devel gcc gcc-c++ libxml2 libxml2-devel bzip2 bzip2-devel  openssl openssl-devel libcurl-devel libjpeg-devel libpng-devel freetype-devel readline readline-devel libxslt-devel perl perl-devel psmisc.x86_64 recode recode-devel
```
#2.下载php
```shell
mkdir -p  /usr/local/src/php5.6  
cd /usr/local/src/php5.6
wget http://am1.php.net/distributions/php-5.6.33.tar.gz
tar -zxvf php-5.6.33.tar.gz
```
#3.编译php
```shell
cd /usr/local/src/php5.6/php-5.6.33
./configure  --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc  --enable-fpm  --with-zlib --enable-mbstring --with-openssl --with-mysql --with-mysqli --with-mysql-sock --with-gd --with-jpeg-dir=/usr/lib --enable-gd-native-ttf --enable-pdo --with-curl --with-pdo-mysql --enable-sockets --enable-bcmath --enable-xml --with-bz2 --with-gettext --enable-zip --with-snmp  --with-png-dir=/usr/lib  --enable-soap --enable-calendar --enable-pcntl
make  && make install
```
#4.设置用户和路径
```shell
groupadd www 
useradd -g www www
mkdir -p /var/lib/php/session/ 
chmod 777 -R /var/lib/php/session/
```
#5.编辑相关配置
```shell
cd /usr/local/php/etc/
wget http://119.23.70.160/php/php.tar.gz
tar -zxvf php.tar.gz
chmod +x php-fpm 
mv php-fpm /etc/init.d/
```
#6.配置环境变量
```shell
echo 'export PATH=$PATH:/usr/local/php/bin' >> /etc/profile
source /etc/profile
```
#7.设置相关服务
```shell
service php-fpm start
chkconfig --add php-fpm
chkconfig php-fpm on
```
## 三、nginx配置
```shell
yum -y install httpd-tools
htpasswd -c /data/supervisord-monitor/application/config/password admin
```
```shell
cat> /usr/local/nginx/conf/vhost/supervisor.conf<<EOF
server {
    listen       82 default_server;
    server_name  localhost;

    auth_basic "Please input password"; 
    auth_basic_user_file /data/supervisord-monitor/application/config/password;

    root         /data/supervisord-monitor/public_html;
    location / {
        index  index.php index.html;
    }
    location /control/ {
        index  index.php;
        rewrite  /(.*)$  /index.php?$1  last;
    }
    location ~ .php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        fastcgi_param  SCHEME $scheme;
        include        fastcgi_params;
    }
}
EOF
```
## 四、下载项目地址
```shell
mkdir /data
cd /data
git clone https://github.com/mlazarov/supervisord-monitor.git
echo "手动修改相关配置"
echo "vim /data/supervisord-monitor/application/config/supervisor.php"
echo "nginx -s reload"
```

