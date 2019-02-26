
monitor 命令可以让我们清楚的看到 redis 是怎么处理每个请求的，这对于调试阶段非常方便。
<br>
```
#实时监控
echo "MONITOR"  |  redis-cli 

#输出日志 (带密码访问 -a )
echo "MONITOR"  |  redis-cli -a 123456 > redis_key.log
```
