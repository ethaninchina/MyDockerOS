```
# CentOS 7
$ setenforce 0
$ sed -i "s/enforcing/disabled/g" `grep enforcing -rl /etc/selinux/config`
# 修改字符集,中文
$ localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
$ export LC_ALL=zh_CN.UTF-8
$ echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf


# CentOS6
$ setenforce 0  # 临时关闭,重启后失效
$ service iptables stop  # 临时关闭,重启后失效

# 修改字符集,否则可能报 input/output error的问题,因为日志里打印了中文
$ localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
$ export LC_ALL=zh_CN.UTF-8
$ echo 'LANG=zh_CN.UTF-8' > /etc/sysconfig/i18n
```
