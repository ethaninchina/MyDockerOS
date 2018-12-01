```
#配置redis主从
#主reids 配置文件,复制一份redis的配置文件：
cd /usr/local/redis/redis-3.2.12
mkdir –p 6379/data 6380/data
cp redis.conf /usr/local/redis/redis-3.2.12/6379/data/redis-6379.conf
cp redis.conf /usr/local/redis/redis-3.2.12/6379/data/redis-6380.conf

#redis主配置
vim /usr/local/redis/redis-3.2.12/6379/data/redis-6379.conf

daemonize no
　修改为：
daemonize yes  (后台程序方式运行)

pidfile /var/run/redis_6379.pid
　修改为：
pidfile /usr/local/redis/redis-3.2.12/6379/redis_6379.pid

#设置请求密码
requirepass 12345

#设置数据文件路径
dir /usr/local/redis/redis-3.2.12/6379/data


#redis从配置
vim /usr/local/redis/redis-3.2.12/6379/data/redis-6380.conf

port 6379
    改为:
port 6380

pidfile 改为 /usr/local/redis/redis-3.2.12/6380/redis_6380.pid

#注释/删除 requirepass 12345
#设置数据文件路径
dir /usr/local/redis/redis-3.2.12/6380/data

#添加从属关系
slaveof 127.0.0.1 6379

#添加主redis访问密码
masterauth system

#启动主从redis
/usr/local/redis/redis-3.2.12/src/redis-server /usr/local/redis/redis-3.2.12/6379/redis-6379.conf
/usr/local/redis/redis-3.2.12/src/redis-server /usr/local/redis/redis-3.2.12/6380/redis-6380.conf

#在redis主中存储数据
cd /usr/local/redis/redis-3.2.12/src
./redis-cli -h 127.0.0.1 -p 6379 
auth 12345
set foo test

#ctrl+c退出
#在从redis中取数据

./redis-cli -h 127.0.0.1 -p 6380
get foo
```
