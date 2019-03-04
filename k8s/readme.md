重启后 kubelet 无法启动,启动失败
<br>
```
cat>>/etc/rc.d/rc.local<<EOF
swapoff -a
sed -i 's/^.*swap/\#&/g' /etc/fstab
mount -a
sysctl -p /etc/sysctl.d/k8s.conf
systemctl restart kubelet
EOF

chmod +x /etc/rc.d/rc.local

reboot
```
下次开机启动就可以自动启动了
<br>
```
注释包含swap关键词的行

sed -i 's/^.*swap/\#&/g' /etc/fstab
```
