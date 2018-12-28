#配置yum源
vim /etc/yum.repos.d/influxdata.repo

[influxdb]
name = InfluxData Repository - RHEL $releasever
baseurl = https://repos.influxdata.com/rhel/$releasever/$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key

# 安装
yum install telegraf influxdb -y


#启动
systemctl enable telegraf
systemctl restart telegraf
systemctl status telegraf

systemctl enable influxd
systemctl restart influxd
systemctl status influxd



#配置telegraf 关键项目
vim /etc/telegraf/telegraf.conf

#influxdb数据库作为存储数据库
  urls = ["http://10.125.20.113:8086"]
  database = "pda"
  username = "pdaadmin"
  password = "pdaauthpass"


    [[inputs.procstat]]
    pattern = "redis"