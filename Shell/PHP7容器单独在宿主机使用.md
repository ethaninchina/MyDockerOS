# 相关配置下载
wget https://raw.githubusercontent.com/station19/MyDockerOS/master/Shell/wwwdocker/wwwdocker.tar.gz

# ################启动脚本服务
#!/bin/bash
#停止/清空无效的容器记录
#docker stop $(docker ps -a -q)
#docker rm -f $(docker ps -a -q)

#启动docker容器
docker run --name PHP7 \
--restart=always \
--net=host \
-v /data0/docker/website/crm8000/PSI:/tmp/html \ #宿主机项目存放目录 映射到 PHP7容器/tmp/html目录
-v /data0/docker/logs/php_log:/tmp/phplogs \
-v /data0/docker/php/php.ini:/etc/php/php.ini \
-v /data0/docker/php/www.conf:/usr/local/php/etc/php-fpm.d/www.conf \
-d registry.cn-hangzhou.aliyuncs.com/webss/php:7


# 宿主机服务： nginx 1.12 、 mysql 5.6 
# 容器  服务： PHP7.1.12               
 

#nginx配置
server {
        listen             80;
        server_name crm8000.ooxx.com;
        root /data0/docker/website/crm8000/PSI; #宿主机 nginx指定根目录
        index  index.html index.htm default.htm index.php;
        
        location / {
        if (!-e $request_filename){
               rewrite ^/(.*)$ /index.php last; #重定向不匹配的路径
        }
        }
        
       # nginx 中php解析设置
        location ~ .*\.php { 
                root /tmp/html; #php容器项目目录,如果和nginx的root目录不对应，请在这里要添加php容器的项目目录
                fastcgi_pass  127.0.0.1:9191; #如 容器内PHP7服务端口为9191
                fastcgi_index index.php;
                include fastcgi.conf;
        }
}

