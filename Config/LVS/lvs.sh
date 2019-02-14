#!/bin/sh
### BEGIN INIT INFO
# Provides: lvs_realserver
# Default-Start:  3 4 5
# Default-Stop: 0 1 6
# Short-Description: LVS real_server service scripts
# Description: LVS real_server start and stop controller
### END INIT INFO
#  Copyright 2013 lxcong
#
#  chkconfig: - 20 80
#
#  Author:  xxxx@xxxx

#有多个虚拟IP，以空格分隔

SNS_VIP="10.0.0.200"

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
for loop in $WEB_VIP
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
        echo -e "\033[31m VIP 已启动 \033[0m"
        ;;
    stop)
        stop
        echo -e "\033[31m VIP 已停止 \033[0m"
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
