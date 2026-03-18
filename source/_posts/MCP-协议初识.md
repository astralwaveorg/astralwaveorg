---
topic: ai
title: MCP 协议初识
date: 2025-01-18 01:28:44
categories:
  - AI
  - MCP
tags:
  - MCP
  - Agent
  - 协议
description: Model Context Protocol 是什么？AI Agent 的新标准
---
topic: ai

# MCP 协议初识

2025 年初，Anthropic 发布了 MCP（Model Context Protocol）。

## 解决什么问题

AI Agent 如何安全地调用外部工具？

### 传统方式

```python
# 每个工具单独对接
def search(query): ...
def send_email(to, content): ...
def read_file(path): ...
def call_api(endpoint, data): ...

# 混乱，难以扩展
```

### MCP 方式

```json
{
  "tools": [
    {
      "name": "search",
      "description": "搜索网页信息",
      "inputSchema": {
        "type": "object",
        "properties": {
          "query": {
            "type": "string",
            "description": "搜索关键词"
          }
        },
        "required": ["query"]
      }
    }
  ]
}
```

标准化了。

## 架构

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Claude    │────▶│    MCP      │────▶│   工具      │
│   Desktop   │     │   Server    │     │  (本地/远程)│
└─────────────┘     └─────────────┘     └─────────────┘
```

- **MCP Host**：Claude Desktop、Cursor 等
- **MCP Server**：提供工具的服务
- **MCP Client**：连接 Server

## 优势

### 1. 工具定义统一

所有工具用同一个 schema：

```json
{
  "name": "filesystem_read",
  "description": "读取文件内容",
  "inputSchema": {
    "type": "object",
    "properties": {
      "path": {"type": "string"},
      "lines": {"type": "number"}
    }
  }
}
```

### 2. 安全沙箱

- 本地工具：文件、命令行
- 远程工具：API 调用

用户授权，透明可控。

### 3. 动态发现

```python
# 查询可用工具
tools = client.list_tools()
# 自动发现，不需要硬编码
```

## 示例

### 本地文件工具

```json
{
  "name": "filesystem",
  "tools": [
    {
      "name": "read_file",
      "description": "读取文件",
      "inputSchema": {
        "type": "object",
        "properties": {
          "path": {"type": "string"}
        },
        "required": ["path"]
      }
    },
    {
      "name": "write_file",
      "description": "写入文件",
      "inputSchema": {
        "type": "object",
        "properties": {
          "path": {"type": "string"},
          "content": {"type": "string"}
        },
        "required": ["path", "content"]
      }
    }
  ]
}
```

### 数据库工具

```json
{
  "name": "database",
  "tools": [
    {
      "name": "query",
      "description": "执行 SQL 查询",
      "inputSchema": {
        "type": "object",
        "properties": {
          "sql": {"type": "string"}
        },
        "required": ["sql"]
      }
    }
  ]
}
```

## 使用场景

- **开发工具**：代码编辑、调试
- **数据处理**：数据库查询、文件处理
- **自动化**：工作流、脚本执行
- **信息获取**：网页搜索、知识库

## 未来

MCP 可能会成为 AI Agent 的 USB-C。

就像 USB-C 统一了设备接口，MCP 统一了 AI 与工具的接口。

拭目以待。