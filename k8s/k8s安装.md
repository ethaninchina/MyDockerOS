# 1,) (master, node)设置hosts,主机名 

cat >>/etc/hosts<<EOF
10.0.0.111  k8s-master
10.0.0.110  k8s-node1 
10.0.0.109  k8s-node2
EOF

#(master)
hostnamectl set-hostname k8s-master
#(node)
hostnamectl set-hostname k8s-node1
hostnamectl set-hostname k8s-node2

# 2,) (master, node)关闭自带防火墙  
systemctl disable firewalld
systemctl stop firewalld
systemctl status firewalld

yum install iptables-services

sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config 
setenforce 0

yum -y install epel-release
yum update

# 3,) (master, node)关闭swap 
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab
mount -a


# 4,) (master)使用chrony同步时间，配置master节点与网络NTP服务器同步时间，所有node节点与master节点同步时间。
#安装chrony：
yum install -y chrony
#注释默认ntp服务器
sed -i 's/^server/#&/' /etc/chrony.conf
#指定上游公共 ntp 服务器，并允许其他节点同步时间
cat >> /etc/chrony.conf << EOF
server 0.asia.pool.ntp.org iburst
server 1.asia.pool.ntp.org iburst
server 2.asia.pool.ntp.org iburst
server 3.asia.pool.ntp.org iburst
allow all
EOF
#重启chronyd服务并设为开机启动：
systemctl enable chronyd
systemctl restart chronyd
systemctl status chronyd
#开启网络时间同步功能
timedatectl set-ntp true


# 5,) (node)配置所有node节点：
#安装chrony：
yum install -y chrony
#注释默认服务器
sed -i 's/^server/#&/' /etc/chrony.conf
#指定内网 master节点为上游NTP服务器
echo "server k8s-master iburst" >> /etc/chrony.conf
#重启服务并设为开机启动：
systemctl enable chronyd
systemctl restart chronyd
#查看存在以^*开头的行，说明已经与服务器时间同步
chronyc sources


#(node)配置docker yum源
yum -y install yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

#安装指定版本，这里安装18.06
yum list docker-ce --showduplicates | sort -r
yum install -y docker-ce-18.06.1.ce-3.el7
systemctl start docker
systemctl enable docker
systemctl status docker





<!-- #安装cfssl（所有节点）
wget -q  --timestamping \
https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 \
https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64

mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo

mkdir /k8s/etcd/{bin,cfg,ssl} -p
mkdir /k8s/kubernetes/{bin,cfg,ssl} -p
cd /k8s/etcd/ssl/ -p /etc/kubernetes/ca -->


#(master, node)在所有节点上
cat>/etc/sysctl.d/k8s.conf<<EOF
vm.swappiness = 0
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# 使配置生效
modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

#执行脚本
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
yum install ipset ipvsadm -y


# 6,) (master, node) 所有节点上安装指定版本 kubelet、kubeadm 和 kubectl
cat>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


yum install -y kubelet-1.13.1 kubeadm-1.13.1 kubectl-1.13.1
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet


######### 部署master节点
#Master节点执行初始化：
#注意这里执行初始化用到了- -image-repository选项，指定初始化需要的镜像源从阿里云镜像仓库拉取。
<!-- 初始化过程说明：
[preflight] kubeadm 执行初始化前的检查。
[kubelet-start] 生成kubelet的配置文件”/var/lib/kubelet/config.yaml”
[certificates] 生成相关的各种token和证书
[kubeconfig] 生成 KubeConfig 文件，kubelet 需要这个文件与 Master 通信
[control-plane] 安装 Master 组件，会从指定的 Registry 下载组件的 Docker 镜像。
[bootstraptoken] 生成token记录下来，后边使用kubeadm join往集群中添加节点时会用到
[addons] 安装附加组件 kube-proxy 和 kube-dns。
Kubernetes Master 初始化成功，提示如何配置常规用户使用kubectl访问集群。
提示如何安装 Pod 网络。
提示如何注册其他节点到 Cluster。 -->

