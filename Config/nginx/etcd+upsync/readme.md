```
yum install epel-re* -y
yum install git wget path lrzsz -y
yum install gcc gcc-c++ automake pcre pcre-devel zlip zlib-devel openssl openssl-devel -y

cd /usr/local/src/
```
##### 下载模块
```
#下载 nginx_upstream_check_module (健康检查)
git clone https://github.com/xiaokai-wang/nginx_upstream_check_module.git

#下载 nginx-upsync-module (动态upstream管理)
wget https://github.com/weibocom/nginx-upsync-module/archive/v2.1.0.tar.gz
tar zxvf v2.1.0.tar.gz

#下载openresty
wget https://openresty.org/download/openresty-1.13.6.2.tar.gz
```
##### 编译openresty (nginx)
```
tar zxvf openresty-1.13.6.2.tar.gz
cd openresty-1.13.6.2
patch -p1 < ../nginx_upstream_check_module/check_1.12.1+.patch

#回车
#y

#开始编译
./configure --prefix=/usr/local/openresty --add-module=../nginx-upsync-module-2.1.0 --add-module=../nginx_upstream_check_module --with-pcre-jit --with-stream_ssl_preread_module --with-http_v2_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --with-http_stub_status_module --with-http_realip_module --with-http_addition_module --with-http_auth_request_module --with-http_secure_link_module --with-http_random_index_module --with-http_gzip_static_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-threads --with-stream --with-stream_ssl_module --with-http_ssl_module 

make && make install


#更改nginx配置
mkdir /usr/local/openresty/nginx/conf/servers

vim /usr/local/openresty/nginx/conf/nginx.conf
.......
http {
# upsync 管理upstream (upstream test  对于 upsync中的在 etcd的key: /upstreams/test 来区分不同的 upstream名)
##### 测试 upstream 为 test
upstream test {
    server localhost:12345 ;#无用配置,只是为了启动nginx时候不报错
    #当strong_dependency打开时，每次nginx启动或重新加载时，nginx都会从consul/etcd中提取服务器。
    upsync 127.0.0.1:2379/v2/keys/upstreams/test upsync_timeout=6m upsync_interval=500ms upsync_type=etcd strong_dependency=off;
    #upsync 将更新的upstream配置dump到配置文件(但 不会 reload/restart)
    upsync_dump_path /usr/local/openresty/nginx/conf/servers/servers_test.conf; 
# 健康检查 间隔1s 超时3秒
    check interval=1000 rise=2 fall=2 timeout=1000 type=http default_down=false; #超时1秒
    check_http_send "HEAD / HTTP/1.0\r\n\r\n";
    check_http_expect_alive http_2xx http_3xx;
}

##### 测试 upstream 为 pda
upstream pda {
    server localhost:8005 ;
    upsync 0.0.0.0:2379/v2/keys/upstreams/pda upsync_timeout=6m upsync_interval=500ms upsync_type=etcd strong_dependency=off;
    upsync_dump_path /usr/local/openresty/nginx/conf/servers/servers_pda.conf;

        check interval=1000 rise=2 fall=2 timeout=3000 type=http default_down=false;
        check_http_send "HEAD / HTTP/1.0\r\n\r\n";
        check_http_expect_alive http_2xx http_3xx;


}

#全局 upsync管理upstream
server {
    listen       80;
    server_name  localhost;

    location /upstream_list {
        upstream_show;
    }

            location /status {
                check_status;
                access_log   off;
           }
        # upstream test #
        location /proxy_test {
            proxy_pass http://test;
        }
        # upstream pda #
        location /proxy_pda {
            proxy_pass http://pda;
        }
    }
}


#定义一个 servers_test.conf 默认
cat>/usr/local/openresty/nginx/conf/servers/servers_test.conf<<EOF
server 127.0.0.1:8001 weight=1 max_fails=2 fail_timeout=10s;
server 127.0.0.1:8002 weight=1 max_fails=2 fail_timeout=10s;
EOF

```

##### etcd 测试 增加数据 (/keys/upstreams/test/ 和 upsync 匹配), 目前还不支持 backup 写法
```
#机器上线
curl -X PUT -d value="{\"weight\":1, \"max_fails\":2, \"fail_timeout\":30, \"down\":1}" http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:666
curl -X PUT -d value="{\"weight\":1, \"max_fails\":2, \"fail_timeout\":10}" http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:777
curl -X PUT -d value="{\"weight\":1, \"max_fails\":2, \"fail_timeout\":30}" http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:888
curl -X PUT -d value="{\"weight\":1, \"max_fails\":2, \"fail_timeout\":30}" http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:999


#机器下线
curl -X DELETE http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:666
curl -X DELETE http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:777
curl -X DELETE http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:888
curl -X DELETE http://127.0.0.1:2379/v2/keys/upstreams/test/127.0.0.1:999
```

```
#查看 etcd中的 key/value
curl 139.199.187.148:2379/v2/keys/upstreams/test

#查看 upsync 的upstream
#所有的upstream
curl http://127.0.0.1/upstream_list
# upstream为 test的
curl http://127.0.0.1/upstream_list?test
```


