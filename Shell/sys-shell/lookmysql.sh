#!/bin/bash 
/usr/bin/mysql -uroot -p123456 --connect_timeout=5 -e "show databases;" >/dev/null 1>/dev/null
if [ $? -ne  0 ]  
    then 
      service mysqld stop
      service mysqld start 
fi 
