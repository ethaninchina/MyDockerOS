#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pika
 
username = 'admin'
password = 'admin'
host = '10.0.0.123'

credentials = pika.PlainCredentials(username, password)
connection = pika.BlockingConnection(pika.ConnectionParameters(
    host=host, credentials=credentials, port=5672
))
 
channel = connection.channel()

#channel.queue_declare(queue='test')
 
 
def callback(ch, method, properties, body):
    print "[x] Received %r" % body
    
#队列名称为 test
channel.basic_consume(callback, queue='test', no_ack=True)
 
print '[*] Waiting for messages. To exit press CTRL+C'
channel.start_consuming()
