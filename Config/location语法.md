### nginx location语法
```
基本语法：location [=|~|~*|^~] /uri/ { … }

= 严格匹配。如果这个查询匹配，那么将停止搜索并立即处理此请求。
~ 为区分大小写匹配(可用正则表达式)
!~为区分大小写不匹配
~* 为不区分大小写匹配(可用正则表达式)
!~*为不区分大小写不匹配
^~ 如果把这个前缀用于一个常规字符串,那么告诉nginx 如果路径匹配那么不测试正则表达式。

 

### 示例 ###

location = / {
 # 只匹配 / 查询。
}

location / {
 # 匹配任何查询，因为所有请求都以 / 开头。但是正则表达式规则和长的块规则将被优先和查询匹配。
}

location ^~ /images/ {
 # 匹配任何以 /images/ 开头的任何查询并且停止搜索。任何正则表达式将不会被测试。
}

location ~*.(gif|jpg|jpeg)$ {
 # 匹配任何以 gif、jpg 或 jpeg 结尾的请求。
}

location ~*.(gif|jpg|swf)$ {
  valid_referers none blocked aa.abc.cn bb.abc.cn;
  if ($invalid_referer) {
    #防盗链
    rewrite ^/ http://$host/logo.png;
  }
}
```
