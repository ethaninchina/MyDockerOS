# 一、下载elasticsearch
```shell
cd /usr/local/src
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.4.tar.gz
tar -xf elasticsearch-6.2.4.tar.gz
mv elasticsearch-6.2.4 ..
ln -s elasticsearch-6.2.4 elasticsearch
```
# 二、编译配置文件
#1.编辑配置文件elasticsearch.yml
```shell
cat > /usr/local/elasticsearch/config/elasticsearch.yml<<EOF
cluster.name: elk-elk
###分别填写节点名字 node-71,node-72,node-73
node.name: node-71 
path.data: /data/es/data
path.logs: /data/es/logs

path.repo: ["/data/es/backup"]

node.master: true
node.data: true
bootstrap.memory_lock: true
###分别填写节点192.168.34.71/72/73
network.host: 192.168.34.71
http.port: 9200
discovery.zen.ping.unicast.hosts: ["192.168.34.71", "192.168.34.72","192.168.34.73"]
discovery.zen.minimum_master_nodes: 2

http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: "Authorization,,X-Requested-With,Content-Length,Content-Type"
transport.tcp.compress: true

xpack.security.enabled: true

#xpack.ssl.key: elasticsearch/elasticsearch.key
#xpack.ssl.certificate: elasticsearch/elasticsearch.crt
#xpack.ssl.certificate_authorities: ca/ca.crt
xpack.security.transport.ssl.enabled: true
EOF
```
#2.编辑配置文件jvm.options
```shell
echo "-Xms16g"
echo "-Xmx16g"
```
#3.设置vm.max_map_count
```shell
echo "vm.max_map_count=262144" >>/etc/sysctl.conf
sysctl -p
```
#4.建立相关文件和用户
```shell
mkdir /data/es/{data,logs} -p
useradd app
chown -R app.app /usr/local/elasticsearch* /data/es
```
# 四、制作服务
```shell
cat >/usr/lib/systemd/system/elasticsearch.service<<EOF
[Unit]
Description=Elasticsearch
Documentation=http://www.elastic.co
Wants=network-online.target
After=network-online.target

[Service]
RuntimeDirectory=elasticsearch
Environment=ES_HOME=/usr/local/elasticsearch
Environment=ES_PATH_CONF=/usr/local/elasticsearch/config
Environment=PID_DIR=/usr/local/elasticsearch
EnvironmentFile=-/etc/sysconfig/elasticsearch
WorkingDirectory=/usr/local/elasticsearch

LimitMEMLOCK=infinity

User=app
Group=app

ExecStart=/usr/local/elasticsearch/bin/elasticsearch -p ${PID_DIR}/elasticsearch.pid --quiet
[Unit]
Description=Elasticsearch
Documentation=http://www.elastic.co
Wants=network-online.target
After=network-online.target

[Service]
RuntimeDirectory=elasticsearch
Environment=ES_HOME=/usr/local/elasticsearch
Environment=ES_PATH_CONF=/usr/local/elasticsearch/config
Environment=PID_DIR=/usr/local/elasticsearch
EnvironmentFile=-/etc/sysconfig/elasticsearch
WorkingDirectory=/usr/local/elasticsearch

LimitMEMLOCK=infinity

User=app
Group=app

ExecStart=/usr/local/elasticsearch/bin/elasticsearch -p ${PID_DIR}/elasticsearch.pid --quiet

# StandardOutput is configured to redirect to journalctl since
# some error messages may be logged in standard output before
# elasticsearch logging system is initialized. Elasticsearch
# stores its logs in /var/log/elasticsearch and does not use
# journalctl by default. If you also want to enable journalctl
# logging, you can simply remove the "quiet" option from ExecStart.
StandardOutput=journal
StandardError=inherit

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Specifies the maximum number of processes
LimitNPROC=4096

# Specifies the maximum size of virtual memory
LimitAS=infinity

# Specifies the maximum file size
LimitFSIZE=infinity

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0

# SIGTERM signal is used to stop the Java process
KillSignal=SIGTERM

# Send the signal only to the JVM rather than its control group
KillMode=process

# Java process is never killed
SendSIGKILL=no

# When a JVM receives a SIGTERM signal it exits with code 143
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target

# Built for distribution-6.2.4 (distribution)
EOF
```

# 五、启动服务
```shell
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
```
