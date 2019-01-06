# Centos7遇到max user processes问题

### 修改文件：/etc/security/limits.conf 
```
[****@***** ~]$ tail -2 /etc/security/limits.conf  
* soft nofile 655350 
* hard nofile 655350 
```

### 修改文件：/etc/security/limits.d/20-nproc.conf
```
[****@*****~]$ tail -2 /etc/security/limits.d/20-nproc.conf  
*          soft    nproc     655350 
root       soft    nproc     unlimited 
```

### 重启系统后发现，ulimit -u一直无法突破15084，虽然比原来默认的4096是大了几倍，但并不是我们上面配置文件中的数值啊。
```
[****@***** ~]$ ulimit -a 
core file size          (blocks, -c) 0 
data seg size           (kbytes, -d) unlimited 
scheduling priority             (-e) 0 
file size               (blocks, -f) unlimited 
pending signals                 (-i) 15084 
max locked memory       (kbytes, -l) 64 
max memory size         (kbytes, -m) unlimited 
open files                      (-n) 655350 
pipe size            (512 bytes, -p) 8 
POSIX message queues     (bytes, -q) 819200 
real-time priority              (-r) 0 
stack size              (kbytes, -s) 8192 
cpu time               (seconds, -t) unlimited 
max user processes              (-u) 15084 
virtual memory          (kbytes, -v) unlimited 
file locks                      (-x) unlimite 
```
### 编辑一个配置文件：/etc/systemd/system.conf
```
sed -i '/^#DefaultLimitNOFILE=/aDefaultLimitNOFILE=655350' /etc/systemd/system.conf 
sed -i '/^#DefaultLimitNPROC=/aDefaultLimitNPROC=655350' /etc/systemd/system.conf 
```
### 检查
```
[root@*********** ~]# egrep -v "^#"  /etc/systemd/system.conf  
[Manager] 
DefaultLimitNOFILE=655350 
DefaultLimitNPROC=655350 
```
### 此时重启就会发现max user processes 变成了我们修改的655350了
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
