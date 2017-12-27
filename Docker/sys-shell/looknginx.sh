#! /bin/bash
if [ ! -f /opt/openresty/nginx/logs/nginx.pid ]; then
service nginx stop
service nginx start
fi

