###  docker 打包镜像

### 查看镜像，然后通过docker save命令将镜像保存为文件(归档文件)
```
[root@localhost ~]# docker save -o es.tar docker.io/elasticsearch:2.3.4    #-o 后面的es.tar是归档文件的名字
[root@localhost ~]# ls -l es.tar 
-rw------- 1 root root 352998912 Dec  7 04:30 es.tar.gz
```
### 将多个镜像保存为tar文件
```
[root@localhost ~]# docker save -o es.tar docker.io/elasticsearch:2.3.4 es_ik:5.4.3

[root@localhost ~]# ls -l es.tar 
-rw------- 1 root root 694486528 Dec  7 04:34 es.tar.gz

```
##### 导入保存的镜像(为了测试，导入之前先删除，如果在其他机器导入则没有删除的动作)
##### 删除[root@localhost ~]# docker rmi -f docker.io/elasticsearch:2.3.4

### 导入镜像 
```
[root@localhost ~]# docker load --input es.tar.gz 
```
