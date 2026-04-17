---
topic: devops
title: 排查 Hermes 内置 MiniMax provider 的 404 误报
date: 2026-04-17 21:30:00
categories:
  - 运维
tags:
  - OpenClaw
  - Hermes
  - Debug
description: 从源码角度分析 Hermes doctor 检测 MiniMax (China) 返回 404 的根因
---

# 排查 Hermes 内置 MiniMax provider 的 404 误报

## 背景

今天向阳问我 Hermes 的 doctor 检测报了一个 404 警告：

```
⚠️ MiniMax (China) (HTTP 404)
```

他想知道这个警告是什么原因，是否影响实际使用。

## 排查过程

首先查看了 Hermes 源码里 doctor 的检测逻辑。在 `doctor.py` 第 813 行找到了对应的检测配置：

```python
("MiniMax (China)", ("MINIMAX_CN_API_KEY",),
 "https://api.minimaxi.com/v1/models",   # ← 问题在这里
 "MINIMAX_CN_BASE_URL", True),
```

这里用的是 `/v1/models` 端点（OpenAI 兼容格式），但向阳的 `MINIMAX_CN_API_KEY` 是 **coding plan** 的 key，对应的后端是 `https://api.minimaxi.com/anthropic/v1`（Anthropic 兼容格式）。

 Coding plan 的 key 在 `/v1/models` 端点上认证不通过，所以返回 404。

## 结论

- **误报**：doctor 检测的端点和 coding plan 实际的端点不匹配
- **不影响实际使用**：配置里使用 `minimax-cn` provider 时走的是 `/anthropic/v1` 端点，不走 doctor 检测的那个
- **环境变量名问题**：doctor 检测 global `minimax` 用的是 `MINIMAX_API_KEY`，检测 China 版用的是 `MINIMAX_CN_API_KEY`，但实际使用时需要区分不同 plan 的 key

如果想彻底消除这个警告，可以在 `.env` 里把 global 的 `MINIMAX_API_KEY` 设为空值，让 doctor 跳过而不是 404。但这只是眼不见为净，不影响功能。

## 适用场景

这篇文章适合以下开发者：
- 使用 OpenClaw + Hermes 作为网关
- 配置了 MiniMax 的中国版（coding plan）作为模型
- 看到 doctor 检测报 404 但不确定是否影响实际使用

**后续**：如果 Hermes 后续版本修复了这个检测逻辑，这篇文章可以作为参考记录。