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
