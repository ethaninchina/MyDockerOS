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

[root@node1 ~]# [rabbitmq-erlang]
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
mkdir -p ~/download && cd ~/download
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
<br>
<br>
```
########## haproxy 负载 
#全局配置
global
        #日志输出配置，所有日志都记录在本机，通过local0输出
        log 127.0.0.1 local0 info
        #最大连接数
        maxconn 4096
        #改变当前的工作目录
        chroot /apps/svr/haproxy
        #以指定的UID运行haproxy进程
        uid 99
        #以指定的GID运行haproxy进程
        gid 99
        #以守护进程方式运行haproxy #debug #quiet
        daemon
        #debug
        #当前进程pid文件
        pidfile /apps/svr/haproxy/haproxy.pid

#默认配置
defaults
        #应用全局的日志配置
        log global
        #默认的模式mode{tcp|http|health}
        #tcp是4层，http是7层，health只返回OK
        mode tcp
        #日志类别tcplog
        option tcplog
        #不记录健康检查日志信息
        option dontlognull
        #3次失败则认为服务不可用
        retries 3
        #每个进程可用的最大连接数
        maxconn 2000
        #连接超时
        timeout connect 5s
        #客户端超时
        timeout client 120s
        #服务端超时
        timeout server 120s

        maxconn 2000
        #连接超时
        timeout connect 5s
        #客户端超时
        timeout client 120s
        #服务端超时
        timeout server 120s

#绑定配置
listen rabbitmq_cluster
        bind 0.0.0.0:5672
        #配置TCP模式
        mode tcp
        #加权轮询
        balance roundrobin
        #RabbitMQ集群节点配置,其中ip1~ip7为RabbitMQ集群节点ip地址
        server  node1  node1:5672 check inter 5000 rise 2 fall 3 weight 1
        server  node2  node2:5672 check inter 5000 rise 2 fall 3 weight 1
        server  node3  node3:5672 check inter 5000 rise 2 fall 3 weight 1

#haproxy监控页面地址
listen monitor
        bind 0.0.0.0:8100
        mode http
        option httplog
        stats enable
        stats uri /stats
        stats refresh 5s
```
