upstream SAP-ZBA {
            hash $http_x_forwarded_for consistent;
	        #hash $remote_addr consistent;
            server 192.168.100.103:8080 weight=10 max_fails=3 fail_timeout=30s; #new add
            server 192.168.100.104:8080 weight=10 max_fails=3 fail_timeout=30s; #new add
            server 192.168.100.13:8080 weight=30 max_fails=3 fail_timeout=30s;
            server 192.168.100.14:8080 weight=30 max_fails=3 fail_timeout=30s;
            keepalive 300;
    }


server {
        listen       8080;
        server_name  192.168.9.33;

        access_log  /datas/soft/nginxlog/logs/pda.access.log  json;
        error_log  /datas/soft/nginxlog/logs/pda.error.log  error;


        location / {
            proxy_pass http://SAP-ZBA;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
            proxy_ignore_client_abort on;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
        }

# 访问 /ISAPService.asmx?op=UploadtoImageNObb 将流量代理到 http://SAP-Image
	   location  ^/ISAPService.asmx {
   	         if ( $query_string ~* ^(.*)op=UploadtoImageNObb$ )   {
        		     proxy_pass  http://SAP-Image;
       		    }
        }
}
