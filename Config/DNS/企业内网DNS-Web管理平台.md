### Bind-DLZ + Django + Mysql DNS管理平台
##### 系统环境:CentOS Linux release 7.4.1708 (Core)

###### 1,安装mysql 5.6
```
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm-ivh mysql-community-release-el7-5.noarch.rpm
yum install mysql mysql-server mysql-devel -y
```

```
vim /etc/my.cnf
character-set-server=utf8
```

```
systemctl enable mysql
systemctl start mysql
systemctl status mysql


mysql -uroot -p
Grant all privileges on *.* to 'root'@'localhost' identified by '123456' with grant option;
```

##### 2, 安装 bind-9.9.5
```
 wget http://distfiles.macports.org/bind9/bind-9.9.5.tar.gz
 tar -zxvf  bind-9.9.5.tar.gz
 cd bind-9.9.5
 
 ./configure --prefix=/usr/local/bind/  \
 --enable-threads=no \
 --enable-newstats   \
 --with-dlz-mysql    \
 --disable-openssl-version-check
 
 #官网说明强调编译关闭多线程，即--enable-threads=no
 
 make
 make install           #源码编译安装完成
 
 # 如果提示 not found  libmysqlclient,执行下面命令
 # ln -s /usr/lib64/mysql/libmysqlclient.so /usr/lib/libmysqlclient.so
```
##### 3, 环境变量配置
```
cat>>/etc/profile<<EOF 
export PATH=$PATH:/usr/local/bind/bin:/usr/local/bind/sbin
EOF

source  /etc/profile  #重新加载一下环境变量
named -v 
 
useradd  -s  /sbin/nologin  named
chown  -R named:named /usr/local/bind/
```

#### 剩余步骤,移步到 https://github.com/station19/Bind-Web

