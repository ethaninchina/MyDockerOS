#!/bin/bash
#判断是否为root用户
stty erase '^H'

if [ "$(id -u)" != "0" ]
then
    echo "need root"
    exit
fi


################ keepalived set ###################
### 安装 keepalived 主备需要设置此处,否则无需更改
#本机IP地址
unicast_src_ip="101.186.45.51"
#对端IP地址
unicast_peer="101.186.45.52"
#VIP地址
vip="101.186.45.53"
#角色
Master_Backip="MASTER"
#优先级(MASTER: 100 , BACKUP: 90)
priority="100"
################ keepalived end ###################


#开始执行...
echo '1) install keepalved
2) install openresty
3) install openresty + keepalved
'
read -t 60 -p "Please input number: "  number
#提示“请输入姓名”并等待60秒，把用户的输入保存入变量number中

if [ $number == "1" ];then
    echo "开始执行 installing keepalved"
elif [ $number == "2" ];then
    echo "开始执行 installing openresty"

elif [ $number == "3" ];then
     echo "开始执行 installing openresty + keepalved"
else 
    echo "输入错误,请重新执行脚本"
    exit
fi

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

#set history show time
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

#判断ulimit是否设置OK [max user processes 的值如果小于 100000 重新设置参数]
limitnum=$(ulimit -a|grep 'max user processes'|awk '{print $NF}')
if [ ${limitnum} -lt "100000" ];then 

#关闭selinux
setenforce 0
sed -i "s/^SELINUX\=enforcing/SELINUX\=disabled/g" /etc/selinux/config

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
echo "重新登录确认ulimit参数是否生效,否则重启生效...."
fi

#内核优化 sysctl.conf
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
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
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
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
#默认128，最大限制65535，用于设置系统同时发起的TCP连接数，数值较小时，无法应付高并发情形，导致连接超时、重传等问题
net.core.somaxconn = 65535
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

    log_format  json  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"'
                      'host: "\$server_addr" '
                      'domain: "\$http_host" '
                      '"\$server_protocol" '
                      'uri: "\$request_uri" ' 
                      'method: \$request_method '
                      'status: "\$status" '
                      'upstatus:"\$upstream_status" '
		      'post_data: "\$request_body" '
                      'upaddr: "\$upstream_addr" '
                      'request_time: "\$request_time" '
                      'upstream_response_time: "\$upstream_response_time" ';

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

# mkdir vhost 
mkdir /usr/local/openresty/nginx/conf/vhost/

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


function keepalived() {
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

vrrp_instance VI_50 {
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


case "$number" in
	1)
		keepalived
		;;
	2)
		openresty
		;;
	3)
        	keepalived
		openresty
		;;
esac
