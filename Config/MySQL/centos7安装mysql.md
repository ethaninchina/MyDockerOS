```
#安装mysql5.6
rpm -ivh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm



yum install mysql mysql-server mysql-devel -y

systemctl enable mysqld
systemctl start mysqld
systemctl status mysqld


mysql -uroot -p
Grant all privileges on *.* to 'root'@'localhost' identified by '123456' with grant option;




# mysql 5.7 安装 
rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm


yum install mysql mysql-server mysql-devel -y

systemctl enable mysqld
systemctl start mysqld
systemctl status mysqld


grep 'password' /var/log/mysqld.log

mysql -uroot -p

#修改密码
alter user 'root'@'localhost' identified by 'ABC520EFG520___';

#刷新内容
flush privileges; 


vi /etc/my.cnf
#添加
[mysqld]
character_set_server=utf8
init_connect='SET NAMES utf8'

systemctl restart mysqld
systemctl status mysqld
```
