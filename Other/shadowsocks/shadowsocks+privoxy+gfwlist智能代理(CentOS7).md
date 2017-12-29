# Shadowsocks 客户端
- 安装
```shell
yum install python-pip  -y
pip install --upgrade pip
pip install shadowsocks
```
- 配置
```shell
vi /etc/shadowsocks.json

{
  "server":"x.x.x.x",             #你的 ss 服务器 ip
  "server_port":443,              #你的 ss 服务器端口
  "local_address": "127.0.0.1",   #本地ip
  "local_port":1080,              #本地端口
  "password":"password",          #连接 ss 密码
  "timeout":300,                  #等待超时
  "method":"aes-256-cfb",         #加密方式
  "workers": 1                    #工作线程数
}
```
- 启动
```shell
/usr/bin/sslocal -c /etc/shadowsocks.json /dev/null &

#开机启动
echo "/usr/bin/sslocal -c /etc/shadowsocks.json /dev/null &" >>/etc/rc.local
```

- 测试
```shell
curl --socks5 127.0.0.1:1080 http://packages.cloud.google.com
```
- 出现以下结构说明正常，CN直接去curl是无法拿到数据的
``` shell
<html>
  <head>
    <title>Directory listing for /</title>
  </head>
  <body>
    <h2>Index of /</h2>
    <p></p>
    <a href="/apt">apt</a><br />
    <a href="/yuck">yuck</a><br />
    <a href="/yum">yum</a><br />
    <a href="/yum-legacy">yum-legacy</a><br />
  </body>
</html>
```

# Privoxy是一款带过滤功能的代理服务器，针对HTTP、HTTPS协议

- Shadowsocks 是一个 socket5 服务，我们需要使用 Privoxy 把流量转到 http／https 上
```shell
yum install privoxy -y
#开机启动
systemctl enable privoxy.service

#查看
systemctl -l status privoxy.service
```
- 配置
```shell
vim /etc/privoxy/config
#[root@ss privoxy]# grep -vE "^$|#" /etc/privoxy/config
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address  0.0.0.0:8118
toggle  1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 0
forwarded-connect-retries  0
accept-intercepted-requests 0
allow-cgi-request-crunching 0
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
```

- 启动privoxy
```shell
systemctl start privoxy.service
```
- 下载gfwlist
```shell
curl -skL https://raw.github.com/zfl9/gfwlist2privoxy/master/gfwlist2privoxy -o gfwlist2privoxy

#生成 gfwlist.action 文件
bash gfwlist2privoxy '127.0.0.1:1080'

#拷贝至 privoxy 配置目录
cp -af gfwlist.action /etc/privoxy/

#加载 gfwlist.action 文件
echo 'actionsfile gfwlist.action' >> /etc/privoxy/config

#重新启动 privoxy.service 服务
systemctl restart privoxy.service
systemctl -l status privoxy.service
```

- 计入系统配置 /etc/profile
```shell
#privoxy 默认监听端口为 8118
proxy="http://127.0.0.1:8118"
export http_proxy=$proxy
export https_proxy=$proxy
export no_proxy="localhost, 127.0.0.1, ::1, ooxx.cn, baidu.com"
#no_proxy 环境变量是指不经过 privoxy 代理的地址或域名
#只能填写具体的 IP、域名后缀，多个条目之间使用 ',' 逗号隔开
#如: export no_proxy="localhost, 192.168.1.1, ip.cn, chinaz.com"
#访问 localhost、192.168.1.1、ip.cn、*.ip.cn、chinaz.com、*.chinaz.com 将不使用代理

#刷新/etc/profile
source /etc/profile
```

- 测试成功

```shell 
curl -sL www.baidu.com
curl -sL packages.cloud.google.com
```
