```
global      #全局
    log     127.0.0.1  local0 info    #日志级别
    log     127.0.0.1  local1 notice
    daemon  #以后台形式运行haproxy
    maxconn 4096    #默认最大连接数

defaults    #初始
    log     global
    mode    tcp     #所处理的类别 (7层http    4层tcp)
    option  tabortonclosecplog  #日志类别TCP日志格式,{如果是tcp模式,改为 httplog 即可}
    option  dontlognull #不记录健康检查的日志信息
    retries 3           #3次连接失败就认为服务不可用，也可以通过后面设置
    option   #当服务器负载很高的时候，自动结束掉当前队列处理比较久的连接
    maxconn 4096  #默认最大连接数
    timeout connect  5s #连接超时时间
    timeout client  30s #客户端超时
    timeout server  30s #服务端超时
    balance roundrobin #默认的负载均衡的方式,轮询方式

listen private_monitoring   #定义一个名为 private_monitoring 的部分
    bind    0.0.0.0:8888    #定义监听 本机IP:端口
    mode    http        #定义为http模式
    option  httplog     #http日志格式
    stats   refresh  5s #stats是haproxy的一个统计页面的套接字，该参数设置统计页面的刷新间隔为5s
    stats   uri  /stats #设置统计页面的uri为/stats
    stats   realm  Haproxy Load #设置统计页面认证时的提示内容 : Haproxy Load
    stats   auth  admin:admin #设置统计页面认证的用户和密码，如果要设置多个，另起一行写入即可
    stats hide-version #隐藏统计页面上的haproxy版本信息

listen rabbitmq_admin   #定义一个名为 rabbitmq_admin 的部分
    bind    0.0.0.0:15672
    server  node1 192.168.1.100:15672
    server  node2 192.168.1.200:15672

listen rabbitmq_cluster #定义一个名为 rabbitmq_cluster 的部分
    bind    0.0.0.0:5672
    mode    tcp
    option  tcplog
    balance roundrobin
    timeout client  60s
    timeout server  60s
    server node1 192.168.1.100:5672 check inter 2000 rise 2 fall 3 weight 1
    server node2 192.168.1.200:5672 check inter 2000 rise 2 fall 3 weight 1
# server语法：server [:port] [param*] # 使用server关键字来设置后端服务器；为后端服务器所设置的内部名称[node1]，该名称将会呈现在日志或警报中、后端服务器的IP地址，支持端口映射[10.12.25.68:80]、 接受健康监测[check]、监测的间隔时长，单位毫秒[inter 2000]、监测正常多少次后被认为后端服务器是可用的[rise 2]、监测失败多少次后被认为后端服务器是不可用的[fall 3]、分发的权重[weight 1]
```
