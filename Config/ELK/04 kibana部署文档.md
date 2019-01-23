# 一、下载kibana
官网地址：https://www.elastic.co<br>
下载地址：https://www.elastic.co/downloads/past-releases/kibana-6-2-4<br>
学习地址：https://www.elastic.co/guide/en/kibana/6.2/release-notes-6.2.4.html<br>
```shell
cd /usr/local/src/
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.2.4-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/packs/x-pack/x-pack-6.2.4.zip
tar -xf kibana-6.2.4-linux-x86_64.tar.gz
mv kibana-6.2.4-linux-x86_64 ..
ln -s kibana-6.2.4-linux-x86_64/ kibana
```

# 二、添加执行用户
```shell
useradd app
chown -R app.app kibana*
```

# 三、编辑配置文件
```shell
cat >/usr/local/kibana/config/kibana.yml<<EOF
server.port: 5601
server.host: "192.168.34.65"
server.maxPayloadBytes: 1048576
server.name: "elk-elk-kibana"
elasticsearch.url: "http://192.168.34.71:9200"
kibana.index: ".kibana"
elasticsearch.username: "kibana"
elasticsearch.password: "kb@2018.com"
elasticsearch.requestTimeout: 30000
elasticsearch.customHeaders: {}
pid.file: /var/run/kibana.pid
ops.interval: 5000
i18n.defaultLocale: "en"
EOF
```

# 四、配置环境变量
```shell
echo 'export PATH=$PATH:/usr/local/kibana/bin' >> /etc/profile
source /etc/profile
```

# 五、安装插件x-back
```shell
cd /usr/local/kibana/bin/
kibana-plugin install /usr/local/src/x-pack-6.2.4.zip
```

# 六、汉化kibana
```shell
cd /usr/local/src/
yum -y install git
git clone https://github.com/anbai-inc/Kibana_Hanization kibana-zh
cd kibana-zh/
python main.py /usr/local/kibana/
```

# 七、启动服务
```shell
nohup ./kibana > /dev/null 2>&1 &
```