kubeadm init \
    --apiserver-advertise-address=10.0.0.111 \
    --image-repository registry.aliyuncs.com/google_containers \
    --kubernetes-version v1.13.1 \
    --pod-network-cidr=10.244.0.0/16


#记录号最后一条 (node节点接入用到)
#  kubeadm join 10.0.0.111:6443 --token 2slxl5.u5csvsvumooarxr8 --discovery-token-ca-cert-hash sha256:786380f8826222d004910611c2e015f02373a6ee8ca707e89f12bee56a887b4b

#创建普通用户并设置密码k8sadmin
useradd k8s
echo "k8s:k8sadmin" | chpasswd k8s

#追加sudo权限,并配置sudo免密
sed -i '/^root/a\k8s  ALL=(ALL)       NOPASSWD:ALL' /etc/sudoers

#保存集群安全配置文件到当前用户.kube目录
su - k8s
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#启用 kubectl 命令自动补全功能（注销重新登录生效）
echo "source <(kubectl completion bash)" >> ~/.bashrc

#需要上面这些配置命令的原因是：Kubernetes 集群默认需要加密方式访问。所以，这几条命令，就是将刚刚部署生成的 Kubernetes 集群的安全配置文件，保存到当前用户的.kube 目录下，kubectl 默认会使用这个目录下的授权信息访问 Kubernetes 集群。如果不这么做的话，我们每次都需要通过 export KUBECONFIG 环境变量告诉 kubectl 这个安全配置文件的位置。配置完成后centos用户就可以使用 kubectl 命令管理集群了

#查看集群状态：
[k8s@k8s-master ~]$ kubectl get cs
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok                   
scheduler            Healthy   ok                   
etcd-0               Healthy   {"health": "true"} 

#查看节点状态
[k8s@k8s-master ~]$ kubectl get nodes 
NAME         STATUS     ROLES    AGE   VERSION
k8s-master   NotReady   master   14m   v1.13.1

#使用 kubectl describe 命令来查看这个节点（Node）对象的详细信息、状态和事件（Event）：
[k8s@k8s-master ~]$  kubectl describe node k8s-master
Name:               k8s-master
Roles:              master
.........
Events:
  Type    Reason                   Age                From                    Message
  ----    ------                   ----               ----                    -------
  Normal  Starting                 15m                kubelet, k8s-master     Starting kubelet.
  Normal  NodeAllocatableEnforced  15m                kubelet, k8s-master     Updated Node Allocatable limit across pods
  Normal  NodeHasSufficientMemory  15m (x8 over 15m)  kubelet, k8s-master     Node k8s-master status is now: NodeHasSufficientMemory
  Normal  NodeHasNoDiskPressure    15m (x8 over 15m)  kubelet, k8s-master     Node k8s-master status is now: NodeHasNoDiskPressure
  Normal  NodeHasSufficientPID     15m (x7 over 15m)  kubelet, k8s-master     Node k8s-master status is now: NodeHasSufficientPID
  Normal  Starting                 14m                kube-proxy, k8s-master  Starting kube-proxy.

#通过 kubectl describe 指令的输出，我们可以看到 NodeNotReady 的原因在于，我们尚未部署任何网络插件，kube-proxy等组件还处于starting状态。
#我们还可以通过 kubectl 检查这个节点上各个系统 Pod 的状态，其中，kube-system 是 Kubernetes 项目预留的系统 Pod 的工作空间（Namepsace，注意它并不是 Linux Namespace，它只是 Kubernetes 划分不同工作空间的单位）
[k8s@k8s-master ~]$ kubectl get pod -n kube-system -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
coredns-78d4cf999f-225bc             0/1     Pending   0          17m   <none>       <none>       <none>           <none>
coredns-78d4cf999f-kjxmk             0/1     Pending   0          17m   <none>       <none>       <none>           <none>
etcd-k8s-master                      1/1     Running   0          16m   10.0.0.111   k8s-master   <none>           <none>
kube-apiserver-k8s-master            1/1     Running   0          16m   10.0.0.111   k8s-master   <none>           <none>
kube-controller-manager-k8s-master   1/1     Running   0          16m   10.0.0.111   k8s-master   <none>           <none>
kube-proxy-985ln                     1/1     Running   0          17m   10.0.0.111   k8s-master   <none>           <none>
kube-scheduler-k8s-master            1/1     Running   0          16m   10.0.0.111   k8s-master   <none>           <none>


