# docker 部署go 项目教程
 秘钥这里只做示例 （不可用）
## 目录结构
```
.
├── docker-compose.yml
├── go1
│   ├── Dockerfile
│   └── main
├── go2
│   ├── Dockerfile
│   └── main
└── nginx
├── nginx.conf
├── conf.d
│   ├── go1.conf
│   └── go2.conf
└── certs
├── go1.pem
├── go1.key
├── go2.pem
└── go2.key

```

## 1. docker-compose.yml

```shell
version: '3.8'

services:
  go8001:
    build:
      context: ./go1
      dockerfile: Dockerfile
    image: goenv:8001
    container_name: go1
    ports:
      - "8001:8001"
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
    environment:
      - TZ=Asia/Shanghai
      - APP_ENV=production
    healthcheck:
      test: [ "CMD-SHELL", "pgrep -f main || exit 1" ]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network

  go8002:
    build:
      context: ./go2
      dockerfile: Dockerfile
    image: goenv:8002
    container_name: go2
    ports:
      - "8002:8001"
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
    environment:
      - TZ=Asia/Shanghai
      - APP_ENV=production
    healthcheck:
      test: ["CMD-SHELL", "pgrep -f main || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network
      
    frontend:
    build:
      context: ./front  # 前端项目的相对路径
      dockerfile: Dockerfile  # 确保这个路径指向正确的Dockerfile
    container_name: front
    ports:
      - "3003:80"  # 或者任何其他未被占用的端口
    restart: always
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/certs:/etc/nginx/certs
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    restart: always
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

## 2. Dockerfile（Go 服务）

```shell
# 使用指定版本的官方Go镜像作为基础
FROM golang:1.24.1 as builder

# 设置工作目录
WORKDIR /app

ENV GOPROXY=https://goproxy.cn,direct

# 复制可执行文件
COPY main .

# 设置可执行权限
RUN chmod +x main

EXPOSE 8001

# 入口点
ENTRYPOINT ["./main"]
```

3. nginx.conf
```shell
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;

    # 包含所有独立的配置文件
    include /etc/nginx/conf.d/*.conf;
}
```

Nginx 服务配置（go1.conf）:
```shell
server {
    listen 80;
    server_name m.wsky.fun;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name m.wsky.fun;

    ssl_certificate /etc/nginx/certs/m.wsky.pem;
    ssl_certificate_key /etc/nginx/certs/m.wsky.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://go1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```