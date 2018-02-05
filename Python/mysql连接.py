#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
import pymysql

# 打开数据库连接
db = pymysql.connect(
    host='localhost',
    port=3306,
    user='root',
    passwd='123456',
    db='test',
    charset='utf8'
)

# 使用 cursor() 方法声明一个游标对象 cursor
cursor = db.cursor()

#创建搜索
def search():
    # sql语句
    sql = "SELECT * from trade"
    # 使用 execute()  方法执行 SQL 查询
    cursor.execute(sql)
    # 使用 fetchone() 方法获取单条数据.
    # data = cursor.fetchone()
    # 获取所有记录列表
    data = cursor.fetchall()

    #for 遍历字段
    for row in data:
        id = str(row[0]) #str转换数字值
        name = row[1]
        account = str(row[2]) #str转换数字值
        saving = str(row[3]) #str转换数字值
        expend = str(row[4]) #str转换数字值
        income = str(row[5]) #str转换数字值

        #打印字段
        print ('ID='+id, 'name='+name, 'account='+account, 'saving='+saving, 'expend='+expend ,'income='+income )

#创建插入
def insert():
    #sql 语句
    sql2 = "INSERT INTO `test`.`trade` (`id`, `name`, `account`, `saving`, `expend`, `income`) VALUES ('222', '神张222灯', '38012345678', '1000.00', '1000.00', '2000.00')"
    try:
       # 执行SQL语句
       cursor.execute(sql2)
       # 提交修改
       db.commit()
       print('success 执行成功')
    except Exception as e:
       # 发生错误时回滚
       db.rollback()
       print('error 执行错误,已回滚',e)


#执行函数
if __name__ == '__main__':
    search()
    insert()


# 关闭连接
cursor.close() #关闭游标对象
db.close() #关闭数据库连接


