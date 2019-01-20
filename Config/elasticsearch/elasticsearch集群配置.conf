ELK (elasticsearch 集群)
#kibana连接集群点

10.0.0.113  es-cluster-node1
10.0.0.109  es-cluster-ma-node1
10.0.0.110  es-cluster-ma-node2
10.0.0.111  es-cluster-ma-node3


# 主/备节点
yum install git java-1.8* -y

echo '
10.0.0.113  es-cluster-node1
10.0.0.109  es-cluster-ma-node1
10.0.0.110  es-cluster-ma-node2
10.0.0.111  es-cluster-ma-node3
' >> /etc/hosts

#下载安装包 [主节点]
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.4.3.rpm
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.4.3.rpm
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.4.3-x86_64.rpm
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.4.3-x86_64.rpm

#备节点安装[elasticsearch]
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.4.3.rpm
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.4.3-x86_64.rpm


##### 主节点(kibana连接es集群) (只测试kibana + elasticsearch )
cp /etc/kibana/kibana.yml{,.bak}
cp /etc/elasticsearch/elasticsearch.yml{,.bak}
mkdir -p /data/elk/es/{data,logs}
chmod 777 /data/elk/es/ -R

echo '
cluster.name: my_es_cluster
node.name: es-node1
path.data: /data/elk/es/data
path.logs: /data/elk/es/logs
http.cors.enabled: true
http.cors.allow-origin: "*"
node.master: false
node.data: true
# 配置白名单 0.0.0.0表示其他机器都可访问
network.host: 0.0.0.0
transport.tcp.port: 9300
# tcp 传输压缩
transport.tcp.compress: true
http.port: 9200
discovery.zen.ping.unicast.hosts: ["es-cluster-ma-node1:9300", "es-cluster-ma-node2:9300", "es-cluster-ma-node3:9300"]
discovery.zen.minimum_master_nodes: 2
#为了防止集群发生“脑裂”，即一个集群分裂成多个，通常需要配置集群最少主节点数目，通常为 (可成为主节点的主机数目 / 2) + 1，例如我这边可以成为主节点的主机数目为 7，那么结果就是 4，配置示例：
# 以下配置可以减少当es节点短时间宕机或重启时shards重新分布带来的磁盘io读写浪费
discovery.zen.fd.ping_timeout: 300s
discovery.zen.fd.ping_retries: 8
discovery.zen.fd.ping_interval: 30s
discovery.zen.ping_timeout: 180s
'>/etc/elasticsearch/elasticsearch.yml




##### 集群节点 ["es-cluster-ma-node1:9300", "es-cluster-ma-node2:9300", "es-cluster-ma-node3:9300"]
cp /etc/elasticsearch/elasticsearch.yml{,.bak}
mkdir -p /data/elk/es/{data,logs}
chmod 777 /data/elk/es/ -R

echo '
cluster.name: my_es_cluster
node.name: es-cluster-node1
path.data: /data/elk/es/data
path.logs: /data/elk/es/logs
http.cors.enabled: true
http.cors.allow-origin: "*"
node.master: true
node.data: true
# 配置白名单 0.0.0.0表示其他机器都可访问
network.host: 0.0.0.0
transport.tcp.port: 9300
# tcp 传输压缩
transport.tcp.compress: true
http.port: 9200
discovery.zen.ping.unicast.hosts: ["es-cluster-ma-node1:9300", "es-cluster-ma-node2:9300", "es-cluster-ma-node3:9300"]
discovery.zen.minimum_master_nodes: 2
#为了防止集群发生“脑裂”，即一个集群分裂成多个，通常需要配置集群最少主节点数目，通常为 (可成为主节点的主机数目 / 2) + 1，例如我这边可以成为主节点的主机数目为 7，那么结果就是 4，配置示例：
# 以下配置可以减少当es节点短时间宕机或重启时shards重新分布带来的磁盘io读写浪费
discovery.zen.fd.ping_timeout: 300s
discovery.zen.fd.ping_retries: 8
discovery.zen.fd.ping_interval: 30s
discovery.zen.ping_timeout: 180s
'>/etc/elasticsearch/elasticsearch.yml
 

##### 设置 kibana
echo '
server.port: 5601
server.host: "0.0.0.0"
# ES的url的一个ES节点#
elasticsearch.url: "http://10.0.0.111:9200"
kibana.index: ".kibana"
'>/etc/kibana/kibana.yml

yum install -y git
git clone https://github.com/anbai-inc/Kibana_Hanization.git
cd Kibana_Hanization
python main.py /usr/share/kibana

#启动
systemctl restart elasticsearch
systemctl restart kibana

systemctl status elasticsearch
systemctl status kibana



#集群查看
http://10.0.0.113:9200/_cat/nodes?pretty

http://10.0.0.113:9200/_cat/shards

http://10.0.0.113:9200/_cat/health





 
