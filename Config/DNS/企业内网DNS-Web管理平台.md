### Bind-DLZ + Flask + Mysql DNS管理平台
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
 ln -s /usr/lib64/mysql/  .so /usr/lib/libmysqlclient.so
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
##### 4, 配置Bind vi /usr/local/bind/etc/named.conf
```
	options {
			directory       "/usr/local/bind/";
			version         "bind-9.9.5";
			listen-on port 53 { any; };
			allow-query-cache { any; };
			listen-on-v6 port 53 { any; };
			allow-query     { any; };
			recursion yes;    
			dnssec-enable yes;
			dnssec-validation yes;
			dnssec-lookaside auto;

	};
	 
	 
	key "rndc-key" {
			algorithm hmac-md5;
			secret "C4Fg6OGjJipHKfgUWcAh+g==";

	};
	 
	controls {
			inet 127.0.0.1 port 953
					allow { 127.0.0.1; } keys { "rndc-key"; };
	};
	 
	 
	view "ours_domain" {
			match-clients           {any; };
			allow-query-cache           {any; };
			allow-recursion          {any; };
			allow-transfer          {any; };
	 
			dlz "Mysql zone" {
					database        "mysql
					{host=localhost dbname=named ssl=false port=3306 user=root pass=123456}
					{select zone from dns_records where zone='$zone$'}
					{select ttl, type, mx_priority, case when lower(type)='txt' then concat('\"', data, '\"') when lower(type) = 'soa' then concat_ws(' ', data, resp_person, serial, refresh, retry, expire, minimum) else data end from dns_records where zone = '$zone$' and host = '$record$'}"; 
			};
			zone "."  IN {
				type hint;
				file "/usr/local/bind/etc/named.ca";
			};
	 
	};
```
##### 5, 生成 name.ca文件
```
cd /usr/local/bind/etc/
dig -t NS .  >named.ca
```
##### 6, 下载web文件
```
git clone https://github.com/station19/Bind-Web-1.git
cd Bind-Web
```
##### 7, 配置数据库，导入sql 文件
```
mysql -uroot -p   #登录数据库
mysql> CREATE DATABASE  named   CHARACTER SET utf8 COLLATE utf8_general_ci; 
mysql> source /root/Bind-Web/named.sql;             #注意路径，这里我放在当前目录
就两张表，一个dns用到的表，一个用户管理表
```

##### 8, 设置数据库
```
vim /root/Bind-Web/config.py
db_host = 'localhost'
db_name = 'named'
db_user = 'root'
db_passwd = '123456'
```
##### 9, 安装python相关环境
```
cd 
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

cd /root/Bind-Web/
yum install python-devel -y
pip install -r requirement.txt

python run.py
```

###### 启动 bind 

```
mkdir  /var/run/named/ && chown  named:named -R /var/run/named 
cd /root/Bind-Web/bind /etc/init.d/bind 
chmod +x /etc/init.d/bind
/etc/init.d/bind  start            #监控日志，查看启动状态
chkconfig  --add bind            #加入开机启动
```






