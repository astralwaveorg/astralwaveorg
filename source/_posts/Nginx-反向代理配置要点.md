---
title: Nginx 反向代理配置要点
date: 2021-08-30 01:05:32
categories:
  - 运维
  - Nginx
tags:
  - Nginx
  - 反向代理
  - 配置
---

# Nginx 反向代理配置要点

用了 Nginx 一段时间，总结几个关键点：

## 基础反向代理

```nginx
server {
    listen 80;
    server_name mysite.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 负载均衡

```nginx
upstream backend {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
}

location / {
    proxy_pass http://backend;
}
```

## HTTPS 配置

```nginx
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
```

## 几个建议

1. 开启 gzip
2. 配置缓存
3. 做好限流
4. 日志要打

Nginx 真的是神器，谁用谁知道。
