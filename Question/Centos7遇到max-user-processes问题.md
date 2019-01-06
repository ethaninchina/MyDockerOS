# Centos7遇到max user processes问题

### 修改文件：/etc/security/limits.conf 
```
[****@***** ~]$ cat /etc/security/limits.conf
* soft nofile 100001
* hard nofile 100002
root soft nofile 100001
root hard nofile 100002
```

### 修改文件：/etc/security/limits.d/20-nproc.conf
```
[****@*****~]$ cat /etc/security/limits.d/20-nproc.conf  
*          soft    nproc     65535
root       soft    nproc     unlimited 
```

### 重启系统后发现，ulimit -u一直无法突破15084，虽然比原来默认的4096是大了几倍，但并不是我们上面配置文件中的数值啊。
```
[****@***** ~]$ ulimit -a 
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 7403
max locked memory       (kbytes, -l) 64
max memory size         (kbytes, -m) unlimited
open files                      (-n) 100001
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 4096
virtual memory          (kbytes, -v) unlimited
file locks                      (-x) unlimited
```
### 编辑一个配置文件：/etc/systemd/system.conf
```
sed -i '/^#DefaultLimitNOFILE=/aDefaultLimitNOFILE=65535' /etc/systemd/system.conf 
sed -i '/^#DefaultLimitNPROC=/aDefaultLimitNPROC=65535' /etc/systemd/system.conf 
```
### 检查
```
[root@*********** ~]# egrep -v "^#"  /etc/systemd/system.conf  
[Manager] 
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535 
```
### 此时重启就会发现max user processes 变成了我们修改的 65535 了
```
[root@*********** ~]# ulimit -a
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 7403
max locked memory       (kbytes, -l) 64
max memory size         (kbytes, -m) unlimited
open files                      (-n) 100001
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 65535
virtual memory          (kbytes, -v) unlimited
file locks                      (-x) unlimited
```
