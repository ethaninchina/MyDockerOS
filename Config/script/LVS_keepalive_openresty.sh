#!/bin/bash
# 1)安装 Openresty
# 2)安装 keepalived + Openresty
# 3)安装 keepalived + LVS
#过滤交互时输入出现 ^H
stty erase '^H'


#################### keepalived+openresty 只设置这里 ####################
# 如果需要安装 keepalived 主备,则需要设置此处,否则无需更改
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
############ keepalived+LVS 设置上面和这里 ### 不安装LVS则不需要配置以下项####
#设置 vip port 和 realserver port 相同, 设置 realserver ip 
vs_port="80"
rs1="101.186.45.60"
rs2="101.186.45.61"
#################### keepalived end #############################

#判断是否为root用户
if [ "$(id -u)" != "0" ]
then
    echo "need root"
    exit
fi

#开始执行...
echo '1) install Openresty
2) install keepalved + Openresty
3) install keepalved + LVS
'
read -t 60 -p "Please input number: "  number
#提示“请输入姓名”并等待60秒，把用户的输入保存入变量number中

if [ $number == "1" ];then
    echo -e "\033[41;37m 开始执行 installing Openresty \033[0m"
    sleep 3
elif [ $number == "2" ];then
    echo -e "\033[41;37m 开始执行 installing keepalved + Openresty \033[0m"
    sleep 3
elif [ $number == "3" ];then
     echo -e "\033[41;37m 开始执行 installing keepalved + LVS \033[0m"
     sleep 3
else 
    echo -e "\033[41;37m 输入错误,请重新执行脚本 \033[0m"
    exit 1
fi

function sytem() {
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

ulimit -a
echo -e "\033[41;37m 重新确认ulimit参数是否生效,否则重启生效.... \033[0m"
sleep 5
fi
}

#openresty 安装
function openresty() {
#内核优化 sysctl.conf
cp -fr /etc/sysctl.conf /etc/sysctl.conf.old
curl -o /etc/sysctl.conf "https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctem/sysctl.conf"
sysctl -p

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

#keepalived(nginx)安装
function ng_keepalived() {
#内核优化 sysctl.conf
cp -fr /etc/sysctl.conf /etc/sysctl.conf.old
curl -o /etc/sysctl.conf "https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctem/sysctl.conf"
sysctl -p

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

#keepalived(LVS)安装
function LVS_keepalived() {
cp /etc/sysctl.conf /etc/sysctl.conf.old 
curl -o /etc/sysctl.conf "https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctem/lvs_sysctl.conf"
sysctl -p

yum install ipvsadm -y
yum install keepalived -y

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
sleep 5
ipvsadm -L -n
}


function echo_realserver {
        echo -e "\033[41;37m
        LVS_keepalived安装成功后,请在 realserver机器,按照顺序1-6依次执行/修改 ...

        1) curl -o /etc/init.d/lvs https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/LVS/lvs.sh 
        2) chmod +x /etc/init.d/lvs
        3) chkconfig lvs on
        4) chkconfig --list |grep lvs
        5) 修改 脚本内的 SNS_VIP 地址 
        6) 启动脚本: service lvs start \033[0m"
}

# 1)安装 Openresty
# 2)安装 keepalived + Openresty
# 3)安装 keepalived + LVS

case "$number" in
	1)
	sytem #设置系统参数
	openresty #安装openresty
	;;
	2)
	sytem #设置系统参数
        openresty #安装openresty
	ng_keepalived #安装ng检测脚本+keepalived 
	;;
	3)
	sytem #设置系统参数
        LVS_keepalived #安装LVS+keepalived
	echo_realserver #输出realserver设置信息
	;;
esac
