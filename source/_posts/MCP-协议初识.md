---
title: MCP 协议初识
date: 2025-01-18 01:28:44
categories:
  - AI
  - MCP
tags:
  - MCP
  - Agent
  - 协议
---

# MCP 协议初识

Model Context Protocol， Anthropic 搞的。

## 解决什么问题

Agent 如何安全地调用外部工具？

## 传统方式

```python
# 每个工具单独对接
def search(query): ...
def send_email(to, content): ...
def read_file(path): ...
```

乱套。

## MCP 方式

```json
{
  "tools": [
    {
      "name": "search",
      "description": "搜索网页",
      "inputSchema": {"type": "object", "properties": {"query": {"type": "string"}}}
    }
  ]
}
```

标准化了。

## 优势

1. 工具定义统一
2. 安全沙箱
3. 动态发现

感觉是 Agent 时代的基础设施。

先研究着，后面可能有大用。
