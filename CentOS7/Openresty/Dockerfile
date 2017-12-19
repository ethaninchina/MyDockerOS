FROM centos:7
MAINTAINER wyz test@test.com

#nginx 版本,此处为 Openresty
ARG NGINX_VER=1.13.6.1

#服务器基础设置
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && echo 'Asia/Shanghai' > /etc/timezonesource /etc/profile \
     && useradd -M -s /sbin/nologin nginx \
     && useradd -M -s /sbin/nologin PHP-FPM \
#更换yum源
    && mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
#安装基础工具
    && yum install vim wget git net-tools -y \
#安装supervisor
    && yum install python-setuptools -y && easy_install supervisor \
#安装php需要的依赖
    && yum install epel-release -y && yum update -y \
    && yum -y install pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel libpng libpng-devel curl curl-devel libicu libicu-devel libmcrypt  libmcrypt-devel freetype freetype-devel libmcrypt libmcrypt-devel autoconf gcc-c++ \
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
#配置supervisor
    && cd \
    && echo [supervisord] > /etc/supervisord.conf \
    && echo nodaemon=true >> /etc/supervisord.conf \
    \
    && echo [program:nginx] >> /etc/supervisord.conf \
    && echo command=/etc/init.d/nginx start >> /etc/supervisord.conf

EXPOSE 80 443
CMD ["/usr/bin/supervisord"]
