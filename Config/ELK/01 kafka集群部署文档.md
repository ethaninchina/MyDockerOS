### 一、下载kafka
官网地址：http://kafka.apache.org<br>
学习地址：http://orchome.com/kafka/index<br>
下载地址：http://kafka.apache.org/downloads.html<br>
```shell
wegt http://mirrors.hust.edu.cn/apache/kafka/1.1.1/kafka_2.11-1.1.1.tgz
tar -zxvf kafka_2.11-1.1.1.tgz
mv  kafka_2.11-1.1.1 /usr/local/
cd /usr/local/
ln -s kafka_2.11-1.1.1 kafka
```
### 二、新建kafka和zookeeper数据目录
```shell
mkdir -p /data/zookeeper
mkdir -p /data/kafka-logs
#以下三行在192.168.34.61/62/63上分别执行
echo "0" > /data/zookeeper/myid
echo "1" > /data/zookeeper/myid
echo "2" > /data/zookeeper/myid
```
### 三、编译kafka和zookeeper配置文件

#编辑配置文件zookeeper.properties
```shell
cat >/usr/local/kafka/config/zookeeper.properties<<EOF
dataDir=/data/zookeeper
dataLogDir=/data/zookeeper/logs
clientPort=2181
maxClientCnxns=100
tickTime=2000
initLimit=10
syncLimit=5
server.0=192.168.34.61:2088:3088
server.1=192.168.34.62:2088:3088
server.2=192.168.34.63:2088:3088
EOF
```
#编辑配置文件server.properties
```shell
cat >/usr/local/kafka/config/server.properties<<EOF
#61/62/63三台分别为 0，1，2
broker.id=0
#分别改为主机的IP，即61/62/63
listeners=PLAINTEXT://192.168.34.61:9092  
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/data/kafka-logs
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=72
default.replication.factor=3
auto.create.topics.enable=true
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=192.168.34.61:2181,192.168.34.62:2181,192.168.34.63:2181
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
EOF
```
### 四、配置kafka环境变量
```shell
echo 'export PATH=$PATH:/usr/local/kafka/bin' >> /etc/profile
source /etc/profile
```
### 五、后台启动服务
#分别在192.168.34.61/62/63上执行
```shell
cd /usr/local/kafka
bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
bin/kafka-server-start.sh config/server.properties
```
