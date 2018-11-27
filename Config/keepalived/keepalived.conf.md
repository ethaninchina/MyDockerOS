### 安装keepalived
 ```
wget http://www.keepalived.org/software/keepalived-2.0.10.tar.gz
tar zxvf keepalived-2.0.10.tar.gz
cd keepalived-2.0.10

./configure --prefix=/usr/local/keepalived 

# IPV6报错
#*** WARNING - this build will not support IPVS with IPv6. Please install libnl/libnl-3 dev libraries to support IPv6 with IPVS.
#yum -y install libnl libnl-devel 

make && make install

cp /usr/local/keepalived/sbin/keepalived /usr/sbin/



#设置开机启动
systemctl enable keepalived.service

#启动keepalived
systemctl start keepalived.service

#ps -ef|grep keepalived
```

### keepalived配置  /etc/keepalived/keepalived.conf  , 此配置在关闭selinux和 iptables情况下进行
```
! Configuration File for keepalived

global_defs {
   router_id ZB_PDA_NGINX1 #主备需不一样,备机ZB_PDA_NGINX2
}

vrrp_script chk_nginx { #定义脚本模块名称 chk_nginx
    script "/etc/keepalived/nginx_check.sh"
    interval 2 #检测间隔时间
    weight -30 #weight 的绝对值必须 大于 master 和 Backup 的 priority 之差
    #weight为正数
    #如果脚本执行结果为0,,Master:weight+priority>Backup:weight+priority(不切换)
    #如果脚本执行结果不为0,Master:priority<Backup:priority+weight(切换)
    #weight为负数
    #如果脚本执行结果为0,,Master:priority>Backup:priority(不切换)
    #如果脚本执行结果不为0,Master:priority+weight<Backup:priority(切换)
    #一般来说,weight的绝对值要大于Master和Backup的priority之差
    fall 3 #失败3次确认失败
    rise 2 #成功2次确认成功
}

vrrp_instance VI_221 {
    state MASTER #主为master 备机为 BACKUP
    interface eth0 #绑定网络物理接口eth0
    virtual_router_id 51 #主备ID需要一样
    mcast_src_ip 172.168.10.221 # 本机 IP 地址
    priority 100 #节点优先级，值范围 0-254，MASTER 要比 BACKUP 高
    advert_int 1 #组播信息发送间隔，两个节点设置必须一样，默认 1s
    authentication {  #认证模块,主备一样
        auth_type PASS
        auth_pass 4008 #密码最好是数字,不超过8位,不然有可能出现双VIP问题
    }


    track_script { #脚本执行模块
        chk_nginx
    } 

    virtual_ipaddress {  #虚拟VIP 主备一样,可以设置多个,换行填写即可
         172.168.10.223
    }
}


########## keepalived backup ##########
[root@zb-pda-nginx02 conf]# cat /etc/keepalived/keepalived.conf 
! Configuration File for keepalived

global_defs {
   router_id ZB_PDA_NGINX2
}

vrrp_script chk_nginx {
    script "/etc/keepalived/nginx_check.sh"
    interval 2
    weight -30
    fall 3
    rise 2
}

vrrp_instance VI_221 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    mcast_src_ip 172.168.10.222
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 4008
    }

    track_script {
        chk_nginx
    }
 
    virtual_ipaddress {
         172.168.10.223
    }
}
```
### keepalived检测脚本 /etc/keepalived/nginx_check.sh
```
#!/bin/bash
# /etc/keepalived/nginx_check.sh
counter=$(ps -C nginx --no-heading|wc -l)
if [ "${counter}" = "0" ]; then
    /usr/local/openresty/nginx/sbin/nginx
    sleep 2
    counter=$(ps -C nginx --no-heading|wc -l)
    if [ "${counter}" = "0" ]; then
        /bin/systemctl stop keepalived.service
    fi
fi
```
```
##################################################################
#设置keepalived开机启动
# systemctl enable keepalived.service 

#查看服务启动情况 
# /bin/systemctl status keepalived.service


# 停止/启动 keepalived服务 
# /bin/systemctl stop keepalived.service
# /bin/systemctl start keepalived.service


# #杀死 nginx 进程
# kill -9 $(ps -C nginx --no-heading|awk '{print $1}')

# #启动nginx
# /usr/local/openresty/nginx/sbin/nginx
```
