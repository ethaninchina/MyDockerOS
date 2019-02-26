#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pika
import random
import time
import gevent
from gevent import monkey


username = 'admin'
password = 'admin'
host = '10.0.0.123'

def sendmsg():
    credentials = pika.PlainCredentials(username, password)
    connection = pika.BlockingConnection(pika.ConnectionParameters(host=host, credentials=credentials, port=5672))
    channel = connection.channel()
    #channel.queue_declare(queue='test')
    #消息队列名称为test
    channel.basic_publish(exchange='',
                        routing_key='test',
                        body='Hello World123!')

    #print "[x] send message ok"
    connection.close()


def call_gevent(count):
    """调用gevent 模拟高并发"""
    begin_time = time.time()
    run_gevent_list = []
    for i in range(count):
        print('--------------%d--Test-------------' % i)
        run_gevent_list.append(gevent.spawn(sendmsg()))
    gevent.joinall(run_gevent_list)
    end = time.time()

    print('everone test time(avg) s:', (end - begin_time) / count)
    print('sum test time s:', end - begin_time)


if __name__ == '__main__':
    # 10万并发请求队列
    test_count = 100000
    call_gevent(count=test_count)
