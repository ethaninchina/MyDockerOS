#!/usr/bin/bash
#CentOS 7.4 (tx cloud)

#安装docker 和docker-compose
yum install docker docker-compose -y

/bin/systemctl start docker.service
/bin/systemctl enable docker.service

docker pull daocloud.io/library/jenkins:latest
wget https://raw.githubusercontent.com/station19/MyDockerOS/master/Docker/docker-compose/jenkins/docker-compose.yml

#启动
docker-compose up -d

#下载最新版jenkins
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war
docker cp jenkins.war jenkins:/usr/share/jenkins/
docker restart jenkins

#保存修改镜像
#docker commit $(docker ps|grep -v "CONTAINER ID"|grep -w "jenkins"|awk '{print $1}') daocloud.io/library/jenkins
