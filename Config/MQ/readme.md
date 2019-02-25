### rabbitmq 集群搭建 (https://github.com/station19/MyDockerOS/blob/master/Config/MQ/rabbitmq%2Bhaproxy.md)
rabbitmq 集群模式下 出现网络分区后 手动解决方案 (建议)
<br>
```
官方自带解决方法: 
1,) ignore #默认忽略,即手动处理
2,) pause_minority 
3,) autoheal 
```
手动解决方案:
<br>
```
1.）停止其他分区中的节点，然后重新启动这些节点。最后重启信任分区中的节点，以去除告警。 
2.） 关闭整个集群的节点，然后再启动每一个节点，这里需确保你启动的第一个节点在你所信任的分区之中。
```
以下2种方法任选一种 重启 即可
<br>
```
1,) 
rabbimqctl stop
rabbitmq-server -detached
 或者
2,) 建议此方法
rabbitmqctl stop_app 
rabbitmqctl start_app
```

手动同步队列
<br>
```
1,) 查看哪些slave已经同步好了  
rabbitmqctl list_queues $queuename slave_pids synchronised_slave_pids

2,) 手动同步 (默认手动同步) 
rabbitmqctl sync_queue $queuename

3,) 取消自动同步： 
rabbitmqctl cancel_sync_queue $queuename 
```

查看有消息的队列
<br>
```
rabbitmqctl list_queues -p / |awk '{if($NF>0) print$0}'|grep -v 'Listing queues'
```
批量清除消息队列消息
<br>
```
for queuename in `rabbitmqctl list_queues -p / |awk '{if($NF>0) print$0}'|grep -v 'Listing queues'| awk '{print $1}'`
do 
  rabbitmqctl purge_queue -p / $queuename 
done
```
ha-mode   ha-params      行为
<br>
```
all                      queue被mirror到cluster中所有节点。
                         cluster中新添加节点，queue也会被mirror到该节点。

exactly   count          queue被mirror到指定数目的节点,众多集群中的随机2台机器
                         count大于cluster中节点数则queue被mirror到所有节点。
                         若count小于cluster中节点数，在包含mirror的某节点down后不会在其他节点建新的mirror（为避免cluster中queue migrating）

nodes     node names     queue被mirror到指定名字的节点。
                         若任一名称在cluster中不存在并不会引发错误。
                         若指定的任何节点在queue声明时都不在线则queue在被连接到的节点创建。
```

设置策略方法
<br>
```
-p / :设置vhost信息。
--priority 10 :设置优先级。高数字会优先处理
--apply-to queue :作用对象。queue、exchanges，all


#将“aa”开头的queue mirror到cluster中所有节点 (默认优先级)
rabbitmqctl set_policy ha-all "^aa" '{"ha-mode":"all"}'

#将所有的queue mirror到cluster中两个节点，且自动同步 (默认优先级)
rabbitmqctl set_policy ha-all "^" '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'

#将“bb”开头队列 同步设置为自动同步到指定节点 (默认优先级)
rabbitmqctl set_policy ha-node "^bb" '{"ha-mode":"nodes","ha-params":["rabbit@node1", "rabbit@node2"],"ha-sync-mode":"automatic"}'

#将“ff”开头的queue mirror到cluster中两个节点，且自动同步 (默认优先级)
rabbitmqctl set_policy ha-two "^ff" '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'



#设置优先处理 --priority 设置优先级,高数字会优先处理 (自定义优先级)
rabbitmqctl set_policy ha-node "^bb" --priority 5 '{"ha-mode":"nodes","ha-params":["rabbit@node1", "rabbit@node2"],"ha-sync-mode":"automatic"}'

#将所有的queue mirror到cluster中两个节点，且自动同步 --priority 设置优先级,高数字会优先处理 自定义优先级
rabbitmqctl set_policy ha-all "^" --priority 10 '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'
```
