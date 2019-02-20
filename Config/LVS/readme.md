LVS(DR)+keepalived
```
VIP: 
10.0.0.200
10.0.0.201

lvs+keepalived:
10.0.0.101
10.0.0.108

realserver:
10.0.0.110
10.0.0.111
```
##### 安装ipvsadm
```
yum install ipvsadm -y
cp /etc/sysctl.conf /etc/sysctl.conf.old 
curl -o /etc/sysctl.conf "https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctem/lvs_sysctl.conf"
sysctl -p
```


1, keepalived master 设置
```
! Configuration File for keepalived 
global_defs { 
    router_id lvs_clu_1 
} 
virrp_sync_group Prox { 
    group { 
        NginxCluster 
    } 
} 
vrrp_instance NginxCluster { 
    state MASTER 
    interface ens33 
    lvs_sync_daemon_interface ens33 
    unicast_src_ip 10.0.0.101
    unicast_peer {
        10.0.0.108  #对端设备(backup服务器)的 IP 地址，例如：172.168.10.222 
    }
    virtual_router_id 50 
    priority 100 
    advert_int 1 
    authentication { 
        auth_type PASS 
        auth_pass 4008 
   } 
    virtual_ipaddress { 
    	10.0.0.200
	10.0.0.201
    } 
} 
virtual_server  10.0.0.200 80 { 
    delay_loop 3 #健康检查时间间隔 
    lb_algo wrr  #算法
    lb_kind DR  #转发规则
    #persistence_timeout 60 #保持长连接,连接保持，意思就是在这个一定时间内会讲来自同一用户（根据ip来判断的）访问到同一个real server。
    protocol TCP 
    nat_mask 255.255.255.0
    real_server 10.0.0.110 80 { 
        weight 10　 
	      inhibit_on_failure 
        TCP_CHECK { 
            connect_timeout 1 
            nb_get_retry 2 
            delay_before_retry 1 
            connect_port 80 
        } 
    } 
    real_server 10.0.0.111 80 {  #指定real server的真实IP地址和端口
        weight 10
	      inhibit_on_failure  # 若此节点故障，则将权重设为零（默认是从列表中移除）
        TCP_CHECK { 
            connect_timeout 1  #超时时间
            nb_get_retry 2 #重试次数
            delay_before_retry 1 #重试间隔 
            connect_port 80 #监测端口
        } 
    } 
}
#设置虚拟ip 10.0.0.201
virtual_server  10.0.0.201 80 {
    delay_loop 3 #健康检查时间间隔
    lb_algo wrr  #算法
    lb_kind DR  #转发规则
    #persistence_timeout 60
    protocol TCP 
    nat_mask 255.255.255.0
    real_server 10.0.0.110 80 {
        weight 10　 
        inhibit_on_failure
        TCP_CHECK { 
            connect_timeout 1
            nb_get_retry 2  
            delay_before_retry 1
            connect_port 80 
        }   
    }   
    real_server 10.0.0.111 80 {  #指定real server的真实IP地址和端口
        weight 10
        inhibit_on_failure
        TCP_CHECK { 
            connect_timeout 1  #超时时间
            nb_get_retry 2 #重试次数
            delay_before_retry 1 #重试间隔
            connect_port 80 #监测端口 
        }   
    }   
} 
```
2, keepalived backup 设置
```
! Configuration File for keepalived 
global_defs { 
    router_id lvs_clu_2 
} 
virrp_sync_group Prox { 
    group { 
        NginxCluster 
    } 
} 
vrrp_instance NginxCluster { 
    state BACKUP 
    interface ens33 
    lvs_sync_daemon_interface ens33 
    unicast_src_ip 10.0.0.108
    unicast_peer {
        10.0.0.101  #对端设备(backup服务器)的 IP 地址，例如：172.168.10.222    
    }
    virtual_router_id 50 
    priority 80 
    advert_int 1 
    authentication { 
        auth_type PASS 
        auth_pass 4008 
} 
    virtual_ipaddress { 
        10.0.0.200
	10.0.0.201
    } 
} 
virtual_server  10.0.0.200 80 { 
    delay_loop 3 #健康检查时间间隔 
    lb_algo wrr  #算法
    lb_kind DR  #转发规则
    #persistence_timeout 60 #连接保持，意思就是在这个一定时间内会讲来自同一用户（根据ip来判断的）访问到同一个real server。
    protocol TCP 
    nat_mask 255.255.255.0
    real_server 10.0.0.110 80 { 
        weight 10
        inhibit_on_failure
        TCP_CHECK { 
            connect_timeout 1 
            nb_get_retry 2 
            delay_before_retry 1
            connect_port 80 
        } 
    } 
    real_server 10.0.0.111 80 {  #指定real server的真实IP地址和端口
        weight 10
        inhibit_on_failure  # 若此节点故障，则将权重设为零（默认是从列表中移除）
        TCP_CHECK { 
            connect_timeout 1  #超时时间
            nb_get_retry 2 #重试次数
            delay_before_retry 1 #重试间隔 
            connect_port 80 #监测端口
        } 
    } 
}
#设置虚拟ip 10.0.0.201
virtual_server  10.0.0.201 80 {
    delay_loop 3 #健康检查时间间隔
    lb_algo wrr  #算法
    lb_kind DR  #转发规则
    #persistence_timeout 60
    protocol TCP 
    nat_mask 255.255.255.0
    real_server 10.0.0.110 80 {
        weight 10　 
        inhibit_on_failure
        TCP_CHECK { 
            connect_timeout 1
            nb_get_retry 2  
            delay_before_retry 1
            connect_port 80 
        }   
    }   
    real_server 10.0.0.111 80 {  #指定real server的真实IP地址和端口
        weight 10
        inhibit_on_failure
        TCP_CHECK { 
            connect_timeout 1  #超时时间
            nb_get_retry 2 #重试次数
            delay_before_retry 1 #重试间隔
            connect_port 80 #监测端口 
        }   
    }   
} 
```
3,启动keepalived
```
systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived
```


