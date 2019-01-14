$ ssh-keygen -t rsa

##### 一路回车即可

##### 然后在将生成的公钥复制到机器100上的~/.ssh/authorized_keys中，使用如下命令： 


$ ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.0.0.101



##### 最后，测试免密码登录：

$ ssh root@10.0.0.100
