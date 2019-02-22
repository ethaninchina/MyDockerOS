1.hbase所用zk在开发环境中安装于统一服务中，hbase启动时会ssh zk所在服务器，如果不在zk与hbase不在同一服务器中，需配置hbase到zk所在服务器的ssh连接设置。
<\br>
2.pinpoint-collect和pinpoint-web配置的address为zk所在服务器IP，此处配置不包含端口
<\br>
3.pinpoint-web不显示agent信息，需在agent及pinpoint-web所在服务器进行hosts绑定，绑定hbase所在服务host的IP,这样才能使得pinpoint-web连接到hbase服务。
