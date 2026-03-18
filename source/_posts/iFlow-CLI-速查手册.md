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

## 入门提示

刚上手记住这几个就行：

```bash
/init     # 创建 IFLOW.md，第一步必须跑
/docs     # 浏览器打开完整文档
/demo     # 交互式快速演示，感受一下
```

Smart 模式是默认启用的，`Shift+Tab` 或 `Alt+M` 切到 Think 模式。粘贴图片用 `Ctrl+V`（不是 `Cmd+V`），新手几乎都会踩这个坑。

用 `@` 指定上下文文件很实用：

```
@src/myFile.ts 帮我看看这个函数能不能优化
```

多个文件用逗号分隔，`@src/,@lib/` 这样。

Shell 模式通过 `!` 执行终端命令，比如 `!npm run start`，不用切窗口。

## 初始化

```bash
/init
```

分析当前项目，生成或更新 `IFLOW.md` 配置文件。定义项目技术栈、需要关注的核心文件等。

## 帮助和基础命令

```bash
/help              # 显示帮助信息
/docs              # 浏览器打开完整文档
/about             # 显示版本信息
/theme             # 更改主题
/vim               # 开关 vim 模式
/update            # 检查并更新版本
/quit              # 退出 CLI
```

## 语言切换

```bash
/language zh-CN    # 简体中文
/language en-US    # English
```

## 对话管理

```bash
/chat list              # 列出已保存的对话检查点
/chat save <标签>       # 保存当前对话为检查点
/chat resume <标签>     # 从检查点恢复对话
/chat delete <标签>     # 删除检查点
```

清理历史：

```bash
/clear                   # 清除屏幕和对话历史
/cleanup-history         # 清理当前项目的对话历史
/cleanup-checkpoint      # 清理所有检查点，释放磁盘空间
```

## Shell 执行

```bash
!npm run start          # 执行任意 shell 命令
!git status
!docker ps
```

也可以用自然语言描述，iFlow 会转换成命令执行。

## MCP 与扩展

MCP（Model Context Protocol）支持连接各种外部服务：

```bash
/mcp list              # 列出已配置的 MCP 服务器和工具
/mcp auth              # 与支持 OAuth 的 MCP 服务器认证
/mcp online            # 浏览并安装在线仓库的 MCP 服务器
/mcp refresh           # 刷新 MCP 服务器列表，重新加载设置文件
/mcp-demo              # 演示 SQLite MCP Server 的用法
```

插件管理：

```bash
/plugin marketplace     # 管理插件市场
```

扩展：

```bash
/extensions             # 列出激活的扩展
```

## Agents 代理

```bash
/agents list            # 列出可用的代理
/agents refresh         # 从源文件刷新代理列表
/agents online          # 浏览并从在线仓库安装代理
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
/directory add /path/to/project    # 添加工作目录，多个用逗号分隔
/directory show                    # 显示工作区所有目录
```

## 编辑器与 IDE

```bash
/editor                # 设置外部编辑器偏好
/ide                   # 管理 IDE 连接
```

## 日志与导出

```bash
/log                   # 显示当前会话日志存储位置
/export clipboard      # 将对话复制到系统剪贴板
/export file           # 保存对话到当前目录文件
```

## 内存管理

```bash
/memory show           # 显示当前内存内容
/memory add            # 向内存添加内容
/memory refresh        # 从源刷新内存
/memory list           # 列出所有内存文件
```

## 上下文压缩

```bash
/compress              # 压缩上下文，用摘要替换长对话
# 别名: /compact, /summarize
```

## 其他实用命令

```bash
/copy                   # 复制最后结果或代码片段到剪贴板
/stats model            # 显示模型使用统计
/stats tools            # 显示工具使用统计
/qa                     # 基于知识库检索的智能问答
/resume                 # 从历史记录恢复之前的会话历史
/terminal-setup         # 安装 Shift+Enter 快捷键，支持在输入框换行
/tools                  # 列出可用的 iFlow CLI 工具
/statusline             # 设置状态栏 UI
```

Bug 反馈：

```bash
/bug                    # 提交错误报告
```

认证管理：

```bash
/auth                   # 更改认证方式
```

年度总结（如果有的话）：

```bash
/2025                   # 查看 2025 年度总结
```

## 键盘快捷键

| 快捷键 | 功能 |
|--------|------|
| `Shift+Tab` / `Alt+M` | 切换 Smart / Think 模式 |
| `Tab` | 切换 Think 模式 |
| `Ctrl+V` | 粘贴图片（非 `Cmd+V`） |
| `Ctrl+L` | 清除屏幕 |
| `Ctrl+J` | 新行 |
| `Ctrl+O` | 切换调试控制台显示 |
| `Ctrl+Y` | 切换 YOLO 模式 |
| `Ctrl+G` | 切换帮助对话框 |
| `Ctrl+C` | 退出应用程序 |
| `Ctrl+X` / `Meta+Enter` | 在外部编辑器中打开输入 |
| `Alt+Left / Right` | 在输入中跳转单词 |
| `Enter` | 发送消息 |
| `Esc` | 取消操作 / 返回 |
| `Up / Down` | 循环浏览提示历史 |

## 快速演示

```bash
/demo
```

启动交互式工作流，适合刚上手时快速了解 iFlow 能干啥。

---

用了一周下来，最喜欢的几个点：

1. **Shell 模式** — 不用切换窗口，代码写累了直接 `!` 执行命令
2. **对话检查点** — 重要项目可以随时保存/恢复，不用担心上下文丢失
3. **MCP 扩展** — 生态还在完善，但已经有不少实用的服务可以接入
4. **`@` 上下文** — 针对特定文件提问，比每次复制粘贴方便太多

版本 0.5.17，整体体验已经相当成熟。推荐给每天在终端里泡着的开发者。
