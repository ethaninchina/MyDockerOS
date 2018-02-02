import requests
import json
import sys

# 定义IP地址 为脚本后的第一个参数 如 ip.py 202.68.199.219
ip = sys.argv[1]

ipurl = 'http://opendata.baidu.com/api.php?query='+ip+'&co=&resource_id=6006'

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.108 Safari/537.36'}

#创建请求
req = requests.get(url=ipurl,headers=headers)

#结果解码 gb2312
result = req.content.decode('gb2312')

#解码后的结果是字符串，需要json转换下
oneresult = json.loads(result)

#打印结果
tworesult = oneresult['data']

#去掉中括号 获取{} 里面的内容
threeresult = tworesult[0]

#打印IP归属地
print (threeresult['location'])
###


[root@izuf6ai63g73sy058dl8gwz ~]# ./a.py 152.47.3.74
美国
[root@izuf6ai63g73sy058dl8gwz ~]# ./a.py 58.47.3.74
湖南省常德市 电信
