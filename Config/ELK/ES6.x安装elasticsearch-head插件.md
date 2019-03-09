```
yum install epel-release -y

cd /opt
wget https://github.com/mobz/elasticsearch-head/archive/master.zip
tar zxvf master.zip

wget https://npm.taobao.org/mirrors/node/latest-v10.x/node-v10.15.3-linux-x64.tar.gz
tar zxvf node-v10.15.3-linux-x64.tar.gz
```
##### vim /etc/profile
```
export NODE_HOME=/opt/node-v10.15.3-linux-x64
export PATH=$PATH:$NODE_HOME/bin
export NODE_PATH=$NODE_HOME/lib/node_modules

source /etc/profile


cd /opt/elasticsearch-head-master    
npm install -g grunt-cli

```
##### 检查是否安装成功:出来版本信息即表示安装成功
```
grunt -version 
```
##### 编辑 /opt/elasticsearch-head-master/Gruntfile.js
```
vim /opt/elasticsearch-head-master/Gruntfile.js
# 修改为
                                options: {
                                        port: 9100,
                                        base: '.',
                                        keepalive: true,
                                        hostname: '0.0.0.0'
                                }
```
##### 修改连接地址：/opt/elasticsearch-head-master /_site/app.js
```
vim /opt/elasticsearch-head-master /_site/app.js
# 修改为
this.base_uri = this.config.base_uri || this.prefs.get("app-base_uri") || "http://192.168.204.128:9200";
```

##### 运行head：
```
npm install 
```
##### 如果 phantomjs 安装失败,请执行下面命令安装
```
npm install phantomjs-prebuilt@2.1.16 --ignore-scripts
```
##### 启动 
```
grunt server >/dev/null 2>&1 &
```
##### 访问
```
http://192.168.204.128:9100
```
