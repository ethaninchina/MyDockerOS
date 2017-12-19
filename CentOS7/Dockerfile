FROM centos:7
MAINTAINER wyz test@test.com

#php版本,因为php版本间配置文件模板不相同，此处的版本号为大于7.0以上版本
ARG PHP_VER=7.1.12
#nginx 版本,此处为 Openresty
ARG NGINX_VER=1.13.6.1
#redis版本
ARG REDIS_VER=3.2.9
#redis密码
ARG REDIS_PASS=123456

#服务器基础设置
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && echo 'Asia/Shanghai' > /etc/timezonesource /etc/profile \
     && useradd -M -s /sbin/nologin nginx \
     && useradd -M -s /sbin/nologin PHP-FPM \
#更换yum源
    && mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
#安装基础工具
    && yum install vim wget git net-tools -y \
#安装supervisor
    && yum install python-setuptools -y && easy_install supervisor \
#安装php
    && yum install epel-release -y && yum update -y \
    && yum -y install pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel libpng libpng-devel curl curl-devel libicu libicu-devel libmcrypt  libmcrypt-devel freetype freetype-devel libmcrypt libmcrypt-devel autoconf gcc-c++ \
    && cd /usr/src \
    && curl -o php.tar.gz http://php.net/get/php-${PHP_VER}.tar.gz/from/this/mirror -L && mkdir php && tar -xzvf php.tar.gz -C ./php --strip-components 1 \
    && cd php \
    && ./configure --prefix=/usr/local/php --with-config-file-path=/etc/php --enable-soap --enable-mbstring=all --enable-sockets --enable-session --with-gettext --with-xmlrpc --enable-fpm --with-gd --with-freetype-dir=/usr/include/freetype2/freetype --with-jpeg-dir=/usr/lib64 --with-zlib --with-iconv --enable-libxml --enable-xml --enable-intl --enable-zip --enable-inline-optimization --enable-ftp --enable-gd-native-ttf --enable-pcntl --enable-shmop --enable-sysvsem --enable-mbregex --enable-bcmath --enable-maintainer-zts --with-curl --with-mcrypt --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    && make && make install \
    && mkdir /etc/php \
    && cp /usr/src/php/php.ini-development /etc/php/php.ini \
    && cp /usr/src/php/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && chmod +x /etc/init.d/php-fpm \
    && cd /usr/local/php/etc \
    && cp php-fpm.conf.default php-fpm.conf \
    && sed -i "s/;daemonize = yes/daemonize = no/" php-fpm.conf \
    && cp ./php-fpm.d/www.conf.default ./php-fpm.d/www.conf \
    && sed -i "s/export PATH/PATH=\/usr\/local\/php\/bin:\$PATH\nexport PATH/" /etc/profile \
    && sed -i "s/export PATH/PATH=\/etc\/init.d:\$PATH\nexport PATH/" /etc/profile \
#安装nginx/Openresty
    && cd /usr/src \
    && curl -o nginx.tar.gz https://openresty.org/download/openresty-${NGINX_VER}.tar.gz && mkdir nginx && tar -zxvf nginx.tar.gz -C ./nginx --strip-components 1 \
    && cd nginx \
    && ./configure --prefix=/opt/openresty --user=nginx --group=nginx --with-luajit --with-http_iconv_module --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --with-pcre --with-http_dav_module \
     && make && make install \
     && echo "#!/bin/sh" > /etc/init.d/nginx \
     && echo "#description: Nginx web server." >> /etc/init.d/nginx \
     && echo -e "case \$1 in \n\
            restart): \n\
                echo -n "restart" \n\
                /opt/openresty/nginx/sbin/nginx -s stop \n\
                /opt/openresty/nginx/sbin/nginx \n\
                ;; \n\
            reload): \n\
                echo -n "reload" \n\
                /opt/openresty/nginx/sbin/nginx -s reload \n\
                ;; \n\
            stop): \n\
                echo -n "stop" \n\
                /opt/openresty/nginx/sbin/nginx -s stop \n\
                ;; \n\
            -t): \n\
                /opt/openresty/nginx/sbin/nginx -t \n\
                ;; \n\
            start): \n\
                echo -n "start" \n\
                /opt/openresty/nginx/sbin/nginx \n\
                ;; \n\
        esac \n" >> /etc/init.d/nginx \
    && chmod +x /etc/init.d/nginx \
    && sed -i "3a daemon off;" /opt/openresty/nginx/conf/nginx.conf \
    && sed -i "s/#pid/pid/g" /opt/openresty/nginx/conf/nginx.conf \
#安装redis server
    && cd /usr/src \
    && curl -o redis.tar.gz http://download.redis.io/releases/redis-${REDIS_VER}.tar.gz -L && mkdir redis && tar -xzvf redis.tar.gz -C ./redis --strip-components 1 \
    && cd /usr/src/redis \
    && make \
    && make install \
    && mkdir -p /usr/local/redis/bin \
    && cp ./src/redis-server /usr/local/redis/bin/ \
    && cp ./src/redis-cli /usr/local/redis/bin/ \
    && cp ./src/redis-benchmark /usr/local/redis/bin/ \
    && cp ./redis.conf /etc/redis.conf \
    && sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf \
    && sed -i "s/# requirepass foobared/requirepass ${REDIS_PASS}/" /etc/redis.conf \
    && echo -e "# description: Redis server. \n\
         case \$1 in \n\
            restart): \n\
                /usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 6379 -a 123456 shutdown \n\
                /usr/local/redis/bin/redis-server /etc/redis.conf \n\
                ;; \n\
            stop): \n\
                /usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 6379 -a 123456 shutdown \n\
                ;; \n\
            *): \n\
                /usr/local/redis/bin/redis-server /etc/redis.conf \n\
         esac" > /etc/init.d/redis \
    && chmod +x /etc/init.d/redis \
#安装php redis扩展
    && /usr/local/php/bin/pecl install redis && echo "extension=redis.so" >> /etc/php/php.ini \
#安装php swoole扩展
    && /usr/local/php/bin/pecl install swoole && echo "extension=swoole.so" >> /etc/php/php.ini \
#安装php mongodb扩展
    && /usr/local/php/bin/pecl install mongodb && echo "extension=mongodb.so" >> /etc/php/php.ini \

#安装必要的服务
    && cd /usr/src && /usr/local/php/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && /usr/local/php/bin/php composer-setup.php  --install-dir=/usr/local/bin --filename=composer && rm -rf composer-setup.php && /usr/local/php/bin/php /usr/local/bin/composer config -g repo.packagist composer https://packagist.phpcomposer.com \

#配置supervisor
    && echo [supervisord] > /etc/supervisord.conf \
    && echo nodaemon=true >> /etc/supervisord.conf \
    \
    && echo [program:nginx] >> /etc/supervisord.conf \
    && echo command=/etc/init.d/nginx start >> /etc/supervisord.conf \
    \
    && echo [program:php-fpm] >> /etc/supervisord.conf \
    && echo command=/etc/init.d/php-fpm start >> /etc/supervisord.conf \
    \
    && echo [program:redis] >> /etc/supervisord.conf \
    && echo command=/usr/local/redis/bin/redis-server /etc/redis.conf >> /etc/supervisord.conf

EXPOSE 80 443 6379
CMD ["/usr/bin/supervisord"]
