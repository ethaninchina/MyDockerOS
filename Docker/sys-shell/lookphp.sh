#!/bin/bash
#sync && echo 3 > /proc/sys/vm/drop_caches
url="http://127.0.0.1:81/phpstatus"
status=$(curl -s --head --connect-timeout 90 "$url" | awk '/HTTP/ {print $2}')
if [ "$status" != "200" ]; then

kill -INT `cat /var/run/php7-fpm.pid`
wait
/usr/local/php7/sbin/php-fpm -c /usr/local/php7/lib/php.ini -y /usr/local/php7/etc/php-fpm.conf
fi
