# 升级/迁移
- 小版本升级（例如从 10.1.3 升级到 10.1.5）/迁移到其他主机,为了预防万一， 还是建议先备份一下  /root/gitlab/ 这个目录.

参照官方的说明， 将原来的容器停止， 然后删除：
```shell
docker stop registry.cn-hangzhou.aliyuncs.com/webss/gitlab
docker rm registry.cn-hangzhou.aliyuncs.com/webss/gitlab
```

然后重新拉一个新版本的镜像 (如下)
```shell
docker pull registry.cn-hangzhou.aliyuncs.com/webss/gitlab
```

```shell
cat > ~/docker-compose.yml << EOF
version: '2'
services:
    github:
            image: registry.cn-hangzhou.aliyuncs.com/webss/gitlab
            volumes:
                - /root/gitlab/etc:/etc/gitlab
                - /root/gitlab/log:/var/log/gitlab:rw
                - /root/gitlab/data:/var/opt/gitlab
            restart: always
            ports:
                - 8090:80
                - 8443:443
            container_name: gitlab_cn
EOF
```

使用原来的运行命令运行:
```shell
docker-compose -f ~/docker-compose.yml 
```

- GitLab 在初次运行的时候会自动升级.
大版本升级（例如从 10.1.3 升级到 10.2.5）用上面的操作有可能会出现错误,如果出现错误可以尝试登录到容器内部,可以用 docker exec,也可以用 ssh ,依次执行下面的命令：

```shell
gitlab-ctl reconfigure
gitlab-ctl restart
```
