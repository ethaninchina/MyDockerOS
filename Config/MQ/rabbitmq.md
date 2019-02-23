node1,node2,node3上执行
<br>
```
[root@node1 ~] cat /etc/hosts
10.124.5.171    node1
10.124.5.172    node2
10.124.5.173    node3
```
安装 Erlang（RabbitMQ 运行需要 Erlang 环境）：
<br>
```
[root@node1 ~]# vi /etc/yum.repos.d/rabbitmq-erlang.repo
[rabbitmq-erlang]
name=rabbitmq-erlang
baseurl=https://dl.bintray.com/rabbitmq/rpm/erlang/20/el/7
gpgcheck=1
gpgkey=https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc
repo_gpgcheck=0
enabled=1

[root@node1 ~]# yum -y install erlang socat
```
安装 RabbitMQ Server：
<br>
```
[root@node1 ~]# mkdir -p ~/download && cd ~/download
[root@node1 download]# wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.10/rabbitmq-server-3.6.10-1.el7.noarch.rpm
[root@node1 download]# rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
[root@node1 download]# rpm -Uvh rabbitmq-server-3.6.10-1.el7.noarch.rpm
```
安装好之后，就可以启动 RabbitMQ Server 了：
<br>
```
[root@node1 download]# systemctl start rabbitmq-server
systemctl enable rabbitmq-server
systemctl status rabbitmq-server
```
启动 RabbitMQ Web 管理控制台
<br>
```
[root@node1 download]# rabbitmq-plugins enable rabbitmq_management
The following plugins have been enabled:
  amqp_client
  cowlib
  cowboy
  rabbitmq_web_dispatch
  rabbitmq_management_agent
  rabbitmq_management
```
RabbitMQ Server 默认guest用户，只能localhost地址访问，我们还需要创建管理用户：
<br>
```
[root@node1 download]# rabbitmqctl add_user admin admin123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```
然后添加防火墙运行访问的端口：
<br>
```
[root@node1 download]# firewall-cmd --zone=public --permanent --add-port=4369/tcp
firewall-cmd --zone=public --permanent --add-port=25672/tcp
firewall-cmd --zone=public --permanent --add-port=5671-5672/tcp
firewall-cmd --zone=public --permanent --add-port=15672/tcp
firewall-cmd --zone=public --permanent --add-port=61613-61614/tcp
firewall-cmd --zone=public --permanent --add-port=1883/tcp 
firewall-cmd --zone=public --permanent --add-port=8883/tcp

重新启动防火墙：
[root@node1 download]# firewall-cmd --reload
````
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
[root@node1 ~]# rpm -e rabbitmq-server-3.6.10-1.el7.noarch
[root@node1 ~]# rm -rf /var/lib/rabbitmq/     //清除rabbitmq配置文件
```
RabbitMQ Server 高可用集群,将上面的搭建过程，在node2 和 node3 服务器上，再做重复一边。
<br>
```
以node1作为集群中心，在node2上执行加入集群中心命令（节点类型为磁盘节点）：
[root@node1 ~]# cat /var/lib/rabbitmq/.erlang.cookie
LBOTELUJAMXDMIXNTZMB

将node1服务器中的.erlang.cookie文件，拷贝到node2/node3服务器上：
[root@node1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@node2:/var/lib/rabbitmq
[root@node1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@node3:/var/lib/rabbitmq
```
在node2上
<br>
```
[root@node2 ~]# rabbitmqctl stop_app
[root@node2 ~]# rabbitmqctl reset 
[root@node2 ~]# rabbitmqctl join_cluster rabbit@node1
//默认是磁盘节点，如果是内存节点的话，需要加--ram参数
[root@node2 ~]# rabbitmqctl start_app
```
在node3上
<br>
```
[root@node3 ~]# rabbitmqctl stop_app
[root@node3 ~]# rabbitmqctl reset 
[root@node3 ~]# rabbitmqctl join_cluster rabbit@node1
//默认是磁盘节点，如果是内存节点的话，需要加--ram参数
[root@node3 ~]# rabbitmqctl start_app
```
查看集群状态，我们可以在任意一台机器上查看，我们选择在node1上看。
<br>
```
[root@node1 ~]# rabbitmqctl cluster_status

试一下容错,关掉node3上的实例
[root@node3 ~]# rabbitmqctl stop
```
haproxy 负载 安装
```
yum install haproxy -y
systemctl enable haproxy
systemctl start haproxy
systemctl status haproxy
```
配置 vim /etc/haproxy/haproxy.cfg
<br>
```
global
    log     127.0.0.1  local0 info
    log     127.0.0.1  local1 notice
    daemon
    maxconn 4096

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    retries 3
    option  abortonclose
    maxconn 4096
    timeout connect  5000ms
    timeout client  3000ms
    timeout server  3000ms
    balance roundrobin

#haproxy监听status页面
listen rabbitmq_status
    bind    0.0.0.0:8100
    mode    http
    option  httplog
    stats   refresh  5s
    stats   uri  /stats
    stats   realm   Haproxy
    stats   auth  admin:admin

#rabbitmq管理界面
listen rabbitmq_admin
    bind    0.0.0.0:8102
    server  node1 node1:15672
    server  node2 node2:15672
    server  node3 node2:15672

#rabbitmq集群负载
listen rabbitmq_cluster
    bind    0.0.0.0:8101
    mode    tcp
    option  tcplog
    balance roundrobin
    server node1 node1:5672 check inter 2000 weight 1 rise 2 fall 3
    server node2 node2:5672 check inter 2000 weight 1 rise 2 fall 3
    server node3 node2:5672 check inter 2000 weight 1 rise 2 fall 3
```
