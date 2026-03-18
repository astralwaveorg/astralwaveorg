---
topic: devops
title: Docker 入门小结
date: 2020-02-14 00:55:38
categories:
  - 运维
  - Docker
tags:
  - Docker
  - 容器
  - 入门
description: 2020年学习 Docker 的完整记录，从安装到实战
---
topic: devops

# Docker 入门小结

2020 年初，疫情在家办公，闲得发慌，决定把 Docker 好好学一下。

之前一直听别人说"容器化"，但不知道具体能干嘛。自己用了两周，真香。

## 为什么用 Docker

### 传统部署的痛
在我刚学服务器的时候，部署一个应用是这样的：

1. 买服务器
2. 装操作系统
3. 装 Python/MySQL/Nginx/各种依赖
4. 部署代码
5. 配置环境变量

如果服务器挂了，换一台又要重来一遍。

而且经常会遇到"在我电脑上能跑"的问题。

### Docker 的好处

- **环境一致**：开发、测试、生产环境一样
- **隔离**：每个服务独立，互不干扰
- **快速**：几秒启动一个服务
- **可移植**：一次构建，到处运行

## 安装

Mac 上安装非常简单：

```bash
brew install --cask docker
```

Linux（Ubuntu）：

```bash
apt update
apt install docker.io
systemctl start docker
systemctl enable docker
```

## 常用命令

### 镜像相关

```bash
# 搜索镜像
docker search nginx

# 拉取镜像
docker pull nginx:latest

# 查看本地镜像
docker images

# 删除镜像
docker rmi nginx:latest
```

### 容器相关

```bash
# 运行容器
docker run -d -p 80:80 nginx

# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 进入容器
docker exec -it container_id /bin/bash

# 停止容器
docker stop container_id

# 删除容器
docker rm container_id

# 查看日志
docker logs -f container_id
```

### 实战：跑一个 Nginx

```bash
# 简单运行
docker run -d -p 80:80 nginx

# 指定名称，挂载配置
docker run -d -p 80:80 \
  --name my-nginx \
  -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx
```

## Docker Compose

Compose 是 Docker 的编排工具，用一个配置文件管理多个容器。

### 安装

```bash
# Mac 已自带
# Linux
apt install docker-compose
```

### 示例：WordPress

```yaml
version: '3'

services:
  db:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: wordpress
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: example
      WORDPRESS_DB_NAME: wordpress
    depends_on:
      - db
    volumes:
      - ./wp_data:/var/www/html

volumes:
  db_data:
```

启动：

```bash
docker-compose up -d
```

## 踩过的坑

### 坑1：端口冲突
跑 Nginx 提示端口被占用。

解决：`docker ps` 查看已占用的端口，或者改映射端口。

### 坑2：磁盘空间
Docker 镜像越来越多，磁盘满了。

解决：
```bash
# 清理未使用的镜像
docker image prune -a

# 清理构建缓存
docker builder prune
```

### 坑3：权限问题
挂载本地目录到容器，提示权限拒绝。

解决：
```bash
# 方式1：修改目录权限
chmod 777 /path/to/dir

# 方式2：启动时指定用户
docker run -v /path/to/dir:/app -u 1000:1000 image
```

## Dockerfile

自定义镜像需要写 Dockerfile。

示例：一个 Python Web 应用

```dockerfile
FROM python:3.9-slim

WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制代码
COPY . .

# 暴露端口
EXPOSE 8080

# 启动命令
CMD ["python", "app.py"]
```

构建：

```bash
docker build -t my-app .
```

## 感悟

Docker 真的是现代开发的必备技能。

它让"环境配置"不再是问题，让"部署"变得简单，让"微服务"成为可能。

现在我的习惯是：任何服务都先 Docker 跑，稳了再考虑原生部署。

下一步研究 Kubernetes，这才是真正的大家伙。