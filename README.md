#### dockerfile 配置文件在 docker分支

    https://github.com/station19/MyDockerOS/tree/docker

### 以下适合centos7 安装LNMP镜像服务 
··· 服务软件
- openresty
- php7
    - 扩展包括
```shell
[PHP Modules]
bcmath
Core
ctype
curl
date
dom
fileinfo
filter
ftp
gd
gettext
hash
iconv
json
libxml
mbstring
mcrypt
memcached
mongodb
mysqli
mysqlnd
openssl
pcre
PDO
pdo_mysql
pdo_sqlite
Phar
posix
readline
redis
Reflection
session
SimpleXML
soap
sockets
SPL
sqlite3
standard
tokenizer
xdebug
xml
xmlreader
xmlwriter
Zend OPcache
zip
zlib
[Zend Modules]
Xdebug
Zend OPcache
```
- redis
- Mysql
- shadowsocks

#### ① Centos7镜像制作
- `Cenetos7`版 docker容器服务 `LNMP(openresty+php7+redis++Mysql)` + `shadowsocks`
```shell
curl -O https://raw.githubusercontent.com/station19/MyDockerOS/master/Docker/start_web_docker-compose.sh && chmod +x start_web_docker-compose.sh && ./start_web_docker-compose.sh
```
#### ② Alpine Linux镜像制作
- `Alpine Linux`版 docker容器服务 `LNMP(openresty+php7+redis++Mysql)` + `shadowsocks`
```shell
curl -O https://raw.githubusercontent.com/station19/MyDockerOS/master/Docker/start_web_docker-compose-alpine.sh && chmod +x start_web_docker-compose-alpine.sh && ./start_web_docker-compose-alpine.sh
```
