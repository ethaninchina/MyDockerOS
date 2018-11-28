```
# try_files指令 是按顺序检测文件的存在性,并且返回第一个找到文件的内容
# 如果第一个找不到就会自动找第二个,依次查找.其实现的是内部跳转
# 1 ########## 
 location /abc {
       try_files /4.html /5.html @qwe;     
# 检测文件4.html 和 5.html,如果存在正常显示,不存在就去查找@qwe值
  }

   location @qwe  {
      rewrite ^/(.*)$   http://www.baidu.com;     
# 跳转到百度页面
   }
   
   
# 2 ##########   
   error_page 404 = @fallback;
location @fallback {
    proxy_pass http://www.linuxhub.org;
}
# 如果URI不存在，则把请求代理到www.linuxhub.org上去做个弥补



# 3 ########## 
location / {
   try_files $uri $uri/ /index.php @linuxhub;
# 请求url ,如果不存在去查找  @linuxhub
}
location @linuxhub {
   return 504;
   #proxy_pass http://www.baidu.com;
}


# wordpress 缓存命中
try_files /wp-content/cache/supercache/$http_host/$cache_uri/index.html $uri $uri/ /index.php?$args ;
```
