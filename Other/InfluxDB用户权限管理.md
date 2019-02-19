##### 创建数据库
```
CREATE DATABASE "testDB"
```
##### 显示数据库
```
show databases
```

##### 显示用户
```
SHOW USERS
```

##### 创建普通用户
```
CREATE USER "username" WITH PASSWORD 'password'
```

普通权限授权, 赋予 user用户 数据库mydb 权限 (非admin权限)
##### GRANT [READ,WRITE,ALL] ON TO 
```
grant all on mydb to user
```

##### 为一个已有用户授权
```
GRANT [READ,WRITE,ALL] ON <database_name> TO <username>
```

##### 创建[管理员]权限的用户
```
CREATE USER "username" WITH PASSWORD 'password' WITH ALL PRIVILEGES
```
##### 删除用户
```
DROP USER "supaminin"
```

##### 取消用户权限
```
REVOKE ALL PRIVILEGES FROM <username>
```

##### 重设密码
```
SET PASSWORD FOR <username> = '<password>'
```


##### 使用密码访问
```
influx
username: admin
password: 123456 
```

##### InfluxDb数据保留策略 操作
InfluxDB本身不提供数据的删除操作, 因此用来控制数据量的方式就是定义数据保留策略.
因此定义数据保留策略的目的是让InfluxDB能够知道可以丢弃哪些数据, 从而更高效的处理数据.
```
show retention policies on telegraf
```
##### 输出结果为如下
```
name	duration	shardGroupDuration	replicaN	default
autogen	  "0s"	    "168h0m0s"	            1	    true
```
##### 可以看到telegraf只有一个策略, 个字段的含义如下:
```
name 名称, 此示例名称为 autogen
duration 持续时间, 0代表无限制
shardGroupDuration shardGroup的存储时间, shardGroup是InfluxDB的一个基本存储结构, 应该大于这个时间的数据在查询效率上应该有所降低.
replicaN 全称是REPLICATION, 副本个数
default 是否是默认策略
```
#####新建策略
```
CREATE RETENTION POLICY "2_hours" ON "telegraf" DURATION 2h REPLICATION 1 DEFAULT
```
通过上面的语句可以添加策略, 本例在telegraf库添加了一个2小时的策略, 名字叫做2_hours,duration为2小时, 副本为1, 设置为默认策略.

因为名为default的策略不再是默认策略, 因此, 在查询使用default策略的表时要显示的加上策略名"defalut"

#####修改策略
ALTER RETENTION POLICY "autogen" ON "telegraf" DURATION 365d REPLICATION 1 DEFAULT
##### 在telegraf库修改策略 DEFAULT 为4小时

##### 删除策略 
```
drop retention POLICY "4_hours" ON "telegraf"
```
##### 在telegraf库删除  策略 


##### 修改 telegraf 库中名称为 autogen的 的 存储时间,默认为0 不过期,这里修改为365天,副本为1 ,默认default策略
##### 修改库名 telegraf 即可 执行
```
ALTER RETENTION POLICY "autogen" ON "telegraf" DURATION 365d REPLICATION 1 DEFAULT
```

##### 查看 telegraf库 修改是否生效
```
show retention policies on telegraf
```


##### influxdb 用户
```
CREATE USER "supaminin" WITH PASSWORD 'suppass' WITH ALL PRIVILEGES
```

##### 数据库备份
```
influxd backup -database pda /data/backup/influxdb/pda_$(date -d "yesterday" +"%Y%m%d")/
```

##### 备份所有库 v1.6 才支持全量备份
```
influxd backup -portable /data/backup/influxdb/
```

##### 恢复数据库
```
influxd restore -database pda -datadir /data/influxdb/data /data/backup/influxdb/pda
```
