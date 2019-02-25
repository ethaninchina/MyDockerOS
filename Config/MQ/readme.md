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
批量清除消息队列
<br>
```
for queuename in `rabbitmqctl list_queues -p / |awk '{if($NF>0) print$0}'|grep -v 'Listing queues'| awk '{print $1}'`
do 
  rabbitmqctl purge_queue -p / $queuename 
done
```
