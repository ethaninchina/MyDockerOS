#自动备份到百度网盘
#项目地址 http://oott123.github.io/bpcs_uploader/
#
#网盘(seafile)目录
#PATHWP="/data/wangpan"
#web目录
PATHWEB="/data/web/www.ooxx.com"
#下载站目录
PATHDOWNLOAD="/data/web/download"
#数据库目录
MYSQLPATH="/data/mysqlDB_bak"
#Nginx配置上级目录
NginxPATH="/opt/openresty/nginx"
#此次备份用到的目录
BACKPATH="/tmp"
#获取备份当天的日期
DATE=$(date -d "today" +%Y-%m-%d)

cd $NginxPATH
tar zcvf $BACKPATH/$DATE-Nginx.tar.gz conf/
sleep 5
cd $BACKPATH
#rm -fr ./*.tar.gz
#打包需要备份的文件目录
sleep 5
tar zcvf $DATE-WEB.tar.gz $PATHWEB
sleep 30
tar zcvf $DATE-Download.tar.gz $PATHDOWNLOAD
sleep 30
tar zcvf $DATE-MySQL.tar.gz $MYSQLPATH
sleep 30

#打包文件后上传到百度网盘
/data/bao/bpcs_uploader-0.1.0-beta/bpcs_uploader.php upload $BACKPATH/$DATE-Nginx.tar.gz $DATE-Nginx.tar.gz
sleep 5
/data/bao/bpcs_uploader-0.1.0-beta/bpcs_uploader.php upload $BACKPATH/$DATE-WEB.tar.gz $DATE-WEB.tar.gz
sleep 30
/data/bao/bpcs_uploader-0.1.0-beta/bpcs_uploader.php upload $BACKPATH/$DATE-MySQL.tar.gz $DATE-MySQL.tar.gz
sleep 30
/data/bao/bpcs_uploader-0.1.0-beta/bpcs_uploader.php upload $BACKPATH/$DATE-Download.tar.gz $DATE-Download.tar.gz

wait
sleep 3
rm -fr /tmp/*.tar.gz