#可以看到，CoreDNS依赖于网络的 Pod 都处于 Pending 状态，即调度失败。这当然是符合预期的：因为这个 Master 节点的网络尚未就绪。集群初始化如果遇到问题，可以使用kubeadm reset命令进行清理然后重新执行初始化。
# root 用户才可以 reset
<!-- [k8s@k8s-master ~]$ kubeadm reset -->

#部署网络插件,要让 Kubernetes Cluster 能够工作，必须安装 Pod 网络，否则 Pod 之间无法通信。Kubernetes 支持多种网络方案，这里我们使用 flannel,执行如下命令部署 flannel：
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

[k8s@k8s-master ~]$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
podsecuritypolicy.extensions/psp.flannel.unprivileged created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.extensions/kube-flannel-ds-amd64 created
daemonset.extensions/kube-flannel-ds-arm64 created
daemonset.extensions/kube-flannel-ds-arm created
daemonset.extensions/kube-flannel-ds-ppc64le created
daemonset.extensions/kube-flannel-ds-s390x created


#过个几分钟再次查看, 状态已经全部OK
[k8s@k8s-master ~]$ kubectl get pod -n kube-system -o wide
NAME                                 READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
coredns-78d4cf999f-6stc8             1/1     Running   0          11m     10.244.0.2   k8s-master   <none>           <none>
coredns-78d4cf999f-c9kv6             1/1     Running   0          11m     10.244.0.3   k8s-master   <none>           <none>
etcd-k8s-master                      1/1     Running   0          10m     10.0.0.111   k8s-master   <none>           <none>
kube-apiserver-k8s-master            1/1     Running   0          10m     10.0.0.111   k8s-master   <none>           <none>
kube-controller-manager-k8s-master   1/1     Running   0          10m     10.0.0.111   k8s-master   <none>           <none>
kube-flannel-ds-amd64-fsh5w          1/1     Running   0          9m10s   10.0.0.111   k8s-master   <none>           <none>
kube-flannel-ds-amd64-j4wz6          1/1     Running   0          7m26s   10.0.0.110   k8s-node1    <none>           <none>
kube-flannel-ds-amd64-zzll8          1/1     Running   0          7m20s   10.0.0.109   k8s-node2    <none>           <none>
kube-proxy-77b9j                     1/1     Running   0          11m     10.0.0.111   k8s-master   <none>           <none>
kube-proxy-cld8d                     1/1     Running   0          7m20s   10.0.0.109   k8s-node2    <none>           <none>
kube-proxy-dkctt                     1/1     Running   0          7m26s   10.0.0.110   k8s-node1    <none>           <none>
kube-scheduler-k8s-master            1/1     Running   0          10m     10.0.0.111   k8s-master   <none>           <none>

##(node节点) 加入node到集群
kubeadm join 10.0.0.111:6443 --token 2slxl5.u5csvsvumooarxr8 --discovery-token-ca-cert-hash sha256:786380f8826222d004910611c2e015f02373a6ee8ca707e89f12bee56a887b4b

#(master节点) 查看
[k8s@k8s-master ~]$ kubectl get nodes
NAME         STATUS   ROLES    AGE     VERSION
k8s-master   Ready    master   11m     v1.13.1
k8s-node1    Ready    <none>   7m32s   v1.13.1
k8s-node2    Ready    <none>   7m26s   v1.13.1

这时，所有的节点都已经 Ready，Kubernetes Cluster 创建成功，一切准备就绪。
如果pod状态为Pending、ContainerCreating、ImagePullBackOff 都表明 Pod 没有就绪，Running 才是就绪状态。
如果有pod提示Init:ImagePullBackOff，说明这个pod的镜像在对应节点上拉取失败，我们可以通过 kubectl describe pod 查看 Pod 具体情况，以确认拉取失败的镜像：
#kubectl describe pod kube-flannel-ds-amd64-fsh5w --namespace=kube-system


