
## etcd+confd 动态管理 nginx upstream 集群
#### 1, etcd启动 (集群)
###### 三台机器跑etcd集群
```
10.0.0.101  etcd1
10.0.0.108  etcd2
10.0.0.109  etcd3
```
##### 安装 etcd (版本)
```
yum install etcd -y
mkdir /etcd_data && chown etcd.etcd /etcd_data/
```
##### 若使用v3版本的 etcd
```
echo "export ETCDCTL_API=3" >> /etc/profile && . /etc/profile
```

##### etcd1 执行 (10.0.0.101)
```
cat>/etc/etcd/etcd.conf<<EOF
# [member]
# 节点名称
ETCD_NAME=etcd1
# 数据存放位置
ETCD_DATA_DIR="/etcd_data"
# 监听其他 Etcd 实例的地址(修改为本机地址如etcd2)
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
# 监听客户端地址(修改为本机地址如etcd2)
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
#[cluster]
# 通知其他 Etcd 实例地址(修改为本机地址如etcd2)
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.0.101:2380"
# 初始化集群内节点地址
ETCD_INITIAL_CLUSTER="etcd1=http://10.0.0.101:2380,etcd2=http://10.0.0.108:2380,etcd3=http://10.0.0.109:2380"
# 初始化集群状态，new 表示新建
ETCD_INITIAL_CLUSTER_STATE="new"
# 初始化集群 token
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
# 通知 客户端地址(修改为本机地址如etcd2)
ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.101:2379,http://10.0.0.101:4001"
EOF
```
##### etcd2 执行 (10.0.0.108)
```
cat>/etc/etcd/etcd.conf<<EOF
# [member]
# 节点名称
ETCD_NAME=etcd2
# 数据存放位置
ETCD_DATA_DIR="/etcd_data"
# 监听其他 Etcd 实例的地址(修改为本机地址如etcd2)
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
# 监听客户端地址(修改为本机地址如etcd2)
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
#[cluster]
# 通知其他 Etcd 实例地址(修改为本机地址如etcd2)
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.0.108:2380"
# 初始化集群内节点地址
ETCD_INITIAL_CLUSTER="etcd1=http://10.0.0.101:2380,etcd2=http://10.0.0.108:2380,etcd3=http://10.0.0.109:2380"
# 初始化集群状态，new 表示新建
ETCD_INITIAL_CLUSTER_STATE="new"
# 初始化集群 token
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
# 通知 客户端地址(修改为本机地址)
ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.108:2379,http://10.0.0.108:4001"
EOF
```
##### etcd3 执行 (10.0.0.109)
```
cat>/etc/etcd/etcd.conf<<EOF
# [member]
# 节点名称
ETCD_NAME=etcd3
# 数据存放位置
ETCD_DATA_DIR="/etcd_data"
# 监听其他 Etcd 实例的地址(修改为本机地址如etcd2)
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
# 监听客户端地址(修改为本机地址)
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
#[cluster]
# 通知其他 Etcd 实例地址(修改为本机地址如etcd2)
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.0.109:2380"
# 初始化集群内节点地址
ETCD_INITIAL_CLUSTER="etcd1=http://10.0.0.101:2380,etcd2=http://10.0.0.108:2380,etcd3=http://10.0.0.109:2380"
# 初始化集群状态，new 表示新建
ETCD_INITIAL_CLUSTER_STATE="new"
# 初始化集群 token
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
# 通知 客户端地址(修改为本机地)
ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.109:2379,http://10.0.0.109:4001"
EOF
```
##### 开机启动,启动etcd
```
systemctl enable etcd
systemctl restart etcd
systemctl status etcd 
```
##### 查看etcd集群 (etcdctl member list)
```
[root@data ~]# etcdctl member list
2ba4256c28888332: name=etcd3 peerURLs=http://10.0.0.109:2380 clientURLs=http://10.0.0.109:2379,http://10.0.0.109:4001 isLeader=false
ae5f0a864e4bd403: name=etcd2 peerURLs=http://10.0.0.108:2380 clientURLs=http://10.0.0.108:2379,http://10.0.0.108:4001 isLeader=true
bf273b606bebc955: name=etcd1 peerURLs=http://10.0.0.101:2380 clientURLs=http://10.0.0.101:2379,http://10.0.0.101:4001 isLeader=false
```
##### 查看集群健康状态 (etcdctl cluster-health)
```
[root@lvs2 ~]# etcdctl cluster-health 
member 2ba4256c28888332 is healthy: got healthy result from http://10.0.0.109:2379
member ae5f0a864e4bd403 is healthy: got healthy result from http://10.0.0.108:2379
member bf273b606bebc955 is healthy: got healthy result from http://10.0.0.101:2379
cluster is healthy

```

```
#设置key (集群中任何一台机器上执行,数据即同步集群)
etcdctl set /nginx/servername 666.com
etcdctl set /nginx/upstream/server1 10.0.0.111
etcdctl set /nginx/upstream/server2 10.0.0.113

#查看key (集群中任何一台机器上执行,数据即同步集群)
etcdctl get /nginx/servername
etcdctl get /nginx/upstream/server1
etcdctl get /nginx/upstream/server2

#删除key (集群中任何一台机器上执行,数据即同步集群)
etcdctl rm /nginx/servername 
etcdctl rm /nginx/upstream/server1
etcdctl rm /nginx/upstream/server2
```

#### 2, 在安装nginx的机器  安装confd
##### nginx端安装 confd , nginx 
###### 安装nginx
```
yum install yum-utils -y
curl -o /etc/yum.repos.d/nginx.repo https://raw.githubusercontent.com/station19/MyDockerOS/master/repo/nginx.repo
yum-config-manager --enable nginx-mainline
yum install nginx -y
```
###### 安装confd
```
curl -o confd "https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64"
chmod +x confd
mv confd /usr/bin

mkdir -p /etc/confd/{conf.d,templates}
```
```
[root@nginx confd]# tree
.
├── conf.d
│   └── test.conf.toml
└── templates
    └── test.conf.tmpl
```
###### toml 定义nginx配置路径
```
cat>conf.d/test.conf.toml<<EOF
[template]
src = "test.conf.tmpl"
dest = "/etc/nginx/vhost/test.conf"
keys = [
    "/nginx",
]
check_cmd = "/usr/sbin/nginx -t"
reload_cmd = "/usr/sbin/nginx -s reload"
EOF

cat>templates/test.conf.tmpl<<EOF
upstream {{getv "/nginx/servername"}} {
{{range getvs "/nginx/upstream/*"}}
	server {{.}};
{{end}}
}

server {
    server_name         {{getv "/nginx/servername"}};
    location / {
        proxy_pass        http://{{getv "/nginx/servername"}};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect    off;
    }
} 
EOF
```


###### confd启动 (监听etcd的三个节点)
```
confd -watch -backend etcd -node http://10.0.0.101:2379 -node http://10.0.0.108:2379 -node http://10.0.0.109:2379

# 或者设置 10秒更新检查一次 (监听etcd的三个节点)
confd -interval=10 -backend etcd -node http://10.0.0.101:2379 -node http://10.0.0.108:2379 -node http://10.0.0.109:2379 
```

###### nginx机器查看效果 
```
[root@nginx vhost]# cat /etc/nginx/vhost/test.conf 
upstream 666.com {

server 10.0.0.111;

server 10.0.0.113;

}

server {
    server_name         666.com;
    location / {
        proxy_pass        http://666.com;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect    off;
    }
} 
```

 


