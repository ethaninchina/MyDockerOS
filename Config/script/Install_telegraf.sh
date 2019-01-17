#!/bin/bash
#本脚本为安装 telegraf 客户端
#set influxdata.repo
cat>/etc/yum.repos.d/influxdata.repo<<EOF
[influxdb]
name = InfluxData Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF


# install telegraf
yum install telegraf  -y

#启动
systemctl enable telegraf
systemctl restart telegraf
systemctl status telegraf
