#!/bin/bash
#导出数据库
SQL_USER=root
SQL_PASSWD=123456
SQL_PORT=3306
SQL_HOST=192.168.1.100
SQL_DB_online=onlinedb
#SQL_DB_dev=devdb


# mysql备份导出速度快
mysqldump -h $SQL_HOST -u$SQL_USER -p$SQL_PASSWD -P$SQL_PORT --opt \
--default-character-set=utf8 \
--max_allowed_packet=1073741824 \
--net_buffer_length=16384 \
--hex-blob $SQL_DB_online | gzip > /MySQL_BAK/online.DB/liubei_online_`date +%F_%H%M%S`.sql.gz


#sleep 3
# 删除30天前的数据
#find /MySQL_BAK/online.DB/ -mtime +30 -name "*" -exec rm -rf {} \;

#数据导入
#mysql -uroot -p123456 onlinedb < /root/onlinedb_2018-03-02_114956.sql

############################################# shell end ########################################################

# 数据来源 max_allowed_packet 和 net_buffer_length 获得方法 mysql命令

mysql> show variables like 'max_allowed_packet';
+--------------------+-------------+
| Variable_name      | Value       |
+--------------------+-------------+
| max_allowed_packet | 1073741824  |
+--------------------+-------------+
1 row in set (0.00 sec)

mysql> show variables like 'net_buffer_length';
+-------------------+-------+
| Variable_name     | Value |
+-------------------+-------+
| net_buffer_length | 16384 |
+-------------------+-------+
1 row in set (0.00 sec)

