#!/usr/bin/bash
#OS: CentOS7x64
if [ "$(id -u)" -ne "0" ];then
echo "非root用户无权限执行"
exit 1
fi

#全局参数 
# ****** 自定义参数 start ******
#mysql密码
mysql_pass=123456
#自定义ss server端口，ss密码
ss_port=7879
ss_pass=www.baidu.com
# ****** 自定义参数 end ******

# ************** 下面我程序自动执行 ************** 
#关闭selinux
sed -i s/=enforcing/=disabled/g /etc/selinux/config
setenforce 0

#安装必要工具
yum install -y zip unzip lrzsz wget curl

#绑定SS服务IP为eth0的IP
#ss_ip=$(ifconfig eth0|grep -w inet|awk '{print $2}')

#创建docker相关文件路径,下载配置文件
mkdir /root/docker
cd /root/docker
wget https://raw.githubusercontent.com/station19/MyDockerOS/master/Shell/wwwdocker/wwwdocker.tar.gz
tar zxvf wwwdocker.tar.gz
#删除压缩包
rm -fr /root/docker/wwwdocker.tar.gz

#内核优化,内核修改即时生效
curl -o /etc/sysctl.conf https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctl.conf
sysctl -p

#配置ulimit
echo -e "
* soft nofile 102400
* hard nofile 102400
" >>/etc/security/limits.conf
echo "ulimit -SHn 102400" >>/etc/profile

#安装docker
yum install epel-release -y
yum update -y
yum install docker -y
systemctl enable docker.service
systemctl start docker.service

#安装docker-compose编排服务
curl -L https://github.com/docker/compose/releases/download/1.18.0-rc2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
if [ $? -ne  0 ]
    then
    echo "docker-compose 下载安装失败"
    exit 1
fi

#拉取docker项目,根据服务器IP判断选择镜像地址
sourceIP=$(curl -sk http://www.3322.org/dyndns/getip)
IPgsd=$(curl -sk http://ip.taobao.com/service/getIpInfo.php?ip=$sourceIP|cut -d "\"" -f 12)
#如果IP为中国，则使用阿里云镜像,反之则为docker.io官方
if [[ "$IPgsd" = "CN" ]]; then
    lrnp_version="registry.cn-hangzhou.aliyuncs.com/webss/lrnp"
    mysql_version="registry.cn-hangzhou.aliyuncs.com/webss/mysql:5.7"
    shadowsocks_version="registry.cn-hangzhou.aliyuncs.com/webss/sslibev"
else
    lrnp_version="docker.io/wuyuzai/mydockeros:lrnp"
    mysql_version="docker.io/mysql:5.7"
    shadowsocks_version="docker.io/easypi/shadowsocks-libev"
fi

#拉取docker文件文件
docker pull $lrnp_version
docker pull $mysql_version
docker pull $shadowsocks_version

#配置docker-compose.yml 文件
cat>/root/docker/docker-compose.yml<<EOF
version: '2'
    #定义服务lrnp(openresty1.13+redis3.2.9+php7.1.12) 和 mysql(mysql5.7)
services:
        #服务名称
        lrnp:
            #依赖mysql服务，意味着在启动lrnp之前先启动mysql服务容器
            depends_on:
                - mysql
            #nginx镜像的路径
            image: $lrnp_version
            #映射文件/文件夹到宿主机，持久化和方便管理
            volumes:
                - /root/docker/web:/opt/openresty/nginx/html
                - /root/docker/logs/nginx_log:/opt/openresty/nginx/logs
                - /root/docker/nginx-conf:/opt/openresty/nginx/conf
                - /root/docker/logs/php_log:/tmp/phplogs
                - /root/docker/php/php.ini:/etc/php/php.ini
                - /root/docker/php/www.conf:/usr/local/php/etc/php-fpm.d/www.conf
                - /root/docker/redis/redis.conf:/etc/redis.conf
                - /root/docker/logs/redis_log:/tmp/redislogs
            #openresty服务意外退出时自动重启
            restart: always
            #网络模式HOST(使用宿主机网络) 性能更优
            #network_mode: host
            ports:
                - 80:80
                - 443:443
                - 6379:6379
            #容器名称(hostname)
            container_name: lrnp7   
        #服务名称
        mysql:
            image: $mysql_version
            #设置MYSQL_ROOT_PASSWORD环境变量，这里是设置mysql的root密码。
            environment:
                MYSQL_ROOT_PASSWORD: $mysql_pass
            #映射文件路径
            volumes:
                - /root/docker/mysqld/config:/etc/mysql
                - /root/docker/mysqld/mysqldata:/var/lib/mysql
                - /root/docker/logs/mysql_log:/var/log/mysql
            restart: always
            #网络模式HOST 性能更优
            #network_mode: host
            ports:
                - 3306:3306
            #容器名称(hostname)
            container_name: mysql57
        #docker服务
        shadowsocks:
            image: $shadowsocks_version
            environment:
                SERVER_ADDR: 0.0.0.0
                PASSWORD: $ss_pass
                SERVER_PORT: $ss_port
            restart: always
            #网络模式HOST(使用宿主机网络)性能更优
            #network_mode: host
            ports:
                - $ss_port:$ss_port
            #容器名称(hostname)
            container_name: shadowsocks
EOF

#添加开机启动docker服务
echo "/usr/local/bin/docker-compose -f /root/docker/docker-compose.yml up -d" >> /etc/rc.local

#增加权限防止误删docker-compose.yml文件
chattr +i /root/docker/docker-compose.yml

#日志写入权限,否则会导致mysql启动失败问题
chmod 777 /root/docker/logs -R

#首次启动docker-compose
/usr/local/bin/docker-compose -f /root/docker/docker-compose.yml up -d

#关闭系统自带防火墙 firewall
systemctl stop firewalld.service
#禁止firewall开机自启
systemctl mask firewalld
#禁止firewall开机自启
sytsemctl disable firewalld.service

#安装IPtable是
yum install -y iptables
yum update iptables -y
yum install iptables-services -y

#设置iptables配置
cat>/etc/sysconfig/iptables<<EOF
# sample configuration for iptables service
# you can edit this manually or use system-config-firewall
# please do not ask us to add additional ports/services to this default configuration
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [12135:65324]
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
#-A INPUT -s 192.168.0.19/32 -p tcp --dport 22 -j ACCEPT
#-A INPUT -s 192.168.0.19/32 -p tcp --dport 3306 -j ACCEPT
#-A INPUT -p tcp -m multiport --dport 20441,20443,20445,51443 -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport $ss_port -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF

#开机启动iptables
systemctl enable iptables.service
#开启iptables服务
systemctl start iptables.service
#查看iptables配置端口
iptables -L -n

#查看docker服务
docker-compose ps

#结束语
echo -e "
   ***  安装完成, 新系统第一次安装 可能需要重启系统后才能使用 docker-compose 启动服务, 请执行 reboot ***
        
        *** 如正常使用 请忽略 ***
 "
