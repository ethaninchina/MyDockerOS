# 使用ansible-playbook 更新后端nginx配置

nginx_conf/ 目录为nginx配置存放 目录

file/ 目录为项目存放目录

vars_nginx.yml 为变量设置配置

update_nginx_conf.yml 为主配置



##### 测试/不生效
```
ansible-playbook -C ../update_nginx_conf.yml
```


##### 正式使用/生效
```
ansible-playbook ../update_nginx_conf.yml
```

##### hosts 为ansible 的hosts组
```
hosts: webserver 或者 hosts: webserver,nginxproxy

[webserver]
10.0.0.109 hostname=webserver03
10.0.0.110 hostname=webserver02
10.0.0.111 hostname=webserver01

[nginxproxy]
10.0.0.101 hostname=nginxproxy02
10.0.0.108 hostname=nginxproxy01

```