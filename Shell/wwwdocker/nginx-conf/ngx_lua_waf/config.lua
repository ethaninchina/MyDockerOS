--规则存放目录 (git下来后的目录存放地址)
RulePath = "/opt/openresty/nginx/conf/ngx_lua_waf/wafconf" 
--是否开启攻击信息记录，需要配置logdir
attacklog = "on"
--log存储目录，该目录需要用户自己新建，切需要nginx用户的可写权限
logdir = "/data/log/hack/"
--是否拦截url访问
UrlDeny="on"
--是否拦截后重定向
Redirect="on"
--是否拦截cookie攻击
CookieMatch="on"
--是否拦截post攻击
postMatch="on" 
--是否开启URL白名单
whiteModule="on" 
--填写不允许上传文件后缀类型
black_fileExt={"php","jsp","exe","html","sh","py"}
--UA(user-agent)白名单，多个ip用逗号分隔--针对自定义user-agent设置
uaWhitelist={"WYZ_only_UA"}
--ip白名单，多个ip用逗号分隔
ipWhitelist={"127.0.0.1","172.104.119.50","192.168.188.173","58.250.164.39"}
--ip黑名单，多个ip用逗号分隔
ipBlocklist={"1.0.0.1","2.0.0.2"}
--是否开启拦截cc攻击(需要nginx.conf的http段增加lua_shared_dict limit 10m;)
CCDeny="on"
--设置cc攻击频率，单位为秒.
--默认1分钟同一个IP只能请求同一个地址60次，也是就每分钟60次，一秒一次
CCrate="60/60"
html=[[
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>网站警告</title>
<style>
p {
	line-height:20px;
}
ul{ list-style-type:none;}
li{ list-style-type:none;}
</style>
</head>

<body style=" padding:0; margin:0; font:14px/1.5 Microsoft Yahei, 宋体,sans-serif; color:#555;">

 <div style="margin: 0 auto; width:1000px; padding-top:70px; overflow:hidden;">
  
  
  <div style="width:600px; float:left;">
    <div style=" height:40px; line-height:40px; color:#fff; font-size:16px; overflow:hidden; background:#6bb3f6; padding-left:20px;">网站防火墙 </div>
    <div style="border:1px dashed #cdcece; border-top:none; font-size:14px; background:#fff; color:#555; line-height:24px; height:220px; padding:20px 20px 0 20px; overflow-y:auto;background:#f3f7f9;">
      <p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;"><span style=" font-weight:600; color:#fc4f03;">您的请求带有不合法参数，已被网站管理员设置拦截！</span></p>
<p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">可能原因：您提交的内容包含危险的攻击请求</p>
<p style=" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:1; text-indent:0px;">如何解决：</p>
<ul style="margin-top: 0px; margin-bottom: 0px; margin-left: 0px; margin-right: 0px; -qt-list-indent: 1;"><li style=" margin-top:12px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">1）检查提交内容；</li>
<li style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">2）禁止敏感参数提交，请勿越权,谢谢；</li>
<li style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">3）网站仅有访客权限，请联系网站管理员；</li></ul>
    </div>
  </div>
</div>
</body></html>
]]
