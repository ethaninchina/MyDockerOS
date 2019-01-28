### 企业级 DNS 内网域名解析(主备) 配置
##### 主机: 10.0.0.111
##### 备机: 10.0.0.113

#####  主机: 10.0.0.111  ##### 
```
yum install gcc-c++ openssl openssl-devel -y
yum install bind -y

[yunwei@dns01 ~]$ sudo cat /etc/named.conf

options {
	listen-on port 53 { any; }; //监听地址
	listen-on-v6 port 53 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { any; }; //允许所有查询
	notify yes; //主动同步给从服务器

	recursion yes; //允许递归查询

	dnssec-enable yes; //是否支持DNSSEC开关
	dnssec-validation yes; //是否进行DNSSEC确认开关
	dnssec-lookaside auto; //当设置dnssec-lookaside,它为验证器提供另外一个能在网络区域的顶层验证DNSKEY的方法

	# forwarders {       	 	//即访问非内网域名时将解析转发到这几个DNS地址(分别为114的DNS、google的DNS)上进行解析 
    #           114.114.114.114; //注意这里转发的是DNS地址，没有指定DNS转发域名。
    #           8.8.8.8;
    #           8.8.4.4;
    #        };

	bindkeys-file "/etc/named.iscdlv.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
```

#####  主机: 10.0.0.111  ##### 
```
[yunwei@dns01 ~]$ sudo cat /etc/named.rfc1912.zones

zone "myapi.com" IN {
	type master;
	file "myapi.com.zone";
	allow-update { none;};  //是否允许更新。
	allow-transfer { 10.0.0.113; };//允许哪个主机同步数据库文件,备机
	also-notify { 10.0.0.113; };// 备机
	notify yes;
};
zone "my-niubi.com" IN {
        type master;
        file "my-niubi.com.zone";
        allow-update { none;};
        allow-transfer { 10.0.0.113; };
        also-notify { 10.0.0.113; };
        notify yes;
};
```
##### 配置要解析的 内网域名  (主机配置即可,备机无需配置)
###### myapi.com.zone
```
vim /var/named/myapi.com.zone

$TTL 1D
@       		IN SOA  myapi.com. admin.myapi.com. (
                                        32	; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       		IN NS   	dns1.myapi.com.
dns1    		IN A    	10.0.0.111
www   			IN A 		10.0.0.109
api   			IN A 		10.0.0.110
```
###### my-niubi.com.zone
```
vim /var/named/my-niubi.com.zone

$TTL 1D
@       		IN SOA  my-niubi.com. admin.my-niubi.com. (
                                        18	; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       		IN NS   	dns1.my-niubi.com.
dns1    		IN A    	10.0.0.111
;----------------------web server-------------------
www	    		IN A    	10.0.0.109
api	    		IN A    	10.0.0.110
;----------------------down file server-------------------
download		IN A    	10.0.0.77
```


####################################################
###############  备机: 10.0.0.113  #################
####################################################
```
[yunwei@dns02 ~]$ sudo cat /etc/named.conf

options {
	listen-on port 53 { any; };
	listen-on-v6 port 53 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { any; };

	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;
	dnssec-lookaside auto;

	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.iscdlv.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
```
#####  从机: 10.0.0.113  ##### 
```
zone "myapi.com" IN {
	type slave;
	masters {10.0.0.111;}; // 主机地址
	file "slaves/myapi.com.zone";
	allow-update { none;};
};
zone "my-niubi.com" IN {
	type slave;
	masters {10.0.0.111;};
	file "slaves/my-niubi.com.zone";
	allow-update { none;};
};
```



