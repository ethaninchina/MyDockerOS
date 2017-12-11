#!/bin/bash
free=`free -m | awk 'NR==2' | awk '{print $4}'`

if [ $free -le 50 ];then
                sync && echo 1 > /proc/sys/vm/drop_caches
                sync && echo 2 > /proc/sys/vm/drop_caches
                sync && echo 3 > /proc/sys/vm/drop_caches
fi

