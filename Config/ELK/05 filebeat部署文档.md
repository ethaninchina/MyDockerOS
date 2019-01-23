# 一、下载filebeat
官网地址：http://kafka.apache.org<br>
学习地址：https://www.elastic.co/guide/en/beats/libbeat/6.2/release-notes-6.2.4.html<br>
下载地址：https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.2.4-linux-x86_64.tar.gz<br>
```shell
cd /usr/local/src
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.2.4-linux-x86_64.tar.gz
tar -zxvf filebeat-6.2.4-linux-x86_64.tar.gz
mv filebeat-6.2.4-linux-x86_64 ../
ln -s filebeat-6.2.4-linux-x86_64 filebeat
```

# 二、编辑启动脚本
```shell
cat >/usr/local/filebeat/filebeat-service.sh <<EOF
#! /bin/bash
PATH=/usr/bin:/sbin:/bin:/usr/sbin
export PATH
agent="/usr/local/filebeat/filebeat"
args="-c /usr/local/filebeat/filebeat.yml -path.home /usr/local/filebeat -path.config /usr/local/filebeat -path.data /usr/local/filebeat/data -path.logs /usr/local/filebeat/logs"
test_args="-e -configtest"
test() {
$agent $args $test_args
}

start() {
    pid=`ps -ef |grep /usr/local/filebeat/filebeat |grep -v grep | awk  '{ print $2}'`
    if [ ! "$pid" ];then
        echo "Starting filebeat... "
        test
        if [ $? -ne 0 ]; then
            echo
            exit 1
        fi
        $agent $args &
        if [ $? == 0 ];then
            echo "start filebeat ok"
        else
            echo "start filebeat failed"
        fi
    else
        echo "filebeat is still running!"
        exit
    fi
}

stop() {
    echo -n $"Stopping filebeat: "
    pid=`ps -ef |grep /usr/local/filebeat/filebeat |grep -v grep | awk  '{ print $2}'`
    if [ ! "$pid" ];then
echo "filebeat is not running"
    else
        kill $pid
echo "stop filebeat ok"
    fi 
}   

restart() {
    stop
    start
}

status(){
    pid=`ps -ef |grep /usr/local/filebeat/filebeat |grep -v grep | awk  '{ print $2}'`
    if [ ! "$pid" ];then
        echo "filebeat is not running"
    else
        echo "filebeat is running"
    fi
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        restart
    ;;
    status)
        status
    ;;
    *)
        echo $"Usage: $0 {start|stop|restart|status}"
        exit 1
esac
EOF
```

# 三、配置环境变量
```shell
echo 'export PATH=$PATH:/usr/local/kiban/bin' >> /etc/profile
source /etc/profile
```

# 四、编辑相关配置文件
#1.java类配置文件
```shell
cat >/usr/local/filebeat/filebeat.yml<<EOF
#=========================== Filebeat prospectors =============================
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - /app/logs/*.log
  fields:
    system: ec-java
  ignore_older: 1h
  multiline.pattern: "^[^0-9]|^$"
  multiline.negate: false
  multiline.match: after
#==================== Elasticsearch template setting ==========================
setup.template.settings:
  index.number_of_shards: 3
#=============================== output =======================================
#输出到kafka
output.kafka:
  enabled: true
  hosts: ["192.168.34.60:9092"]
  topic: '%{[fields][system]}'
EOF
```
#2.nginx类配置文件
```shell
cat >/usr/local/filebeat/filebeat.yml<<EOF
#=========================== Filebeat prospectors =============================
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - /usr/local/nginx/logs/access.log
  fields:
    system: ec-nginx37-access
  ignore_older: 1h
- type: log
  enabled: true
  paths:
    - /usr/local/nginx/logs/error.log
  fields:
    system: ec-nginx37-error
  ignore_older: 1h
#==================== Elasticsearch template setting ==========================

setup.template.settings:
  index.number_of_shards: 3
#=============================== output =======================================
#输出到kafka
output.kafka:
  enabled: true
  hosts: ["192.168.34.60:9092"]
  topic: '%{[fields][system]}'
EOF
```
#3.mysql类配置文件
```shell
cat >/usr/local/filebeat/filebeat.yml<<EOF
#=========================== Filebeat prospectors =============================
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - /data/mysql/mysql3306/data/error.log
  fields:
    system: vms-mysql
#==================== Elasticsearch template setting ==========================
setup.template.settings:
  index.number_of_shards: 3
#=============================== output =======================================
#输出到kafka
output.kafka:
  enabled: true
  hosts: ["192.168.34.60:9092"]
  topic: '%{[fields][system]}'
EOF
```

#4.zabbix类配置文件
```shell
cat >/usr/local/filebeat/filebeat.yml<<EOF
#=========================== Filebeat prospectors =============================
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - /var/log/zabbix/zabbix_server.log
    - /var/log/zabbix/zabbix_agentd.log
  fields:
    system: elk-zabbix
#==================== Elasticsearch template setting ==========================
setup.template.settings:
  index.number_of_shards: 3
#=============================== output =======================================
#输出到kafka
output.kafka:
  enabled: true
  hosts: ["192.168.34.60:9092"]
  topic: '%{[fields][system]}'
EOF
```

# 五、启动服务
```shell
sh /usr/local/filebeat/filebeat-service.sh start
```