### nginx 过滤问号、关键字等
```
# 请求参数中带version=1.1 或者 version=2.0 之类的的全部 拒绝(刷接口的比较多)
http://api.ooxx.com/api/?version=3.0&model=public&act=Sms&op=sendSmsCodeFastCache&method=sms_register&mobile=18802676296

  if ( $query_string ~* ^(.*)version=(1|2).\d&model=public&act=Sms&op=sendSmsCodeFastCache&method=sms_register&mobile=(.*)$ ){
        return 403;
       }




	   
# 带有问号的目标地址
www.ankang06.com/user/index/?uid=1118 重定向到  http://1118.blog.ankang06.com

 if ($query_string ~* uid=([0-9]*)$)
   {
    rewrite ^/user/index/(.*)$  http://$id.blog.ankang06.com/? permanent;
   }
	   
	   
	    
# 禁止spam字段
# set $block_spam 0;
if ($query_string ~ "\b(ultram|unicauca|valium|viagra|vicodin|xanax|ypxaieo)\b") {
set $block_spam 1;
}
if ($query_string ~ "\b(erections|hoodia|huronriveracres|impotence|levitra|libido)\b") {
set $block_spam 1;
}
if ($query_string ~ "\b(ambien|blue\spill|cialis|cocaine|ejaculation|erectile)\b") {
set $block_spam 1;
}
if ($query_string ~ "\b(lipitor|phentermin|pro[sz]ac|sandyauer|tramadol|troyhamby)\b") {
set $block_spam 1;
}
if ($block_spam = 1) {
return 444;
}
```