#测试集群各个组件,部署一个 Nginx Deployment，包含2个Pod
[k8s@k8s-master ~]$ kubectl create deployment nginx --image=nginx:alpine
deployment.apps/nginx created
[k8s@k8s-master ~]$ kubectl scale deployment nginx --replicas=2
deployment.extensions/nginx scaled

#查看启动是否成功
[k8s@k8s-master ~]$ kubectl get pods -l app=nginx -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE        NOMINATED NODE   READINESS GATES
nginx-54458cd494-pr6l7   1/1     Running   0          89s   10.244.1.2   k8s-node1   <none>           <none>
nginx-54458cd494-w2rqp   1/1     Running   0          59s   10.244.2.2   k8s-node2   <none>           <none>

#再验证一下kube-proxy是否正常：以 NodePort 方式对外提供服务
[k8s@k8s-master ~]$ kubectl expose deployment nginx --port=80 --type=NodePort
service/nginx exposed
[k8s@k8s-master ~]$ kubectl get services nginx
NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.104.222.18   <none>        80:30875/TCP   20s

### 自定义镜像配置文件

[k8s@k8s-master ~]$ cat>app-nginx.yaml<<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  ports:
  - port: 8080
    targetPort: 80
    nodePort: 20000
  selector:
    app: nginx
  type: NodePort
EOF

[k8s@k8s-master ~]$ kubectl create -f app-nginx.yaml
[k8s@k8s-master ~]$ kubectl get pods -l run=my-nginx -o wide
NAME                        READY   STATUS    RESTARTS   AGE     IP           NODE        NOMINATED NODE   READINESS GATES
my-nginx-64fc468bd4-9xcfr   1/1     Running   0          3m12s   10.244.1.3   k8s-node1   <none>           <none>
my-nginx-64fc468bd4-s829c   1/1     Running   0          3m12s   10.244.2.3   k8s-node2   <none>           <none>

<!-- #最后验证一下dns, pod network是否正常：,运行Busybox并进入交互模式
kubectl run -it curl --image=radial/busyboxplus:curl
[ root@curl-66959f6557-cw7fv:/ ]$ nslookup nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      nginx
Address 1: 10.104.222.18 nginx.default.svc.cluster.local
[ root@curl-66959f6557-cw7fv:/ ]$ curl 10.244.1.3
[ root@curl-66959f6557-cw7fv:/ ]$ curl 10.244.2.3 -->

<!-- #Pod调度到Master节点,出于安全考虑，默认配置下Kubernetes不会将Pod调度到Master节点。查看Taints字段默认配置
[k8s@k8s-master ~]$ kubectl describe node k8s-master 
......
Taints:             node-role.kubernetes.io/master:NoSchedule -->

# kube-proxy开启ipvs, 修改为 mode: “ipvs”：
kubectl edit cm kube-proxy -n kube-system
#修改ConfigMap的kube-system/kube-proxy中的config.conf，mode: “ipvs”：

#重启各个节点上的kube-proxy pod：(grep kube-proxy)
[k8s@k8s-master ~]$ kubectl get pod -n kube-system | grep kube-proxy | awk '{system("kubectl delete pod "$1" -n kube-system")}'
pod "kube-proxy-77b9j" deleted
pod "kube-proxy-cld8d" deleted
pod "kube-proxy-dkctt" deleted

[k8s@k8s-master ~]$ kubectl get pod -n kube-system | grep kube-proxy
kube-proxy-482q9                     1/1     Running   0          13s
kube-proxy-fxlpk                     1/1     Running   0          8s
kube-proxy-g7kxk                     1/1     Running   0          11s

#查看日志 
kubectl logs kube-proxy-482q9  -n kube-system


kubernetes集群移除节点
以移除k8s-node2节点为例，在Master节点上运行：
kubectl drain k8s-node2 --delete-local-data --force --ignore-daemonsets
kubectl delete node k8s-node2

#(node节点)上面两条命令执行完成后，在k8s-node2节点执行清理命令，重置kubeadm的安装状态：
kubeadm reset
 