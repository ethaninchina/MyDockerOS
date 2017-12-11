#生成新镜像,基于私有仓库 daocloud.io/library/centos:6.8
#docker build --no-cache -t clnp-ssh-v3 .
FROM daocloud.io/library/centos:6.8
#作者信息
MAINTAINER wyz "wyz@test.com"
#安装各种服务，修改时区
RUN yes|cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#创建文件夹
RUN mkdir -p /data/docker/logs /data/docker/website /opt/backup
#创建使用用户 nginx apache
RUN useradd -M -s /sbin/nologin nginx && useradd -M -s /sbin/nologin apache

#添加nginx源
ADD nginx/nginx.repo /etc/yum.repos.d/

#下载安装nginx、PHP源
RUN rpm -Uvh http://ftp.iij.ad.jp/pub/linux/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm \
&& rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm \
&& yum update -y

#安装ssh和其他相关依赖
RUN yum install -y vim git openssh-server ntp make openssl openssl-devel pcre pcre-devel libpng libpng-devel libjpeg libjpeg-devel freetype freetype-devel gd gd-devel zlib zlib-devel gcc gcc-c++ libXpm libXpm-devel ncurses ncurses-devel libmcrypt libmcrypt-devel libxml2 libxml2-devel imake autoconf automake screen sysstat compat-libstdc++-33 curl curl-devel readline-devel libxslt-devel net-snmp-devel readline-devel aspell-devel unixODBC-devel libicu-devel libc-client-devel  freetype-devel libXpm-devel libpng-devel libvpx-devel enchant-devel libcurl-devel libssl-dev bzip2-devel db4-devel gmp-devel openldap-devel unixODBC-devel net-snmp-devel aspell-devel libxml2-devel libicu-devel libmcrypt-devel libtidy-devel

#安装nginx
RUN yum install -y nginx

#安装php-fpm和PHP插件
RUN yum install -y --enablerepo=remi --enablerepo=remi-php56 php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-pecl-xdebug php-pecl-xhprof php-fpm php-redis php-pecl-mongo php-gd php-gmp php-imap php-tidy php-ldap

#安装supervisord
RUN yum -y install python-pip \
&& pip install supervisor \
&& pip install setuptools --upgrade

#关闭php的 deamon模式，nginx在配置上面已经标注,修改ssh配置
RUN sed -i 's/daemonize = yes/daemonize = no/g' /etc/php-fpm.conf
RUN sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
RUN echo 123456 | passwd --stdin root
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key  
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key 
RUN mkdir /var/run/sshd

#拷贝配置文件
#ADD nginx/nginx.conf /etc/nginx/
#ADD php/php.ini /etc/ 
#ADD php-fpm.d/www.conf /etc/php-fpm.d/
#ADD supervisord.conf /etc/supervisord.conf
#ADD data.tar.gz /opt/backup/

#开放端口
EXPOSE 22
EXPOSE 80

#启动后执行脚本
ENTRYPOINT ["/usr/bin/supervisord"]
