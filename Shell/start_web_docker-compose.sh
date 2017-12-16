#!/usr/bin/bash
if [ "$(id -u)"  -ne "0" ];then
echo "非root用户无权限执行"
exit
fi

#全局参数 
# ****** 自定义参数 start ******
#mysql变量
mysql_pass=123456
#shadowsocks变量
ss_ip=$(ifconfig eth0|grep inet|awk '{print $2}')
ss_port=7879
ss_pass=Wn#98gsf#
# ****** 自定义参数 end ******

#关闭selinux
sed -i s/=enforcing/=disabled/g /etc/selinux/config
setenforce 0

#内核优化
cat>/etc/sysctl.conf<<EOF
#CTCDN系统优化参数

#系统所有进程一共可以打开的文件数量 
fs.file-max = 10240000

#关闭ipv6
#net.ipv6.conf.all.disable_ipv6 = 1
#net.ipv6.conf.default.disable_ipv6 = 1

# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1

#开启路由转发
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects = 1
net.ipv4.conf.default.send_redirects = 1

#开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

#处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

#关闭sysrq功能
kernel.sysrq = 0

#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1

# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1

#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536

#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

#timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096  87380   4194304
net.ipv4.tcp_wmem = 4096  16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144

#限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800

#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0

#内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1

#内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1

#启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1

#开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1

#当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 30

#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024    65000
EOF

#内核修改即时生效
sysctl -p

#配置ulimit
echo -e "
* soft nofile 102400
* hard nofile 102400
" >>/etc/security/limits.conf

echo "ulimit -SHn 102400" >>/etc/profile

#安装docker
yum install epel-release -y
yum update -y
yum install docker -y
systemctl enable docker.service
systemctl start docker.service

#拉取docker项目
docker pull registry.cn-hangzhou.aliyuncs.com/webss/lrnp
docker pull registry.cn-hangzhou.aliyuncs.com/webss/mysql:5.7
docker pull docker.io/vimagick/shadowsocks-libev

#安装docker-compose编排服务
curl -L https://github.com/docker/compose/releases/download/1.18.0-rc2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

#配置docker-compose.yml 文件
cat>/root/docker-compose.yml<<EOF
version: '2'
    #定义服务lrnp(openresty1.13+redis3.2.9+php7.1.12) 和 mysql(mysql5.7)
services:
        #服务名称
        lrnp:
            #依赖mysql服务，意味着在启动lrnp之前先启动mysql服务容器
            depends_on:
                - mysql
            #nginx镜像的路径
            #image: docker.io/wuyuzai/mydockeros:lrnp
            #aliyun镜像地址
            image: registry.cn-hangzhou.aliyuncs.com/webss/lrnp
            #映射文件/文件夹到宿主机，持久化和方便管理
            volumes:
                - /root/web:/opt/openresty/nginx/html
                - /root/logs/nginx_log:/opt/openresty/nginx/logs
                - /root/logs/php_log:/tmp/phplogs
                - /root/php/php.ini:/etc/php/php.ini
                - /root/php/www.conf:/usr/local/php/etc/php-fpm.d/www.conf
                - /root/nginx-conf:/opt/openresty/nginx/conf
            #openresty服务意外退出时自动重启
            restart: always
            #网络模式HOST(使用宿主机网络)
            network_mode: host
            #容器名称(hostname)
            container_name: lrnp7   
        #服务名称
        mysql:
            #image: docker.io/mysql:5.7
            #阿里云镜像地址
            image: registry.cn-hangzhou.aliyuncs.com/webss/mysql:5.7
            #设置MYSQL_ROOT_PASSWORD环境变量，这里是设置mysql的root密码。
            environment:
                MYSQL_ROOT_PASSWORD: $mysql_pass
            #映射文件路径
            volumes:
                - /root/mysqld/config:/etc/mysql
                - /root/mysqld/mysqldata:/var/lib/mysql
                - /root/logs/mysql_log:/var/log/mysql
            restart: always
            #容器名称(hostname)
            container_name: mysql57
        #docker服务
        shadowsocks:
            image: docker.io/vimagick/shadowsocks-libev
            #网络模式HOST(使用宿主机网络)
            network_mode: host
            environment:
                SERVER_ADDR: $ss_ip
                PASSWORD: $ss_pass
                SERVER_PORT: $ss_port
            restart: always
            #容器名称(hostname)
            container_name: shadowsocks
EOF

#添加开机启动docker服务
echo "cd /root/ && docker-compose up -d" >> /etc/rc.local

#关闭系统自带防火墙 firewall
systemctl stop firewalld.service
#禁止firewall开机自启
systemctl mask firewalld
#禁止firewall开机自启
sytsemctl disable firewalld.service

#安装IPtable是
yum install -y iptables
yum update iptables -y
yum install iptables-services -y

#设置iptables配置
cat>/etc/sysconfig/iptables<<EOF
# sample configuration for iptables service
# you can edit this manually or use system-config-firewall
# please do not ask us to add additional ports/services to this default configuration
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [12135:65324]
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
#-A INPUT -s 192.168.0.19/32 -p tcp --dport 22 -j ACCEPT
#-A INPUT -s 192.168.0.19/32 -p tcp --dport 3306 -j ACCEPT
#-A INPUT -p tcp -m multiport --dport 20441,20443,20445,51443 -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport $ss_port -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF

#首次启动docker-compose
cd /root/ && docker-compose up -d
docker-compose ps

#开机启动iptables
systemctl enable iptables.service
#开启iptables服务
systemctl start iptables.service
#查看iptables配置端口
iptables -L -n

#增加权限防止误删docker-compose.yml文件
chattr +i /root/docker-compose.yml

#结束语
echo -e "
   ***  安装完成 ***
 "
