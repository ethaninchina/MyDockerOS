- 首先得 有一台能访问 Google的服务器或者linux/unix/mac 类的电脑
- 下载安装包,然后copy到 CN 服务器离线安装

```shell
#yum -y install --downloadonly --downloaddir=k8s kubelet kubeadm kubectl

wget https://raw.githubusercontent.com/station19/MyDockerOS/master/k8s/k8s.tar.gz
tar zxvf k8s.tar.gz
cd k8s
yum -y localinstall *.rpm

```

