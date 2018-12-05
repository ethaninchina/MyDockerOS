### liunx中查询第8列 不等于某一个值 用awk命令写
```
tail -f /datas/soft/nginxlog/logs/pda.access.log |awk '$8 != 200{print $0}'


# 日志格式 
1.2.3.4 - [05/Dec/2013:13:06:11 +0800] "POST /abcde.asmx HTTP/1.1" 502 0 "-" qqee/3.3.0 - 60.000  - - -

```
