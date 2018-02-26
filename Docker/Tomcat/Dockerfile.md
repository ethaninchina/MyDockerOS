### nginx+tomcat8+java1.8+redis3.2
```
FROM daocloud.io/library/centos:7
MAINTAINER wyz test@test.com
#nginx+tomcat8+java1.8+redis3.2
#服务器基础设置
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && echo 'Asia/Shanghai' > /etc/timezonesource /etc/profile
#更换yum源
RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
#安装基础工具
RUN yum install epel-release -y && yum update -y \
    && yum install vim wget git net-tools telnet lrzsz -y

#安装supervisor,crontab
RUN yum install -y supervisor && easy_install supervisor \
    && yum install vixie-cron crontabs -y

# 安装nginx,java,redis
RUN cd /opt \
    && yum install nginx java redis -y \
    && curl -o tomcat-8.0.tar.gz http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.0.50/bin/apache-tomcat-8.0.50.tar.gz \
    && curl -o tomcat-8.5.tar.gz http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.28/bin/apache-tomcat-8.5.28.tar.gz \
    && tar zxvf tomcat-8.0.tar.gz && tar zxvf tomcat-8.5.tar.gz 

#删除匹配行避免nginx启动出错(ipv6识别错误)
RUN sed -i '/[::]/d' /etc/nginx/nginx.conf \
    && sed -i '/nginx.pid;/a\\daemon off;' /etc/nginx/nginx.conf

#配置supervisor nginx + tomcat +redis
RUN echo [supervisord] > /etc/supervisord.conf \
    && echo nodaemon=true >> /etc/supervisord.conf \
    \
    && echo [program:nginx] >> /etc/supervisord.conf \
    && echo command=/usr/sbin/nginx >> /etc/supervisord.conf \
    \
    && echo [program:tomcat] >> /etc/supervisord.conf \
    && echo command=/opt/apache-tomcat-8.0.50/bin/catalina.sh run >> /etc/supervisord.conf \
    \
    && echo [program:redis] >> /etc/supervisord.conf \
    && echo command=/usr/bin/redis-server /etc/redis.conf >> /etc/supervisord.conf \
    \
    && echo [program:crond] >> /etc/supervisord.conf \
    && echo command=/usr/sbin/crond -n >> /etc/supervisord.conf
 
 EXPOSE 80 443 8080 6379
CMD ["/usr/bin/supervisord"]

#docker run -p 8080:8080 -h "tomcat8" --name=nginx-tomcat8-redis32 --restart=always -d ntr-test2

#连接宿主机mysql服务使用host网络
#docker run --net=host -h "tomcat8" --name=nginx-tomcat8-redis32 --restart=always -d ntr-test2
```
