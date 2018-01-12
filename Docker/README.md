### 安装部署 `docker` 服务

- 安装 `docker`
```
yum install epel-release -y
yum update -y
yum install docker -y

systemctl enable docker.service
systemctl start docker.service
```

- 安装 `docker-compose`
```
curl -L https://get.daocloud.io/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
```

### 暂停/恢复容器服务
- 暂停所有服务
```docker-compose pause``` 
- 暂停web服务的容器
```docker-compose pause web ```

- 复容器服务
恢复所有服务
```docker-compose unpause```
- 恢复web服务的容器
```docker-compose unpause web```


### 配置镜像加速
```
cat>/etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://nuqr3lew.mirror.aliyuncs.com"]
}
EOF
```

- 重启docker服务生效
```
systemctl restart docker.service
```


### push到阿里云镜像
```
docker login --username=ooxx registry.cn-hangzhou.aliyuncs.com

docker push php7
```
