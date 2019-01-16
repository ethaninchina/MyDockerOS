#!/bin/bash
#判断是否为root用户
stty erase '^H'

if [ "$(id -u)" != "0" ]
then
    echo "need root"
    exit
fi


################ start ###################
### 安装 keepalived 主备需要设置此处,否则无需更改
unicast_src_ip="101.186.45.51"
unicast_peer="101.186.45.52"
vip="101.186.45.53"
Master_Backip="MASTER"
################ end ###################


#开始执行...
echo '1) install keepalved
2) install openresty
3) install openresty + keepalved
'
read -t 60 -p "Please input number: "  number
#提示“请输入姓名”并等待30秒，把用户的输入保存入变量name中

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

#判断ulimit是否设置OK
if [ $(ulimit -n) -lt "655350" ];then 
# ulimit 设置
#关闭selinux
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
echo "重新登录确认参数是否生效,否则重启生效"
fi

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
    error_log  /data/logs/error.log debug;

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

mkdir /usr/local/openresty/nginx/conf/vhost/

systemctl enable openresty
systemctl start openresty
systemctl status openresty
}


function keepalived() {
yum install keepalived -y
cat > /etc/keepalived/nginx_check.sh<<EOF
#!/bin/bash
counter=$(ps -C nginx --no-heading|wc -l)
if [ "${counter}" = "0" ]; then
    /bin/systemctl start openresty.service
    #/usr/local/openresty/nginx/sbin/nginx
    sleep 2
    counter=$(ps -C nginx --no-heading|wc -l)
    if [ "${counter}" = "0" ]; then
        /bin/systemctl stop keepalived.service
    fi
fi
EOF

chmod +x /etc/keepalived/nginx_check.sh

# set IP/interface/MASTER/BACKUP
# unicast_src_ip="10.186.45.51"
# unicast_peer="10.186.45.52"
# vip="10.186.45.53"
# Master_Backip="MASTER"
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
    priority 100
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
