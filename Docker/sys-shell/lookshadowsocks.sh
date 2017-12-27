#!/bin/bash 
ps -ef|grep shadowsocks|grep -v grep >/dev/null 1>/dev/null
if [ $? -ne  0 ]  
    then 
/usr/bin/python /usr/bin/ssserver -c /etc/shadowsocks.json -d start
	 fi 

