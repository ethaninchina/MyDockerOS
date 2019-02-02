##### nginx 利用官方源 repo 安装 
```
yum install yum-utils -y
curl -o /etc/yum.repos.d/nginx.repo https://raw.githubusercontent.com/station19/MyDockerOS/master/repo/nginx.repo
yum-config-manager --enable nginx-mainline
yum install nginx -y
```

