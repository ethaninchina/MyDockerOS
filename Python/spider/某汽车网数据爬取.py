#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 爬取某商城内容 下载到本地
import sys
import requests #网页请求模块
import getpass #输入密码隐藏getpass模块
from bs4 import BeautifulSoup #html模块

# print ('请输入您的用户名和密码')
# user_name = input('用户名：')
# password = input('密码：')
# password = getpass.getpass('密 码：') #密码隐藏

login_url = 'http://test.ooxx.com/mall/index.php?act=login&op=login'
login_data = {'formhash':'XkdCkZeaCWhGCcyL_Vj_FY29W-AdsVC',
        'form_submit':'ok',
        'nchash':'3c2bc036',
        'user_name':'13800138000',
        'password':'123456',
        '_spring_security_remember_me':'true'}

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.108 Safari/537.36'}

#定义session
Py_session = requests.Session()

#get登陆使用session 赋值G
G = Py_session.get(login_url,headers=headers)

#创建session post请求对象
P = Py_session.post(url=login_url,data=login_data,headers=headers,timeout=30)

#打印登陆post登陆后的状态码
Pstatus = P.status_code

#提示Post登陆成功或者失败
if Pstatus != 302:
    print (Pstatus,'登录失败')
    sys.exit(0) #失败退出脚本
else:
    print (Pstatus,'登录成功')

##################### 调用session 获取get内容 #####################
#调用session登陆方法，打印登陆后请求页面源码
G = Py_session.get('http://test.ooxx.com/mall/index.php?act=car_brand&op=index',headers=headers)

#打印get源码
#print(G.content.decode())
#打印get状态码
print('get页面开始get数据：',G.status_code)
### 测试 登陆后获取内容
soup = BeautifulSoup(G.content,"html.parser")  #文档对象
#定义保存文件UTF-8编码到当前目录下的car.txt
OutFile = open('./汽车品牌.txt','w+',encoding='utf8')
OutFile2 = open('./配件品牌.txt','w+',encoding='utf8')

#定义计数变量Num 数字显示默认等于0
Numone = 0
Numtwo = 0

#打印下载汽车品牌
#查找a标签,只会查找出一个a标签，class="carModel" 行
for LBcar in soup.find_all('a',class_='carModel'):  #得到大概数据
    #print(LBcar)
    Numone += 1 #默认加1
    print ("开始下载汽车品牌第[ %s] 条数据" % Numone,LBcar['href']) #打印数据
    # print ('车型:',LBcar['title'],file=OutFile)  #查找LBcar标签里的title值
    # print ('车型连接:',LBcar['href'],file=OutFile)
    # print ('车型编号:',str(LBcar['href'].split('car=')[1]),file=OutFile) #split截取字符串
    print('车型:', LBcar['title'], '车型连接:', LBcar['href'], '车型编号:', str(LBcar['href'].split('car=')[1]), file=OutFile)

print ('\n') #换行 区分 汽车和配件数据

#打印下载配件品牌
#查找a标签,只会查找出一个a标签，class="carModel" 行
for LBpeijian in soup.find_all('dd',class_='goods-class'):  #得到大概数据
    #print(LBpeijian) #打印 最终精确链接信息
    for pjdata in LBpeijian('a'):
        #print (pjdata)
        # 打印 配件品牌名称
        Numtwo += 1  # 默认加1
        print("开始下载配件品牌第[ %s ]条数据" % Numtwo, pjdata['href'])  # 打印数据
        print ('配件品牌：'+pjdata['href'],'配件品牌名称：'+str(pjdata).split('>')[1].split('</')[0],file=OutFile2)
        #print ('配件品牌链接：' + pjdata['href'])
