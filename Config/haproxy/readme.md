##### 利用confd+etcd管理 haproxy 配置(服务注册)
confd +eetcd 配置参考 https://github.com/station19/MyDockerOS/blob/master/Config/nginx/etcd%2Bconfd/readme.md

##### conf.d
```
mkdir -p /etc/confd/{conf.d,templates}

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

centos下haproxy日志的配置 
```
涉及到的配置文件如下
 
 1)  /etc/haproxy/haproxy.conf  //这个是haproxy程序的主配置文件，具体路径可以随意指定,主要是下面这句话
   
    log         localhost   local0
 
 2)  /etc/rsyslog.conf           //这个配置文件不用动，默认会有下面的设置，会读取 /etc/rsyslog.d/*.conf目录                                 //下的配置文件
    $IncludeConfig /etc/rsyslog.d/*.conf
 
 3)  /etc/rsyslog.d/haproxy.conf //这个文件是需要我们手动创建的，内容如下：
 cat /etc/rsyslog.d/haproxy.conf
 $ModLoad imudp
 $UDPServerRun 514 
 $template Haproxy,"%rawmsg% \n"
 local0.=info -/var/log/haproxy.log;Haproxy
 local0.notice -/var/log/haproxy-status.log;Haproxy
 ### keep logs in localhost ##
 local0.* ~ 
 
 4)  /etc/sysconfig/rsyslog 内容如下
 # Options for rsyslogd
 # Syslogd options are deprecated since rsyslog v3.
 # If you want to use them, switch to compatibility mode 2 by "-c 2"
 # See rsyslogd(8) for more details
 SYSLOGD_OPTIONS="-c 2 -r -m 0"
 
 备注:
 #-c 2 使用兼容模式，默认是 -c 5
 #-r 开启远程日志
 #-m 0 标记时间戳。单位是分钟，为0时，表示禁用该功能
 
 好了，日志配置主要就是涉及到这几个文件了。

 
 另外，再重启下rsyslog和haproxy服务就可以了
 #centos 6: 
 /etc/init.d/rsyslog restart
 
 #centos 7: 
 systemctl restart rsyslog
 
 killlall -9 haproxy && haproxy -f /etc/haproxy/haproxy.conf
 
 
 最后，最重要的一点，一定要把iptables udp 514端口开起来
 
 iptables -I INPUT -m udp -p udp --dport 514 -j ACCEPT
 
 否则有可能会报一堆错误，类似下面这样子：
 
 sendto logger #0 failed: operation not permitted (errno=1)
 ```