#### ###### realserver 设置 ######
4, realserver 设置vip绑定脚本
vim /etc/init.d/lvs
```
#!/bin/sh
### BEGIN INIT INFO
# Provides: lvs_realserver
# Default-Start:  3 4 5
# Default-Stop: 0 1 6
# Short-Description: LVS real_server service scripts
# Description: LVS real_server start and stop controller
### END INIT INFO
#  Copyright 2019 ooxx
#
#  chkconfig: - 20 80
#
#  Author:  xxxx@xxxx

#有多个虚拟IP，以空格分隔

SNS_VIP="10.0.0.200 10.0.0.201"

. /etc/rc.d/init.d/functions

if [[ -z "$SNS_VIP"  ]];then
    echo 'Please set vips in '$0' with SNS_VIP!'
fi 

start(){
num=0
for loop in $SNS_VIP
do
    /sbin/ifconfig lo:$num $loop netmask 255.255.255.255 broadcast $loop
    /sbin/route add -host $loop dev lo:$num
    ((num++))
done
echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
sysctl -e -p >/dev/null 2>&1
} 

stop(){
num=0
for loop in $SNS_VIP
do
    /sbin/ifconfig lo:$num down
    /sbin/route del -host $loop >/dev/null 2>&1
    ((num++))
done
echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
sysctl -e -p >/dev/null 2>&1
} 

case "$1" in
    start)
        start
        echo "RealServer Start OK"
        ;;
    stop)
        stop
        echo "RealServer Stoped"
        ;;
    restart)
        stop
        start
        ;;
    *)
         echo "Usage: $0 {start|stop|restart}"
         exit 1
esac
exit 0
```
启动脚本,并设置开机启动
```
service lvs start
chkconfig lvs on

chkconfig --list |grep lvs
```
##### lvs 端查看并发量
```

操作步骤详细到命令行级别
查看LVS的连接情况:  ipvsadm -L -n
查看LVS的吞吐量情况:  ipvsadm -L -n --rate
查看LVS的统计信息:  ipvsadm -L -n --stats
实时查看LVS连接状态变化:  watch ipvsadm ipvsadm -L -n
```

```
[root@lvs1 keepalived]# ipvsadm -L -n
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.0.0.200:80 wrr
  -> 10.0.0.110:80                Route   10     206        6267      
  -> 10.0.0.111:80                Route   10     209        6265      
TCP  10.0.0.201:80 wrr
  -> 10.0.0.110:80                Route   10     226        3906      
  -> 10.0.0.111:80                Route   10     237        3894      
[root@lvs2 keepalived]# 
```

