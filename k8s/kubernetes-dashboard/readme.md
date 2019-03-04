#
当然，如果直接用官方提供的该文件创建dashboard，由于创建的用户kubernetes-dashboard绑定的角色为kubernetes-dashboard-minimal，由于改角色并没有访问和操作集群的权限，因此登陆dashboard的时候，会提示权限错误：“configmaps is forbidden: User "system:serviceaccount:kube-system:kubernetes-dashboard"。因此需修改RoleBinding的相关参数，绑定权限更高的角色：

kubernetes-dashboard.yaml 修改如下
```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
  ```
现有的
```
wget https://raw.githubusercontent.com/station19/MyDockerOS/master/k8s/kubernetes-dashboard/kubernetes-dashboard.yaml
wget https://raw.githubusercontent.com/station19/MyDockerOS/master/k8s/kubernetes-dashboard/k8s-admin.yaml
```
综合查看
```
kubectl get svc,pod -n kube-system
```
查看dashboard被k8s分配到了哪一台机器上
```
kubectl get pods --all-namespaces -o wide
```
查看dashboard的集群内部IP
```
kubectl get services --all-namespaces
```
删除老的 dashboard
```
kubectl delete -f kubernetes-dashboard.yaml 
kubectl delete -f k8s-admin.yaml
```
创建新的dashboard
```
kubectl create -f kubernetes-dashboard.yaml
kubectl create -f k8s-admin.yaml
```
查看token
```
kubectl get secret -n kube-system

kubectl describe secret kubernetes-dashboard-token-2rbgp -n kube-system
```
