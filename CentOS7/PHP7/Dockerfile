FROM centos:7
MAINTAINER wyz test@test.com

#php版本,因为php版本间配置文件模板不相同，此处的版本号为大于7.0以上版本
ARG PHP_VER=7.1.12

#服务器基础设置
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && echo 'Asia/Shanghai' > /etc/timezonesource /etc/profile \
     && useradd -M -s /sbin/nologin PHP-FPM 

#更换yum源
RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#安装基础工具
RUN yum install epel-release -y && yum update -y \
    && yum install vim wget git net-tools telnet -y

#安装supervisor
RUN yum install -y supervisor && easy_install supervisor


#安装php
RUN yum -y install pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel libpng libpng-devel curl curl-devel libicu libicu-devel libmcrypt  libmcrypt-devel freetype freetype-devel libmcrypt libmcrypt-devel autoconf gcc-c++
WORKDIR /usr/src
RUN curl -o php.tar.gz http://php.net/get/php-${PHP_VER}.tar.gz/from/this/mirror -L && mkdir php && tar -xzvf php.tar.gz -C ./php --strip-components 1
WORKDIR php
RUN ./configure --prefix=/usr/local/php --with-config-file-path=/etc/php --enable-soap --enable-mbstring=all --enable-sockets --enable-session --with-gettext --with-xmlrpc --enable-fpm --with-gd --with-freetype-dir=/usr/include/freetype2/freetype --with-jpeg-dir=/usr/lib64 --with-zlib --with-iconv --enable-libxml --enable-xml --enable-intl --enable-zip --enable-inline-optimization --enable-ftp --enable-gd-native-ttf --enable-pcntl --enable-shmop --enable-sysvsem --enable-mbregex --enable-bcmath --enable-maintainer-zts --with-curl --with-mcrypt --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    && make && make install \
    && mkdir /etc/php \
    && cp /usr/src/php/php.ini-development /etc/php/php.ini \
    && cp /usr/src/php/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && chmod +x /etc/init.d/php-fpm
WORKDIR /usr/local/php/etc
RUN cp php-fpm.conf.default php-fpm.conf \
    && sed -i "s/;daemonize = yes/daemonize = no/" php-fpm.conf \
    && cp ./php-fpm.d/www.conf.default ./php-fpm.d/www.conf \
    && sed -i '$a export PATH=\$PATH:\/usr\/local\/php\/bin:\/etc\/init.d' /etc/profile

#安装php redis扩展
RUN /usr/local/php/bin/pecl install redis && echo "extension=redis.so" >> /etc/php/php.ini

#安装php mongodb扩展
RUN /usr/local/php/bin/pecl install mongodb && echo "extension=mongodb.so" >> /etc/php/php.ini

#安装php swoole扩展
RUN /usr/local/php/bin/pecl install swoole && echo "extension=swoole.so" >> /etc/php/php.ini

#安装必要的服务
RUN yum install vixie-cron crontabs -y \
     && cd /usr/src && /usr/local/php/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && /usr/local/php/bin/php composer-setup.php  --install-dir=/usr/local/bin --filename=composer && rm -rf composer-setup.php && /usr/local/php/bin/php /usr/local/bin/composer config -g repo.packagist composer https://packagist.phpcomposer.com

#配置supervisor
WORKDIR ~/
RUN echo [supervisord] > /etc/supervisord.conf \
    && echo nodaemon=true >> /etc/supervisord.conf \
    \
    && echo [program:php-fpm] >> /etc/supervisord.conf \
    && echo command=/etc/init.d/php-fpm start >> /etc/supervisord.conf \
    \
    && echo [program:crond] >> /etc/supervisord.conf \
    && echo command=/usr/sbin/crond -n >> /etc/supervisord.conf

EXPOSE 9000

CMD ["/usr/bin/supervisord"]
