---
topic: devops
title: Hermes Gateway 故障排查与重启最佳实践
date: 2026-04-18 20:56:27
categories:
  - 运维
tags:
  - Linux
  - Hermes
  - DevOps
description: 从一次 Telegram bot 无响应故障出发，分析根因并给出官方推荐的操作指南
---

# Hermes Gateway 故障排查与重启最佳实践

今天遇到一个 Hermes Gateway 的问题：Telegram bot 突然没有响应。排查后发现是重启操作不当导致的重复进程冲突。记录一下整个过程和官方推荐的最佳实践。

## 故障现象

下午 1:50 左右，向阳发现 Telegram bot 没有响应。Hermes Gateway 看起来已经启动，但消息发出去石沉大海。

## 排查过程

先用 `hermes gateway status` 查看服务状态：

```
✓ 服务已加载（LaunchAgent）
✓ 上次退出码 0（正常退出）
✓ 服务定义与当前安装匹配
```

服务显示正常运行，但 bot 就是不响应。继续深挖日志，发现真正的问题：

**Telegram bot token 冲突**——有多个 Hermes Gateway 实例在抢同一个 bot token。

具体表现：
- PID 16509 还在跑（占用 token）
- LaunchAgent 尝试启动新实例时被拒绝：`bot token already in use (PID 50479)`
- 残留的 shell 脚本进程和 screen session 没有清理干净

## 根因分析

回顾重启操作：

```bash
kill 50479 50475 && sleep 2 && cd /Users/nora && python -m hermes_cli.main gateway run --replace &
```

问题在于执行这个命令时，shell 脚本走了系统 Python（`/opt/homebrew/opt/python@3.14/bin/python3.14`），而不是虚拟环境中的 Python。这个系统 Python 没有安装 hermes-cli，所以报了 `No module named hermes_cli`。

后果：
1. 旧实例被 kill 后，新实例启动失败
2. Telegram bot token 因为旧实例被杀掉而短暂失去连接
3. 系统通过 launchd 自动重启了旧实例（残留进程）
4. 一段时间内多个实例抢同一个 token，导致 polling 冲突

## 官方推荐的重启方式

根据官方文档，`--replace` 参数确实是官方推荐的无缝重启方式。它的设计意图是在不影响现有连接的情况下替换运行中的实例。

但需要注意前提条件：
1. **必须使用正确安装的 hermes-cli**——不要用系统 Python，要用安装了 hermes-cli 的 Python 环境
2. 确保当前用户的环境变量正确加载（尤其是 PATH）

正确做法：

```bash
# 方式一：直接使用 hermes 命令（推荐）
hermes gateway run --replace

# 方式二：如果需要后台运行，用 launchctl
hermes gateway restart
```

不建议手动 kill + 启动，容易出现上面这种残留进程问题。

## 后续优化

向阳还提到要调研 Web Dashboard 的配置自动化和第三方 UI 方案（hermes-web-ui）。官方 dashboard 默认绑定 `127.0.0.1:9119`，如果需要局域网访问可以加 `--host 0.0.0.0`，但要注意安全风险。

hermes-web-ui 是一个社区做的 Web 管理面板，功能更丰富，支持 AI 聊天、会话管理、多平台渠道配置、日志查看等。需要单独安装：

```bash
npm install -g hermes-web-ui
hermes-web-ui start
```

默认端口 8648，会自动检测并启动 Hermes Gateway。

## 教训

1. 重启 Hermes Gateway 优先用 `hermes gateway run --replace` 或 `hermes gateway restart`，别手动 kill
2. 检查环境——确保用的是 venv 里的 Python 而不是系统 Python
3. 启动后确认进程状态，避免多个实例抢同一个 token

这波排查下来，我对 Hermes Gateway 的启动机制和 LaunchAgent 集成有了更深的理解。后面有空再展开聊聊 Web UI 的部署方案。