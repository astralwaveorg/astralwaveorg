---
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
---

# CI/CD 流水线搭建记录

花了三天，总算是把 CI/CD 跑通了。

## 流程

```
代码 push → GitLab Runner 拉取 → 编译 → 测试 → 打包镜像 → 推送到仓库 → 服务器 pull → 部署
```

## .gitlab-ci.yml 示例

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
  only:
    - main

deploy:
  stage: deploy
  script:
    - docker-compose up -d
  only:
    - main
```

## 收获

1. 部署从手动变成了自动
2. 回滚分分钟的事
3. 安心多了

下一步研究 K8s...
