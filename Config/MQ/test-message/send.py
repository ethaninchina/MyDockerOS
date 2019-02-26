#!/usr/bin/env python
# -*- coding: UTF-8 -*- 
import pika
 
username = 'admin'
password = 'admin'
host = '10.0.0.123'
 
credentials = pika.PlainCredentials(username, password)
connection = pika.BlockingConnection(pika.ConnectionParameters(host=host, credentials=credentials, port=5672))
channel = connection.channel()
 
#channel.queue_declare(queue='test')
#队列名称为 test
channel.basic_publish(exchange='',
                      routing_key='test',
                      body='Hello World123!')
 
print "[x]  Hello World123!"
connection.close()
