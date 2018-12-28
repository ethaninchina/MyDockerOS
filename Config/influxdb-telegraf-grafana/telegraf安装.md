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
[global_tags]
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""
  hostname = ""
  omit_hostname = false
[[outputs.influxdb]]
   urls = ["http://113.115.120.143:8086"]
  database = "mydb"
  username = "mydmin"
  password = "mypasswd"
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "overlay", "aufs", "squashfs"]
[[inputs.diskio]]
[[inputs.kernel]]
[[inputs.mem]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
[[inputs.http]]
[[inputs.http_response]]
    interval = "60s"
    address = "http://baidu.com"
    response_timeout = "15s"
    method = "GET"
[[inputs.net]]
[[inputs.net_response]]
[[inputs.netstat]]
 [[inputs.nginx]]
      urls = ["http://localhost:9009/nginx_status"]
 [[inputs.http_listener]]
[[inputs.procstat]]
  pattern = "squid"
[[inputs.procstat]]
  pattern = "nginx:"
[[inputs.procstat]]
  pattern = "keepalived"

```
