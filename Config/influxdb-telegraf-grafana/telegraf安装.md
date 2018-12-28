# 配置yum源
```
vim /etc/yum.repos.d/influxdata.repo
```

```
[influxdb]
name = InfluxData Repository - RHEL $releasever
baseurl = https://repos.influxdata.com/rhel/$releasever/$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
```

# 安装 influxdb , telegraf
```
yum install telegraf influxdb -y


#启动
systemctl enable telegraf
systemctl restart telegraf
systemctl status telegraf

systemctl enable influxd
systemctl restart influxd
systemctl status influxd
```


# 配置客户端 telegraf 关键项目
```
vim /etc/telegraf/telegraf.conf
```

# 修改influxdb数据库作为存储数据库
```
  urls = ["http://113.115.120.143:8086"]
  database = "mydb"
  username = "myadmin"
  password = "mypasswd"

...
...
...
    [[inputs.procstat]]
    pattern = "redis"
```
