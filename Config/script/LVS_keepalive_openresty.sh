#!/bin/bash
# 1)安装 Openresty
# 2)安装 keepalived + Openresty
# 3)安装 keepalived + LVS

#过滤交互时输入出现 ^H
stty erase '^H'

#判断是否为root用户
if [ "$(id -u)" != "0" ]
then
    echo "need root"
    exit
fi


#################### keepalived+openresty set ####################
### 如果需要安装 keepalived 主备,则需要设置此处,否则无需更改
#本机IP地址
unicast_src_ip="10.0.0.113"
#对端IP地址(主备的另一台机器IP地址)
unicast_peer="10.0.0.109"
#VIP地址
vip="10.0.0.222"
#角色 (MASTER/BACKUP)
Master_Backip="MASTER"
#优先级(MASTER: 100 , BACKUP: 90)
priority="100"
############ keepalived+LVS set ### 不安装LVS则不需要配置以下项####
#vip port 和 realserver port, realserver ip
vs_port="80"
rs1="101.186.45.60"
rs2="101.186.45.61"
#################### keepalived end #############################


#echo -e "\033[41;37m 红底白字 \033[0m"
#开始执行...
echo '1) install Openresty
2) install keepalved + Openresty
3) install keepalved + LVS
'
read -t 60 -p "Please input number: "  number
#提示“请输入姓名”并等待60秒，把用户的输入保存入变量number中

if [ $number == "1" ];then
    echo -e "\033[41;37m 开始执行 installing Openresty \033[0m"
elif [ $number == "2" ];then
    echo -e "\033[41;37m 开始执行 installing keepalved + Openresty \033[0m"

elif [ $number == "3" ];then
     echo -e "\033[41;37m 开始执行 installing keepalved + LVS \033[0m"
else 
    echo -e "\033[41;37m 输入错误,请重新执行脚本 \033[0m"
    exit 1
fi

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# set history show time
echo '
HISTFILESIZE=4000
HISTSIZE=4000
HISTTIMEFORMAT="%F %T "
export HISTTIMEFORMAT
'>>/etc/bashrc
. /etc/bashrc

#set ntpdate
yum install ntpdate -y
ntpdate ntp1.aliyun.com
clock -w
echo "0 0 * * * ntpdate ntp1.aliyun.com" >> /var/spool/cron/root


#关闭selinux
setenforce 0
sed -i "s/^SELINUX\=enforcing/SELINUX\=disabled/g" /etc/selinux/config


#判断ulimit是否设置OK [max user processes 的值如果小于 100000 重新设置参数]
limitnum=$(ulimit -a|grep 'max user processes'|awk '{print $NF}')
if [ ${limitnum} -lt "100000" ];then 

#set ulimit
cat>/etc/security/limits.conf<<EOF
* soft nofile 100001
* hard nofile 100002
root soft nofile 100001
root hard nofile 100002
EOF

cat>/etc/security/limits.d/20-nproc.conf<<EOF
*          soft    nproc     100001
root       soft    nproc     unlimited 
EOF

sed -i '/^#DefaultLimitNOFILE=/aDefaultLimitNOFILE=100001' /etc/systemd/system.conf 
sed -i '/^#DefaultLimitNPROC=/aDefaultLimitNPROC=100001' /etc/systemd/system.conf 

echo -e "\033[41;37m 重新登录确认ulimit参数是否生效,否则重启生效.... \033[0m"
sleep 5

fi

#内核优化 sysctl.conf
cp -fr /etc/sysctl.conf /etc/sysctl.conf.old
#curl -o /etc/sysctl.conf "https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctem/sysctl.conf"
cat>/etc/sysctl.conf<<EOF
#############系统优化参数#############
#系统所有进程一共可以打开的文件数量 
fs.file-max = 100001
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
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
#开启sysrq功能
kernel.sysrq = 1
#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
#是否开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 0
#默认128，最大限制65535，用于设置系统同时发起的TCP连接数，数值较小时，无法应付高并发情形，导致连接超时、重传等问题
net.core.somaxconn = 65535
#修改消息队列长度
kernel.msgmnb = 65535
kernel.msgmax = 65535
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
net.ipv4.tcp_tw_recycle = 0
#开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 60
#当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 1800
#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024    65000
EOF
sysctl -p

