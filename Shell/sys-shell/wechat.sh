#!/bin/bash
# toparty: 4   #¿¿ID
# agentid: 2   #¿¿ID

CropID="CropID"
Secret="Secret"

GURL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CropID&corpsecret=$Secret"
Gtoken=$(/usr/bin/curl -s -G $GURL | awk -F\" '{print $10}')
PURL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$Gtoken"
Content=$1..$2..$3..$4
echo $Content
#/usr/bin/curl --data-ascii '{ "touser": "@all", "toparty": " 3 ","msgtype": "text","agentid": "1000002","text": {"content": "'${Content}'"},"safe":"0"}' $PURL
/usr/bin/curl --data-ascii '{ "touser": "@all","msgtype": "text","agentid": "1000002","text": {"content": "'${Content}'"},"safe":"0"}' $PURL
