---
topic: devops
title: CI/CD 流水线搭建记录
date: 2022-06-25 00:52:17
categories:
  - 运维
  - DevOps
tags:
  - CI/CD
  - GitLab
  - Docker
  - 自动化
description: 从零搭建 CI/CD 流水线，GitLab Runner + Docker 完整实战
---

# CI/CD 流水线搭建记录

2022 年上半年，部署还是手工的。每次发版，流程是这样的：

1. 本地打包
2. 打包 Docker 镜像
3. 登录服务器
4. 拉镜像
5. 停容器
6. 起容器
7. 检查

平均 30 分钟，错了还要重来。

痛定思痛，决定搞 CI/CD。

## 为什么需要 CI/CD

### 手工部署的问题
- 容易出错
- 重复劳动
- 回滚困难
- 无法追溯

### CI/CD 的好处
- 自动化，省时间
- 可追溯，每一次提交都有记录
- 回滚简单，版本可控
- 减少人为失误

## 技术选型

### CI/CD 工具
- **Jenkins**：老牌，插件多，但配置复杂
- **GitLab CI**：集成在 GitLab 中，体验好
- **GitHub Actions**：GitHub 自带，免费额度够用
- **Travis CI**：GitHub 友好，但免费版有限

最终选了 **GitLab CI**，因为项目用 GitLab。

### 部署方式
- **Docker**：环境一致，必选
- **docker-compose**：多服务编排
- **Kubernetes**：暂不急，先 docker-compose

## GitLab Runner 安装

### 1. 安装 Runner

```bash
# Ubuntu
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner
```

### 2. 注册 Runner

```bash
sudo gitlab-runner register
# 输入 GitLab URL
# 输入 Token（在 GitLab 设置 -> CI/CD -> Runners）
# 输入描述：production-runner
# 输入标签：production
# 选择 executor：docker
# 输入默认镜像：alpine:latest
```

### 3. 配置 Docker

```bash
# 安装 Docker（如果没有）
apt install docker.io

# 给 Runner 用户加权限
usermod -aG docker gitlab-runner
```

## 流水线配置

### .gitlab-ci.yml

```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: registry.example.com/myapp
  DOCKER_TAG: $CI_COMMIT_SHA

# 构建镜像
build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
    - docker push $DOCKER_IMAGE:$DOCKER_TAG
  only:
    - main

# 运行测试
test:unit:
  stage: test
  image: node:18
  script:
    - npm ci
    - npm run test:unit
  coverage: /Coverage: \d+\.\d+%/

test:integration:
  stage: test
  image: node:18
  services:
    - postgres:15
    - redis:7
  script:
    - npm ci
    - npm run test:integration

# 部署到服务器
deploy:production:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
  script:
    - ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$DEPLOY_HOST "
        docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY &&
        docker pull $DOCKER_IMAGE:$DOCKER_TAG &&
        docker stop myapp || true &&
        docker rm myapp || true &&
        docker run -d --name myapp -p 8080:8080 $DOCKER_IMAGE:$DOCKER_TAG
      "
  environment:
    name: production
    url: https://myapp.example.com
  only:
    - main
  when: manual  # 手动触发部署
```

### 多环境配置

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  # ... 同上

test:
  stage: test
  # ... 同上

deploy:dev:
  stage: deploy
  script:
    - echo "Deploy to dev"
  environment:
    name: development
  only:
    - develop

deploy:staging:
  stage: deploy
  script:
    - echo "Deploy to staging"
  environment:
    name: staging
  only:
    - main

deploy:prod:
  stage: deploy
  script:
    - echo "Deploy to production"
  environment:
    name: production
  only:
    - main
  when: manual
```

## Docker 优化

### 多阶段构建

```dockerfile
# 构建阶段
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# 运行阶段
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

### 镜像大小优化

```dockerfile
# 使用 alpine
FROM node:18-alpine

# 清理缓存
RUN apk add --no-cache python3 make g++ \
    && rm -rf /var/cache/apk/*

# .dockerignore
node_modules
.git
*.md
```

## 遇到的问题

### 问题1：Runner 找不到 Docker

```yaml
# 加 dind 服务
build:
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker login ...
```

### 问题2：权限不够

```bash
# 给 SSH key 加权限
chmod 600 ~/.ssh/id_rsa

# 或者在 script 里加
- eval $(ssh-agent -s)
- echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
```

### 问题3：构建太慢

- 用 Docker 缓存
- 依赖单独层
- cnpm 换成 npm

## 回滚

### 自动回滚

```yaml
deploy:prod:
  stage: deploy
  script:
    - |
      if [ "$DEPLOY_FAILED" = "true" ]; then
        docker pull $DOCKER_IMAGE:$PREVIOUS_TAG
        docker run -d --name myapp -p 8080:8080 $DOCKER_IMAGE:$PREVIOUS_TAG
      fi
```

### 手动回滚

GitLab 支持手动回滚到之前的部署：

```yaml
deploy:prod:
  stage: deploy
  script:
    - docker-compose up -d
  environment:
    name: production
    on_stop: stop_production

stop_production:
  stage: deploy
  script:
    - docker-compose down
  environment:
    name: production
    action: stop
  when: manual
```

## 监控

### 部署通知

```yaml
notify:
  stage: notify
  script:
    - |
      curl -X POST "$WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d '{"status": "success", "commit": "$CI_COMMIT_SHA"}'
  only:
    - main
```

## 总结

CI/CD 让部署变成了一件事：

```bash
git push
```

然后等通知。

从 30 分钟手工部署，到 5 分钟自动部署，值。

下一步研究 K8s...那是另一个故事了。