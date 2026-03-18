---
topic: devops
title: iFlow CLI 速查手册
date: 2026-03-15 23:45:00
categories:
  - 工具
  - CLI
tags:
  - iFlow
  - CLI
  - AI工具
  - 开发效率
description: iFlow CLI 0.5.17 命令速查，效率翻倍
---

topic: devops

# iFlow CLI 速查手册

上周折腾了一下 iFlow，一个挺有意思的终端 AI 工具。用了一周下来感觉不错，特别是它的命令体系设计得很清晰，适合日常开发时随手调用。

记录一下高频用法，省得每次都翻文档。

## 初始化

`/init` 是第一步，会分析当前项目并生成 `IFLOW.md` 配置文件。这个文件定义了 iFlow 和项目的交互方式，比如指定哪些文件需要重点关注、项目的技术栈是什么。

```bash
/init
```

## 基础命令

### 帮助和文档

```bash
/docs        # 在浏览器打开完整文档
/help        # 显示帮助信息
/statusline  # 设置状态栏 UI
```

### 语言切换

```bash
/language zh-CN   # 简体中文
/language en-US   # English
```

## 对话管理

这是 iFlow 用得最多的功能之一。

```bash
/chat save <标签>      # 保存当前对话为检查点
/chat resume <标签>    # 从检查点恢复
/chat list            # 列出所有保存的对话
/chat delete <标签>    # 删除检查点
```

清理历史也常用到：

```bash
/cleanup-history       # 清理当前项目对话历史
/cleanup-checkpoint    # 清理所有检查点，释放磁盘
/clear                 # 清除屏幕和对话历史
```

## Shell 执行

不用离开 iFlow 直接执行终端命令，懒人福音。

```bash
!npm run start              # 执行 shell 命令
!git status                 # 查看 git 状态
```

也可以用自然语言，比如 `start server`，iFlow 会帮你转换成命令执行。

## MCP 和扩展

iFlow 支持 MCP（Model Context Protocol），可以连接各种外部服务。

```bash
/mcp list              # 列出已配置的 MCP 服务器和工具
/mcp auth              # 与支持 OAuth 的 MCP 服务器认证
/mcp online            # 浏览在线仓库安装 MCP 服务器
/mcp refresh           # 刷新 MCP 服务器列表
```

Agents 代理功能：

```bash
/agents list           # 列出可用的代理
/agents refresh        # 从源文件刷新代理
/agents online         # 浏览并安装在线代理
/agents install         # 引导安装新代理
```

## 技能管理

```bash
/skills list           # 列出已配置技能
/skills refresh        # 刷新技能列表
/skills online         # 浏览在线技能市场
```

## 工作区目录

```bash
/directory add /path/to/project    # 添加工作目录
/directory show                    # 显示所有工作区目录
```

## 其他实用命令

```bash
/compress    # 压缩上下文，用摘要替换长对话
/copy        # 复制最后结果到剪贴板
/export clipboard    # 复制对话到系统剪贴板
/export file        # 保存对话到文件
/theme      # 更改主题
/vim        # 开关 vim 模式
/stats model   # 查看模型使用统计
/stats tools   # 查看工具使用统计
```

## 键盘快捷键

熟练后这些快捷键能省不少时间：

| 快捷键 | 功能 |
|--------|------|
| `Shift+Tab` / `Alt+M` | 切换 Smart/Think 模式 |
| `Ctrl+V` | 粘贴图片（非 `Cmd+V`） |
| `Ctrl+L` | 清除屏幕 |
| `Ctrl+J` | 新行 |
| `Ctrl+O` | 切换调试控制台 |
| `Up/Down` | 循环浏览提示历史 |
| `Esc` | 取消操作 / 返回 |

## @ 上下文指定

在输入框里用 `@` 可以指定要针对的文件或文件夹，AI 就会只关注那部分内容：

```
@src/myFile.ts 帮我优化这个函数的性能
```

多个文件用逗号分隔：

```
@src/,@lib/,@config/ 分析项目结构
```

## 快速演示

想快速了解 iFlow 能干啥？

```bash
/demo
```

会启动一个交互式演示工作流，适合刚上手时熟悉功能。

---

用了一周下来，最喜欢的几个点：

1. **Shell 模式** — 不用切换窗口，代码写累了直接 `!` 执行命令
2. **对话检查点** — 重要项目可以随时保存/恢复，不用担心上下文丢失
3. **MCP 扩展** — 生态还在完善，但已经有不少实用的服务可以接入

版本 0.5.17，整体体验已经相当成熟了。推荐给每天在终端里泡着的开发者。
