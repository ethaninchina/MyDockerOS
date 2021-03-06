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
#自定义docker-compose版本
docker_compose_version=1.18.0
# ****** 自定义参数 end ******

# ************** 下面内容是程序自动执行 ************** 
#关闭selinux
sed -i s/=enforcing/=disabled/g /etc/selinux/config
setenforce 0

#安装工具
yum install -y zip unzip lrzsz curl telnet

#创建docker项目相关文件路径,下载所需配置文件
mkdir /root/docker
cd /root/docker
curl -O https://raw.githubusercontent.com/station19/MyDockerOS/master/Docker/wwwdocker/wwwdocker-alpine.tar.gz
tar zxvf wwwdocker-alpine.tar.gz
#删除压缩包
rm -fr /root/docker/wwwdocker-alpine.tar.gz

#内核优化,内核修改即时生效
curl -o /etc/sysctl.conf https://raw.githubusercontent.com/station19/MyDockerOS/master/Config/sysctem/sysctl.conf
sysctl -p

#配置ulimit
echo -e "
* soft nofile 102400
* hard nofile 102400
" >>/etc/security/limits.conf
echo "ulimit -SHn 102400" >>/etc/profile
#即时生效
source /etc/profile

#安装docker
yum install epel-release -y
yum update -y
yum install docker -y
systemctl enable docker.service
systemctl start docker.service

#拉取docker项目,根据服务器IP判断选择镜像地址和选择docker0compose地址安装
sourceIP=$(curl -sk http://www.3322.org/dyndns/getip)
IPgsd=$(curl -sk http://ip.taobao.com/service/getIpInfo.php?ip=$sourceIP|cut -d "\"" -f 12)

#如果IP为中国，则使用阿里云镜像
if [[ "$IPgsd" = "CN" ]]; then
#IP属于CN,则利用CN 加速镜像安装docker-compose
curl -L https://get.daocloud.io/docker/compose/releases/download/$docker_compose_version/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
#阿里云docker镜像地址
    openresty_version="registry.cn-hangzhou.aliyuncs.com/webss/openresty:openresty-alpine"
    php_version="registry.cn-hangzhou.aliyuncs.com/webss/php:7.1.12-alpine"
    mysql_version="registry.cn-hangzhou.aliyuncs.com/webss/mysql:5.7"
    redis_version="registry.cn-hangzhou.aliyuncs.com/webss/redis:3.2.11-alpine"
    shadowsocks_version="registry.cn-hangzhou.aliyuncs.com/webss/ss-server"
else
#使用github安装docker-compose编排服务
curl -L https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
#docker.io镜像地址   
    openresty_version="docker.io/wuyuzai/mydockeros:openresty-alpine"
    php_version="docker.io/wuyuzai/mydockeros:php7.1.12-alpine"
    mysql_version="docker.io/mysql:5.7"
    redis_version="docker.io/wuyuzai/redis:3.2.11-alpine"
    shadowsocks_version="docker.io/easypi/shadowsocks-libev"
fi

#下载、配置docker-compose.yml 文件
wget -c "https://github.com/station19/MyDockerOS/raw/master/Docker/docker-compose/demo.yml" -O "/root/docker/docker-compose.yml"
#修改上面获取的docker-compose.yml变量值
sed -i s#ss_pass#$ss_pass#g /root/docker/docker-compose.yml
sed -i s#ss_port#$ss_port#g /root/docker/docker-compose.yml
sed -i s#openresty_version#$openresty_version#g /root/docker/docker-compose.yml
sed -i s#php_version#$php_version#g /root/docker/docker-compose.yml
sed -i s#mysql_version#$mysql_version#g /root/docker/docker-compose.yml
sed -i s#mysql_pass#$mysql_pass#g /root/docker/docker-compose.yml
sed -i s#redis_version#$redis_version#g /root/docker/docker-compose.yml
sed -i s#shadowsocks_version#$shadowsocks_version#g /root/docker/docker-compose.yml

#添加开机启动docker服务
echo "/usr/local/bin/docker-compose -f /root/docker/docker-compose.yml up -d" >> /etc/rc.local

#增加权限防止误删docker-compose.yml文件
chattr +i /root/docker/docker-compose.yml

#日志写入权限,否则会导致mysql启动失败问题
chmod 777 /root/docker/logs -R
#下载目录框架cache目录写入权限
chmod 777 /root/docker/web/download/_h5ai/p*/cache

#首次启动docker-compose
/usr/local/bin/docker-compose -f /root/docker/docker-compose.yml up -d

#关闭系统自带防火墙 firewall
systemctl stop firewalld.service
#禁止firewall开机自启
systemctl mask firewalld
#禁止firewall开机自启
systemctl disable firewalld.service

#安装iptables
yum install -y iptables
yum update iptables -y
yum install iptables-services -y

#增加一处判定ssh端口脚本 # ssh port start
ssh_port=$(grep ^Port /etc/ssh/sshd_config|awk '{print $2}')
if [ -z "$ssh_port" ]; then
        SSH_Port=22
        echo $SSH_Port
 else
 
for SSH_Port in $ssh_port
do
        echo $SSH_Port 
done
fi 
# ssh port end

#设置iptables配置
cat>/etc/sysconfig/iptables<<EOF
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
#特殊端口指定IP管理
#-A INPUT -s 192.168.0.19/32 -p tcp --dport 22 -j ACCEPT
#-A INPUT -s 192.168.0.19/32 -p tcp --dport 3306 -j ACCEPT
#开放不连续端口
#-A INPUT -p tcp -m multiport --dport 123,234,345,456 -j ACCEPT
#常规端口开放
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport $SSH_Port -j ACCEPT
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
   ***  安装完成, 系统第一次安装 需要重启(reboot)系统后 iptables的NAT服务才能成功自动映射docker端口  ***
   
          *** 请执行命令【 reboot 】 重启服务器 *** 
          
          *** 如iptables nat转发正常使用 请忽略 ****
 "
 
#删除shell
cd /root && rm $0