#openresty 安装
function openresty() {
useradd -s /sbin/nologin nginx

# install openresty
yum install yum-utils -y
yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
yum install wget pcre-devel gcc openssl-deve curl -y
yum install openresty -y

# set openresty(nginx)
cp /usr/local/openresty/nginx/conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf.old 

mkdir -p /data/logs/

cat>/usr/local/openresty/nginx/conf/nginx.conf<<EOF
user  nginx;
worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;
pid        logs/nginx.pid;
events {
    use epoll;
    worker_connections  100000;
    multi_accept on;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
log_format json '{"@timestamp":"\$time_iso8601",'
                 '"host":"\$server_addr",'
                 '"clientip":"\$remote_addr",'
                 '"size":"\$body_bytes_sent",'
                 '"responsetime":"\$request_time",'
                 '"upstreamtime":"\$upstream_response_time",'
                 '"upstreamhost":"\$upstream_addr",'
                 '"domain":"\$http_host",'
                 '"method": "\$request_method",'
                 '"url":"\$uri",'
		         '"query_string":"\$query_string",'
                 '"xff":"\$http_x_forwarded_for",'
                 '"referer":"\$http_referer",'
                 '"agent":"\$http_user_agent",'
                 '"status":"\$status",'
                 '"ups_status":"\$upstream_status"}';
    access_log  /data/logs/access.log  json;
    error_log  /data/logs/error.log;
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay 	on;
    keepalive_timeout  65; #保持长连接的时间 默认65
    keepalive_requests 1000; #每个连接最大请求数 默认100
    server_tokens off; #关闭版本提示
    client_header_timeout 60s; #客户端向服务端发送一个完整的 request header 的超时时间,默认60s
    client_body_timeout 120s; #客户端与服务端建立连接后发送 request body 的超时时间。如果客户端在指定时间内没有发送任何内容，Nginx 返回 HTTP 408（Request Timed Out）,默认60s
    proxy_connect_timeout 300s; #后端服务器连接的超时时间_发起握手等候响应超时时间,默认60s
    proxy_read_timeout 300s; #连接成功后_等候后端服务器响应时间(后端服务器处理请求的时间),默认60s
    proxy_send_timeout 300s; #后端服务器数据回传时间_就是在规定时间之内后端服务器必须传完所有的数据,默认60s
    #send_timeout 60s; #nginx传输到客户端的超时时间,默认60s,正常情况下 毫秒内传完了
    proxy_buffer_size 64k; #是设置缓存冲的大小。
    proxy_buffers 4 128k; #设置缓冲区的数量和大小
    proxy_busy_buffers_size 256k;
    client_max_body_size 10m; #客户端最大的 request body 大小
    client_body_buffer_size 1024k; #客户端 request body 缓冲区大小
include /usr/local/openresty/nginx/conf/vhost/*.conf;
}
EOF

#set vhost/?.conf
mkdir /usr/local/openresty/nginx/conf/vhost/

cat>/usr/local/openresty/nginx/conf/vhost/test.conf<<EOF
upstream A {
   server 10.0.0.1:80 weight=1 max_fails=3 fail_timeout=10s;
   server 10.0.0.2:80 weight=1 max_fails=3 fail_timeout=10s;
   server 10.0.0.3:80 weight=1 max_fails=3 fail_timeout=10s;
   #keepalive 300;
    }
    server {
            listen   80;
            server_name  localhost;
            #root   html;
            access_log  /data/logs/access.log  json;
            error_log  /data/logs/error.log;
            location / {
                proxy_pass http://A;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
                proxy_ignore_client_abort on; #499忽略
                proxy_http_version 1.1;
                proxy_set_header Connection "";
                            }
    }
EOF

#set nginx_status.conf
cat>/usr/local/openresty/nginx/conf/vhost/nginx_status.conf<<EOF
server {
    listen 8099;
     
  location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
	}
}
EOF

systemctl enable openresty
systemctl start openresty
systemctl status openresty
}

#keepalived 安装
function ng_keepalived() {
yum install keepalived -y

cat > /etc/keepalived/nginx_check.sh<<EOF
#!/bin/bash
counter=\$(ps -C nginx --no-heading|wc -l)
if [ "\${counter}" = "0" ]; then
    /bin/systemctl start openresty.service
    #/usr/local/openresty/nginx/sbin/nginx
    sleep 2
    counter=\$(ps -C nginx --no-heading|wc -l)
    if [ "\${counter}" = "0" ]; then
        /bin/systemctl stop keepalived.service
    fi
fi
EOF

chmod +x /etc/keepalived/nginx_check.sh
interface=$(ifconfig|awk '{print $1}'|sed -n 1p|cut -d : -f 1)
hostname=$(hostname)

# set keepalived.conf
cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
   router_id $hostname
}
vrrp_script chk_nginx {
    script "/etc/keepalived/nginx_check.sh"
    interval 2
    weight -20
    fall 3
    rise 2
}
vrrp_instance VI_53 {
    state $Master_Backip
    interface $interface
    virtual_router_id 30
    unicast_src_ip $unicast_src_ip
    unicast_peer {
        $unicast_peer
    }
    priority $priority
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 40086
    }
    track_script {
        chk_nginx
    }
    virtual_ipaddress {
         $vip
    }
}
EOF

systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived
}

#keepalived + LVS set
function LVS_keepalived() {
yum install ipvsadm -y
yum install keepalived -y
cp /etc/sysctl.conf /etc/sysctl.conf.old 
curl -o /etc/sysctl.conf "https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctem/lvs_sysctl.conf"
sysctl -p

interface=$(ifconfig|awk '{print $1}'|sed -n 1p|cut -d : -f 1)
hostname=$(hostname)

cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived 
global_defs { 
    router_id $hostname 
} 
virrp_sync_group Prox { 
    group { 
        LVSCluster 
    } 
} 
vrrp_instance LVSCluster { 
    state $Master_Backip 
    interface $interface 
    lvs_sync_daemon_interface $interface 
    unicast_src_ip $unicast_src_ip
    unicast_peer {
        $unicast_peer  #对端设备(如backup服务器)的 IP 地址
    }
    virtual_router_id 50 
    priority $priority 
    advert_int 1 
    authentication { 
        auth_type PASS 
        auth_pass 4008 
   } 
    virtual_ipaddress { 
    	$vip
    } 
} 
virtual_server  $vip $vs_port { 
    delay_loop 3 #健康检查时间间隔 
    lb_algo wrr  #算法
    lb_kind DR  #转发规则
    #persistence_timeout 60 #保持长连接,连接保持，意思就是在这个一定时间内会讲来自同一用户（根据ip来判断的）访问到同一个real server。
    protocol TCP 
    nat_mask 255.255.255.0
    real_server $rs1 $vs_port { 
        weight 10　 
	      inhibit_on_failure 
        TCP_CHECK { 
            connect_timeout 1 
            nb_get_retry 2 
            delay_before_retry 1 
            connect_port $vs_port 
        } 
    } 
    real_server $rs2 $vs_port {  #指定real server的真实IP地址和端口
        weight 10
	      inhibit_on_failure  # 若此节点故障，则将权重设为零（默认是从列表中移除）
        TCP_CHECK { 
            connect_timeout 1  #超时时间
            nb_get_retry 2 #重试次数
            delay_before_retry 1 #重试间隔 
            connect_port $vs_port #监测端口
        } 
    } 
}
EOF

systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived
}


# 1)安装 Openresty
# 2)安装 keepalived + Openresty
# 3)安装 keepalived + LVS

case "$number" in
	1)
		openresty
		;;
	2)
        openresty
		ng_keepalived
		;;
	3)
        LVS_keepalived

        echo -e "\033[41;37m
        LVS_keepalived安装成功后,请在 realserver机器,按照顺序1-6依次执行/修改 ...

        1) curl -o /etc/init.d/lvs https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/LVS/lvs.sh 
        2) chmod +x /etc/init.d/lvs
        3) chkconfig lvs on
        4) chkconfig --list |grep lvs
        5) 修改 脚本内的 SNS_VIP 地址 
        6) 启动脚本: service lvs start \033[0m"

        ipvsadm -L -n
		;;
esac