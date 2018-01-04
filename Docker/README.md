### 存放docker相关服务

- 安装 `docker` 服务
```shell
yum install epel-release -y
yum update -y
yum install docker -y

systemctl enable docker.service
systemctl start docker.service
```

- 安装 `docker-compose`
```shell
curl -L https://get.daocloud.io/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
```

### 配置镜像加速
```shell
cat>/etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://nuqr3lew.mirror.aliyuncs.com"]
}
EOF
```

- 重启docker服务生效
```shell
systemctl restart docker.service
```


### push到阿里云镜像
```shell
docker login --username=ooxx registry.cn-hangzhou.aliyuncs.com

docker push ...
```
