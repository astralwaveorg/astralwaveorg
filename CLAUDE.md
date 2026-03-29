# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Hexo 博客项目，使用 Stellar 主题（v1.29.1），部署在 https://blog.astralwave.org。博客内容主要关于软件架构、后端开发、DevOps 和 AI 应用。

## 常用命令

```bash
# 安装依赖
pnpm install

# 本地开发预览
hexo clean && hexo server    # 或 npm run s

# 生成静态文件
hexo clean && hexo generate  # 或 npm run g / npm run build

# 一键部署
hexo deploy                  # 或 npm run d
```

注意：项目的 package manager 使用 pnpm，不是 npm。

## 目录结构

- `source/_posts/` — 博客文章（Markdown）
- `source/_data/` — 主题数据配置（authors、icons、widgets、topic 等）
- `source/wiki/` — 文档页面
- `source/topic/` — 专栏
- `themes/` — 主题目录（Stellar）
- `bin/` — 运维脚本（start.sh、install.sh、auto_update.sh）
- `scaffolds/` — 文章模板（post.md、draft.md、page.md）

## 配置

- `_config.yml` — Hexo 主配置（站点信息、永久链接、部署等）
- `_config.stellar.yml` — Stellar 主题配置（导航栏、评论、样式等）
- `_config.landscape.yml` — 备选主题配置

## 文章Front Matter

标准字段：`title`、`date`、`categories`、`tags`、`description`、`author`、`lang`

## 主题配置要点

- 主题版本：Stellar v1.33.1 优化版
- 评论系统：Twikoo（envId: https://twikoo-worker.jonny-chang.workers.dev）
- 代码高亮：PrismJS + atom-one-dark 主题
- 永久链接格式：`:year/:month/:day/:title/`
- 启用拼音转换：`permalink_pinyin.enable: true`
