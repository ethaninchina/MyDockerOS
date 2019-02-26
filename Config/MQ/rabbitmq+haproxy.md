rabbitmq1,rabbitmq2,rabbitmq3上执行修改 hostname
<br>
```
[root@rabbitmq1 ~] vim /etc/hostname
rabbitmq1
[root@rabbitmq1 ~] hostname rabbitmq1

[root@rabbitmq2 ~] vim /etc/hostname
rabbitmq2
[root@rabbitmq2 ~] hostname rabbitmq2

[root@rabbitmq3 ~] vim /etc/hostname
rabbitmq3
[root@rabbitmq3 ~] hostname rabbitmq3
```
rabbitmq1,rabbitmq2,rabbitmq3上执行修改hosts
<br>
```
[root@rabbitmq1 ~] cat /etc/hosts
10.10.5.171    rabbitmq1
10.10.5.172    rabbitmq2
10.10.5.173    rabbitmq3

[root@rabbitmq2 ~] cat /etc/hosts
10.10.5.171    rabbitmq1
10.10.5.172    rabbitmq2
10.10.5.173    rabbitmq3

[root@rabbitmq3 ~] cat /etc/hosts
10.124.5.171    rabbitmq1
10.124.5.172    rabbitmq2
10.124.5.173    rabbitmq3
```
rabbitmq1,rabbitmq2,rabbitmq3 上安装 Erlang（RabbitMQ 运行需要 Erlang 环境）：
<br>
```
[root@rabbitmq1 ~]# vi /etc/yum.repos.d/rabbitmq-erlang.repo
[rabbitmq-erlang]
name=rabbitmq-erlang
baseurl=https://dl.bintray.com/rabbitmq/rpm/erlang/20/el/7
gpgcheck=1
gpgkey=https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc
repo_gpgcheck=0
enabled=1

[root@rabbitmq1 ~]# yum -y install erlang socat
```
rabbitmq1,rabbitmq2,rabbitmq3 上安装 RabbitMQ Server：
<br>
```
[root@rabbitmq1 ~]# mkdir -p ~/download && cd ~/download
[root@rabbitmq1 download]# wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.15/rabbitmq-server-3.6.15-1.el7.noarch.rpm
[root@rabbitmq1 download]# rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
[root@rabbitmq1 download]# rpm -Uvh rabbitmq-server-3.6.15-1.el7.noarch.rpm
```
rabbitmq1,rabbitmq2,rabbitmq3 修改配置文件, 启动 RabbitMQ Server ：
<br>
```
#改为自定义存储数据目录和日志目录
mkdir -p /data/{rabbitmq,logs}
chown rabbitmq.rabbitmq /data/{rabbitmq,logs}

cat>/etc/rabbitmq/rabbitmq-env.conf<<EOF
RABBITMQ_MNESIA_BASE=/data/rabbitmq
RABBITMQ_LOG_BASE=/data/logs
EOF

#启动 mq
[root@rabbitmq1 download]# systemctl start rabbitmq-server
systemctl enable rabbitmq-server
systemctl status rabbitmq-server

```
rabbitmq1,rabbitmq2,rabbitmq3 安装插件
<br>
```
#启动 RabbitMQ Web 管理控制台
[root@rabbitmq1 ]# rabbitmq-plugins enable rabbitmq_management

 #安装插件将消息从此队列移动到另一个队列功能
[root@rabbitmq1 ]# rabbitmq-plugins enable rabbitmq_shovel rabbitmq_shovel_management  
```
rabbitmq1,rabbitmq2,rabbitmq3 上 RabbitMQ Server 默认guest用户，只能localhost地址访问，我们还需要创建管理用户：
<br>
```
#创建管理员用户 admin
[root@rabbitmq1 ]# rabbitmqctl add_user admin admin123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

##永久配置生效(内存,磁盘,性能等)
##RabbitMQ的配置文件为：/etc/rabbitmq/rabbitmq.config
##RabbitMQ的环境配置文件为：/etc/rabbitmq/rabbitmq-env.conf
##{vm_memory_high_watermark, 0.6},                 #最大使用内存40%，erlang开始GC
##{vm_memory_high_watermark_paging_ratio, 0.8},    #32G内存，32*0.8*0.2时开始持久化磁盘
##{disk_free_limit, "10GB"},                       #磁盘使用量剩余10G时，不收发消息
##{hipe_compile, true},                            #开启hipe，提高erlang性能
##{cluster_partition_handling, autoheal}           #网络优化参数，不稳定时用这个选项,网络分区的自动处理方式 
##{collect_statistics_interval, 10000},            #统计刷新时间默认5秒，改成10秒

cat>/etc/rabbitmq/rabbitmq.config<<EOF
[{rabbit,[{vm_memory_high_watermark,0.6},{vm_memory_high_watermark_paging_ratio, 0.8},{disk_free_limit, "10GB"},{hipe_compile, true},{cluster_partition_handling, autoheal}]}].
EOF


```
rabbitmq1,rabbitmq2,rabbitmq3 上添加防火墙运行访问的端口：
<br>
```
##[root@rabbitmq1 download]# firewall-cmd --zone=public --permanent --add-port=4369/tcp
#firewall-cmd --zone=public --permanent --add-port=25672/tcp
#firewall-cmd --zone=public --permanent --add-port=5671-5672/tcp
#firewall-cmd --zone=public --permanent --add-port=15672/tcp
#firewall-cmd --zone=public --permanent --add-port=61613-61614/tcp
#firewall-cmd --zone=public --permanent --add-port=1883/tcp 
#firewall-cmd --zone=public --permanent --add-port=8883/tcp

#重新启动防火墙：
#[root@rabbitmq1 download]# firewall-cmd --reload
```
常用命令
<br>
```
rabbitmq-server -detached  启动RabbitMQ节点
rabbitmqctl start_app 启动RabbitMQ应用，而不是节点
rabbitmqctl stop_app  停止
rabbitmqctl status  查看状态
rabbitmqctl add_user mq 123456
rabbitmqctl set_user_tags mq administrator 新增账户
rabbitmq-plugins enable rabbitmq_management  启用RabbitMQ_Management
rabbitmqctl cluster_status 集群状态
rabbitmqctl forget_cluster_node rabbit@rabbit3 节点摘除 
rabbitmqctl reset application 重置
```
卸载 RabbitMQ 命令：
<br>
```
#[root@rabbitmq1 ~]# rpm -e rabbitmq-server-3.6.10-1.el7.noarch
#[root@rabbitmq1 ~]# rm -rf /var/lib/rabbitmq/     //清除rabbitmq配置文件
```
RabbitMQ Server 高可用集群,将上面的搭建过程，rabbitmq1上的操作在 rabbitmq2 和 rabbitmq3 服务器上，再做重复一边。
<br>
```
拷贝数据,促成集群,将rabbitmq1上的 /var/lib/rabbitmq/.erlang.cookie 拷贝 到 rabbitmq2 和 rabbitmq3 上
[root@rabbitmq1 ~]# cat  /var/lib/rabbitmq/.erlang.cookie
LBOTELUJAMXDMIXNTZMB

[root@rabbitmq1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@rabbitmq2:/var/lib/rabbitmq
[root@rabbitmq1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@rabbitmq3:/var/lib/rabbitmq
[root@rabbitmq1 ~]# systemctl restart rabbitmq-server
```
以rabbitmq1作为集群中心，在 rabbitmq2 / rabbitmq3 上执行加入集群中心命令（节点类型为磁盘节点）：
<br>
```
#增加内存节点 rabbitmq2 和 rabbitmq3 上操作
[root@ rabbitmq2 ~]# systemctl restart rabbitmq-server
[root@rabbitmq2 ~]# rabbitmqctl stop_app
[root@rabbitmq2 ~]# rabbitmqctl reset

#//默认是磁盘节点，如果是内存节点的话，需要加--ram参数
#[root@rabbitmq2 ~]# rabbitmqctl join_cluster rabbit@rabbitmq1

[root@rabbitmq2 ~]# rabbitmqctl join_cluster rabbit@rabbitmq1 --ram
[root@rabbitmq2 ~]# rabbitmqctl start_app
```
查看集群状态，我们可以在任意一台机器上查看，我们选择在rabbitmq1上看。
<br>
```
[root@rabbitmq1 ~]# rabbitmqctl cluster_status
[root@rabbitmq1 ~]# rabbitmqctl status

试一下容错,关掉rabbitmq3上的实例
[root@rabbitmq3 ~]# rabbitmqctl stop
```
设置镜像队列策略,在任意一个节点上执行下面的命令将所有队列设置为镜像队列，即队列会被复制到各个节点，各个节点状态保持一直
<br>
```
#将所有的queue mirror到cluster中 众多集群中的随机2台机器，且自动同步 (优先级10)
rabbitmqctl set_policy ha-all "^" --priority 10 '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'
```
haproxy 负载rabbitmq安装 , 修改主备haproxy的hosts  (haproxy01,haproxy02)
```
yum install haproxy -y
systemctl enable haproxy
systemctl start haproxy
systemctl status haproxy

#修改hosts 
[root@haproxy01 ~] cat /etc/hosts
10.124.5.171    rabbitmq1
10.124.5.172    rabbitmq2
10.124.5.173    rabbitmq3
```
配置 vim /etc/haproxy/haproxy.cfg
<br>
```
global
    log     127.0.0.1  local0 info
    log     127.0.0.1  local1 notice
    daemon
    maxconn 10000

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    option  redispatch
    retries 3
    option  abortonclose
    maxconn 10000
    timeout connect  5000ms
    timeout client  3000ms
    timeout server  3000ms
    balance roundrobin

#haproxy监听status页面
listen rabbitmq_status
    bind    0.0.0.0:80
    mode    http
    option  httplog
    stats   refresh  5s
    stats   uri  /mq_stats
    stats   realm   Haproxy
    stats   auth  admin:admin

#rabbitmq管理界面
listen rabbitmq_admin
    bind    0.0.0.0:15672
    mode    http
    option  httplog
    balance roundrobin
    server  rabbitmq1 rabbitmq1:15672 check inter 2000 weight 1 rise 2 fall 3
    server  rabbitmq2 rabbitmq2:15672 check inter 2000 weight 1 rise 2 fall 3
    server  rabbitmq3 rabbitmq3:15672 check inter 2000 weight 1 rise 2 fall 3

#rabbitmq集群负载 TCP
listen rabbitmq_cluster
    bind    0.0.0.0:5672
    mode    tcp
    option  tcplog
    balance roundrobin
    server rabbitmq1 rabbitmq1:5672 check inter 2000 weight 1 rise 2 fall 3
    server rabbitmq2 rabbitmq2:5672 check inter 2000 weight 1 rise 2 fall 3
    server rabbitmq3 rabbitmq3:5672 check inter 2000 weight 1 rise 2 fall 3
```
centos下haproxy日志的配置
<br>
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
haproxy 高可用配置(在haproxy 主被机器上安装keepalived)
<br>
```
yum install keepalived -y
systemctl enable keepalived.service 
systemctl restart keepalived.service
systemctl status keepalived.service
 
#### hapoxy 检测脚本
cat>/etc/keepalived/haproxy_check.sh<<EOF 
#!/bin/bash
# /etc/keepalived/haproxy_check.sh
counter=\$(ps -C haproxy --no-heading|wc -l)
if [ "\${counter}" = "0" ]; then
    systemctl start haproxy
    sleep 2
    counter=\$(ps -C haproxy --no-heading|wc -l)
    if [ "\${counter}" = "0" ]; then
        /bin/systemctl stop keepalived.service
    fi
fi
EOF

chmod +x /etc/keepalived/haproxy_check.sh
```
keepalived 主备配置
<br>
```
! Configuration File for keepalived

global_defs {
   router_id haproxy1 #BACKUP 设置为haproxy2
}

vrrp_script chk_haproxy {
    script "/etc/keepalived/haproxy_check.sh"
    interval 2
    weight -30
    fall 3
    rise 2
}

vrrp_instance VI_221 {
    state MASTER  #BACKUP
    interface ens33 #网卡名
    virtual_router_id 51
    unicast_src_ip 10.0.0.101 #本机IP  (BACKUP 对调即可)
    unicast_peer {
        10.0.0.108   #本机IP 对端IP  (BACKUP 对调即可)
    }
    priority 100  #BACKUP 设置为90 
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 4008
    }

    track_script {
        chk_haproxy
    }
 
    virtual_ipaddress {
         10.0.0.250
    }
}
```
