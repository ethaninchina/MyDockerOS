#!/bin/bash
BCK_DIR="/data/mysqlDB_bak"
MYUSER=root
MYPASS=123456#*#
MYLOGIN="mysql -u$MYUSER -p$MYPASS"
MYDUMP="mysqldump -u$MYUSER -p$MYPASS -B"
cd $BCK_DIR
find ./ -mtime +7 -name "*.sql.gz" -exec rm -fr {} \;

wait

DATABASE="$($MYLOGIN -e "show databases;"|egrep -vi "Data|_schema|mysql|sys")"
for dbname in $DATABASE
  do
   MYDIR=$BCK_DIR/$dbname
   [ ! -d $MYDIR ] && mkdir -p $MYDIR
 $MYDUMP $dbname|gzip >$MYDIR/${dbname}_$(date +%F).sql.gz
done

