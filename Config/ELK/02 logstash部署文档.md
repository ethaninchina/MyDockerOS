# 一、下载logstash
官网地址：https://www.elastic.co<br>
下载地址：https://artifacts.elastic.co/downloads/logstash/logstash-6.2.4.tar.gz<br>
学习地址：https://www.elastic.co/guide/en/logstash/6.2/logstash-6-2-4.html<br>
```shell
cd /usr/local/src/
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.2.4.tar.gz
tar -xf logstash-6.2.4.tar.gz
```
# 二、配置logstash目录
```shell
mkdir -p /usr/local/logstash/re
mkdir -p /usr/local/logstash/config
mv /usr/local/src/logstash-6.2.4 /usr/local/logstash/
```
#新增正则匹配文件
```shell
cat >/usr/local/logstash/re/patterns<<EOF
test_LOG %{DATA:time_local}\.[0-9]{3}\s{1,}%{DATA:msg}$
nginx_LOG %{DATA:time_local}\s\|\|\s%{DATA:client_ip}\s\|\|\s%{DATA:upstream_addr}\s\|\|\s%{DATA:status:int}\s\|\|\s%{DATA:request_time:float}\s\|\|\s%{DATA:upstream_response_time:float}\s\|\|\s%{DATA:connection_requests:int}\s\|\|\s%{DATA:body_bytes_sent:int}\s\|\|\s%{DATA:client_host}\s\|\|\s%{DATA:request_method}\s\|\|\s%{DATA:http_user_agent}\s\|\|\s%{DATA:document_uri}\s\|\|\s%{DATA:request_uri}\s\|\|\s%{DATA:http_referer}\s\|\|\s%{DATA:http_cookie}$
nginx2_LOG %{IPORHOST:clientip} - (?<remote_user>(\s+)|-) \[%{HTTPDATE:time}\] \"%{WORD:verb} %{URIPATHPARAM:request} HTTP/%{NUMBER:httpversion}\" %{NUMBER:http_status_code} %{NUMBER:bytes} \"(?<http_referer>\S+)\" %{QS:agent}
EOF
```
# 三、配置环境变量
```shell
echo 'export PATH=$PATH:/usr/local/logstash/bin/logstash-6.2.4' >> /etc/profile
source /etc/profile
```
# 四、新增相关logstash配置文件
#1.新增跨越zabbix项目配置文件
```shell
cat >/usr/local/logstash/config/zabbix.conf<<EOF
###***elk-zabbix系统配置文件***###
input {
     kafka {
        # 注意这里配置的kafka的broker地址不是zk的地址
        bootstrap_servers => ["192.168.34.60:9092"]
        topics => ["elk-zabbix"]
        auto_offset_reset => "latest"
        consumer_threads => 5
        decorate_events => false
        codec => "json"
      }
}
output {
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "elk-zabbix-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
}
```
#2.新增电商ec项目配置文件
```shell
cat >/usr/local/logstash/config/vms.conf<<EOF
###***ec电商系统配置文件***###
input {
     kafka {
        # 注意这里配置的kafka的broker地址不是zk的地址
        bootstrap_servers => ["192.168.34.60:9092"]
        topics => ["ec-nginx35-access","ec-nginx35-error","ec-nginx37-access","ec-nginx37-error","ec-java","ec-mysql"]
        auto_offset_reset => "latest"
        consumer_threads => 5
        decorate_events => false
        codec => "json"
      }
}
filter {
    if [fields][system] == "ec-nginx35-access" {
            json{
                source => "message"
                remove_field => ["message"]
            }
    }
}
output {
    if [fields][system] == "ec-nginx35-access" {
       # stdout { codec => rubydebug }
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "ec-nginx35-access-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "ec-nginx37-access" {
       # stdout { codec => rubydebug }
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "ec-nginx37-access-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "ec-nginx35-error" {
       # stdout { codec => rubydebug }
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "ec-nginx35-error-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "ec-nginx37-error" {
       # stdout { codec => rubydebug }
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "ec-nginx37-error-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "ec-java" {
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "ec-java-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "ec-mysql" {
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "ec-mysql-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
}
EOF
```
#3.新增车管vms项目配置文件
```shell
cat >/usr/local/logstash/config/vms.conf<<EOF
###***vms车管系统配置文件***###
input {
     kafka {
        # 注意这里配置的kafka的broker地址不是zk的地址
        bootstrap_servers => ["192.168.34.60:9092"]
        topics => ["vms-tomcat","vms-logic","vms-push","vms-java","vms-mysql","vms-windows"]
        auto_offset_reset => "latest"
        consumer_threads => 5
        decorate_events => false
        codec => "json"
      }
}
output {
    if [fields][system] == "vms-tomcat" {
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "vms-tomcat-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "vms-logic" {
        #stdout { codec => rubydebug }
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "vms-logic-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "vms-push" {
        #stdout { codec => rubydebug }
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "vms-push-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "vms-java" {
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "vms-java-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "vms-mysql" {
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "vms-mysql-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
    if [fields][system] == "vms-windows" {
        elasticsearch {
            hosts => ["192.168.34.39:9200"]
            index => "vms-windows-%{+YYYY.MM.dd}"
            user => "elastic"
            password => "elk@2018.com"
        }
    }
}
EOF
```
# 五、启动相关服务
```shell
nohup ./logstash-6.2.4/bin/logstash -f config/zabbix.conf >/dev/null 2>&1 &
nohup ./logstash-6.2.4/bin/logstash -f config/ec.conf >/dev/null 2>&1 &
nohup ./logstash-6.2.4/bin/logstash -f config/vms.conf >/dev/null 2>&1 &
```
