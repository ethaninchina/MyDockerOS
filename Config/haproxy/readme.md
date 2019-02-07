confd 配置参考 https://github.com/station19/MyDockerOS/blob/master/Config/nginx/etcd%2Bconfd/readme.md

```
mkdir -p /etc/confd/{conf.d,templates}
```
##### conf.d 
```
vim /etc/confd/conf.d/haproxy.toml

[template]
#模板文件，基于它进行修改
src = "haproxy.cfg.tmpl"
#haproxy的默认配置路径
dest = "/etc/haproxy/haproxy.cfg"
#keys是在etcd上订阅消息的前缀
keys = [
  "/app/servers",
]
#更新配置后重启haproxy
reload_cmd = "/etc/init.d/haproxy reload"
```

##### templates 模板文件
```
vim /etc/confd/templates/haproxy.cfg.tmpl

global
        log 127.0.0.1 local3
        maxconn 5000
        uid 99
        gid 99
        daemon

defaults
        log 127.0.0.1 local3
        mode http
        option dontlognull
        retries 3
        option redispatch
        maxconn 2000
        timeout connect 5000
        timeout client  50000
        timeout server  50000

frontend myhttp
        mode http
        bind 192.168.1.204:80
        use_backend myserver
        
backend myserver
        mode http
        balance roundrobin
        #confd的语法会替换下面的变量
        {{range gets "/app/servers/*"}}
        server {{base .Key}} {{.Value}} weight 10
        {{end}}
```
