- 配置镜像加速
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


- 登陆阿里云docker镜像服务
```shell
docker login --username=ooxx registry.cn-hangzhou.aliyuncs.com

docker push ...
```
