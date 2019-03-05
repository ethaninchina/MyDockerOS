### 1,) 第一步先 创建空间 namespace.yaml
```
apiVersion: v1
kind: Namespace
metadata:
    name: nginx-cluster
    labels:
        name: nginx-cluster
```
### 2,) 第二步 创建部署文件 deployment.yaml
```
apiVersion: v1
kind: ReplicationController
metadata:
  namespace: nginx-cluster
  name: nginx-server
spec:
  replicas: 2
  selector:
    name: nginx
  template:
    metadata:
      labels:
        name: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-data
              mountPath: /usr/share/nginx/html
      volumes:
        - name: nginx-data
          hostPath:
            path: /tmp/data
```
### 3,) 第三步,创建服务  service.yaml
```
apiVersion: v1
kind: Service
metadata:
  namespace: nginx-cluster
  name: nginx-cluster
spec:
  ports:
    - port: 8000
      targetPort: 80
      protocol: TCP
  selector:
    name: nginx
    ```
