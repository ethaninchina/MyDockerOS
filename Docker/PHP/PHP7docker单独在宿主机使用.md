- 相关配置下载
        #### wget https://raw.githubusercontent.com/station19/MyDockerOS/master/Docker/wwwdocker/wwwdocker.tar.gz

- 启动脚本服务
```shell
#!/bin/bash
#停止/清空无效的容器记录
docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)

#启动docker容器
docker run --name PHP7 \
--restart=always \
--net=host \
-v /data0/docker/website/ooxx/PSI:/tmp/html \ #宿主机项目存放目录 映射到 PHP7容器/tmp/html目录
-v /data0/docker/logs/php_log:/tmp/phplogs \
-v /data0/docker/php/php.ini:/etc/php/php.ini \
-v /data0/docker/php/www.conf:/usr/local/php/etc/php-fpm.d/www.conf \
-d registry.cn-hangzhou.aliyuncs.com/webss/php:7
```

- 宿主机 服务： nginx 1.12 、 mysql 5.6 
- docker容器服务： PHP7.1.12               
- nginx 配置如下：

```shell
server {
        listen             80;
        server_name crm8000.ooxx.com;
        root /data0/docker/website/ooxx/PSI; #宿主机 root 根目录和下面的php解析root根目录在docker启动时候对应
        index  index.html index.htm default.htm index.php;
        
        location / {
        if (!-e $request_filename){
               rewrite ^/(.*)$ /index.php last; #重定向不匹配的路径
        }
        }
        
       # nginx 中php解析设置
        location ~ .*\.(php|php5|php7)?$ 
        {
                root /tmp/html; #因为php是容器化,所以这里root地址填写docker容器内项目存放真实地址 { -v /data0/docker/website/ooxx/PSI:/tmp/html }
                fastcgi_pass  127.0.0.1:9191; #容器php映射的端口
                fastcgi_index index.php;
                include fastcgi.conf;
        }
}
```
