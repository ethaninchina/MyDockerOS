#!/bin/bash
docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)

# start mysql 
docker run --name mysql57 \
--restart=always \
-h "mysql57" \
--net=host \
-e MYSQL_ROOT_PASSWORD=123456 \
-v /root/mysqld/config:/etc/mysql \
-v /root/mysqld/mysqldata:/var/lib/mysql \
-v /root/logs/mysql_log:/var/log/mysql \
-d docker.io/mysql:5.7

#start openresty+php7+redis
docker run --name lrnphp7 \
-h "lrnphp7" \
--restart=always \
--net=host \
-v /root/web:/opt/openresty/nginx/html \
-v /root/logs/nginx_log:/opt/openresty/nginx/logs \
-v /root/logs/php_log:/tmp/phplogs \
-v /root/php/php.ini:/etc/php/php.ini \
-v /root/php/www.conf:/usr/local/php/etc/php-fpm.d/www.conf \
-v /root/nginx-conf:/opt/openresty/nginx/conf \
-d docker.io/wuyuzai/mydockeros:lrnp

