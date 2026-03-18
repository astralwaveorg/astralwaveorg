---
topic: backend
topic: backend
title: Nginx 反向代理配置要点
date: 2021-08-30 01:05:32
categories:
  - 运维
  - Nginx
tags:
  - Nginx
  - 反向代理
  - 配置
description: Nginx 反向代理完整配置指南，从基础到生产环境实战
---
topic: backend

# Nginx 反向代理配置要点

2021 年，公司的服务越来越多，Nginx 从入门到熟练，踩了不少坑。

## 为什么用 Nginx

- **反向代理**：隐藏真实服务器
- **负载均衡**：分发请求到多台后端
- **SSL 终结**：HTTPS 加密解密
- **静态文件服务**：比后端框架快
- **限流防刷**：保护后端服务

## 基础配置

### 安装

```bash
# Ubuntu/Debian
apt update
apt install nginx

# 验证
nginx -v
```

### 最简配置

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
```

## 反向代理核心

```nginx
server {
    listen 80;
    server_name myapp.com;

    location / {
        proxy_pass http://backend servers;

        # 必须设置的 Header
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

## 负载均衡

```nginx
upstream backend {
    server 127.0.0.1:3000 weight=3;
    server 127.0.0.1:3001 weight=2;
    server 127.0.0.1:3002 weight=1;

    # 健康检查
    check interval=3000 rise=2 fall=3 timeout=1000;
}

server {
    location / {
        proxy_pass http://backend;
    }
}
```

### 负载均衡策略

```nginx
# 轮询（默认）
upstream backend {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
}

# IP 哈希（会话保持）
upstream backend {
    ip_hash;
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
}

# 最少连接
upstream backend {
    least_conn;
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
}
```

## HTTPS 配置

### 自签名证书（测试用）

```bash
# 生成私钥
openssl genrsa -out server.key 2048

# 生成证书
openssl req -new -x509 -key server.key -out server.crt -days 365
```

### 生产配置

```nginx
server {
    listen 443 ssl http2;
    server_name myapp.com;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    # SSL 优化
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        proxy_pass http://backend;
    }
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name myapp.com;
    return 301 https://$server_name$request_uri;
}
```

## 静态文件服务

```nginx
server {
    listen 80;
    server_name static.myapp.com;
    root /var/www/static;

    # 开启 gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1000;

    # 缓存配置
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
```

## 限流防刷

```nginx
# 限流配置
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

server {
    location /api/ {
        # 突发流量允许多 5 个
        limit_req zone=api_limit burst=5 nodelay;

        proxy_pass http://backend;
    }
}
```

## 日志与监控

### 访问日志

```nginx
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for" '
                '$request_time';

access_log /var/log/nginx/access.log main;
```

### 错误日志

```nginx
error_log /var/log/nginx/error.log warn;
```

## 常用命令

```bash
# 测试配置
nginx -t

# 重载配置
nginx -s reload

# 优雅重启
kill -HUP $(cat /var/run/nginx.pid)

# 查看进程
ps aux | grep nginx

# 查看连接数
netstat -n | grep ESTABLISHED | wc -l
```

## 性能优化

### 1. worker 进程数

```nginx
# 一般设为 CPU 核心数
worker_processes auto;
```

### 2. 连接数

```nginx
events {
    worker_connections 10240;
    use epoll;
    multi_accept on;
}
```

### 3. 打开文件数

```nginx
worker_rlimit_nofile 65535;
```

### 4. 缓冲区

```nginx
client_body_buffer_size 10k;
client_header_buffer_size 1k;
client_max_body_size 8m;
large_client_header_buffers 4 16k;
```

## 踩过的坑

### 坑1：proxy_pass 末尾斜杠

```nginx
# 有斜杠：/api -> /api
location /api {
    proxy_pass http://backend/;
}

# 无斜杠：/api -> /api
location /api {
    proxy_pass http://backend;
}
```

### 坑2：长连接超时

后端是 Java/Python 长连接服务，要设置超时：

```nginx
proxy_read_timeout 300s;
proxy_send_timeout 300s;
```

### 坑3：IP 获取不到

一定要加这些 Header：

```nginx
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

## 总结

Nginx 真的是神器。

配置看起来简单，但里面门道很多。安全、性能、可靠性，都要考虑。

我的习惯：
- 生产环境配 HTTPS
- 必开限流防刷
- 日志要打，监控要做
- 配置要测试再reload

Nginx 是门学问，持续学习。