---
title: Claude Code 配置参考手册
date: 2026-03-30 10:00:00
categories:
  - 工具
tags:
  - Claude
  - AI
  - 配置
description: 基于 SchemaStore Claude Code Settings Schema 的完整配置参考，涵盖权限、MCP、Hooks、沙箱等核心配置项。
---

> 本手册基于 [SchemaStore Claude Code Settings Schema](https://www.schemastore.org/claude-code-settings.json) 编写

## 目录

1. [核心配置](#1-核心配置)
2. [环境变量](#2-环境变量)
3. [权限配置](#3-权限配置)
4. [MCP 服务器配置](#4-mcp-服务器配置)
5. [Hooks 配置](#5-hooks-配置)
6. [归属与 Git 配置](#6-归属与-git-配置)
7. [输出与界面定制](#7-输出与界面定制)
8. [沙箱配置](#8-沙箱配置)
9. [内存与上下文](#9-内存与上下文)
10. [认证与登录](#10-认证与登录)
11. [插件与市场](#11-插件与市场)
12. [团队协作](#12-团队协作)
13. [思考与响应](#13-思考与响应)

---

## 1. 核心配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `$schema` | string | - | JSON Schema 引用 |
| `language` | string | "en" | 响应语言 (如 "zh-CN", "ja", "es") |
| `respectGitignore` | boolean | true | 文件选择器是否遵守 .gitignore |
| `cleanupPeriodDays` | number | 30 | 聊天记录保留天数 (0=禁用) |
| `autoMemoryEnabled` | boolean | true | 启用自动记忆保存 |
| `autoUpdatesChannel` | string | "latest" | 更新通道 ("stable" 或 "latest") |
| `feedbackSurveyRate` | number | 0 | 质量调查弹出概率 (0-1) |

### 模型配置 (通过 env 设置)

```json
"env": {
  "ANTHROPIC_MODEL": "MiniMax-M2.7",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.7",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.5",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.5",
  "ANTHROPIC_REASONING_MODEL": "MiniMax-M2.7"
}
```

---

## 2. 环境变量

通过 `env` 对象设置会话环境变量。

**常用配置：**

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `ANTHROPIC_AUTH_TOKEN` | API 认证令牌 | `sk-cp-...` |
| `ANTHROPIC_BASE_URL` | API 端点地址 | `https://api.minimaxi.com/anthropic` |
| `ANTHROPIC_MODEL` | 默认模型 | `MiniMax-M2.7` |
| `API_TIMEOUT_MS` | API 超时(毫秒) | `3000000` |
| `LANG` / `LC_ALL` | 本地化 | `zh_CN.UTF-8` |

---

## 3. 权限配置

这是让 Agent 拥有最大权限的核心配置。

### 完整权限配置

```json
"permissions": {
  "allow": [
    "Agent", "Bash", "Edit", "ExitPlanMode", "Glob", "Grep",
    "KillShell", "LSP", "NotebookEdit", "Read", "Skill",
    "TaskCreate", "TaskGet", "TaskList", "TaskOutput",
    "TaskStop", "TaskUpdate", "TodoWrite", "ToolSearch",
    "WebFetch", "WebSearch", "Write", "mcp__.*"
  ],
  "deny": [],
  "ask": [],
  "defaultMode": "bypassPermissions",
  "additionalDirectories": ["~"]
}
```

### 配置说明

| 属性 | 类型 | 说明 |
|------|------|------|
| `allow` | array | 允许的操作 (正则: `mcp__.*` 匹配所有 MCP) |
| `deny` | array | 拒绝的操作 |
| `ask` | array | 需要询问的操作 |
| `defaultMode` | string | 默认权限模式 |
| `additionalDirectories` | array | 额外允许访问的目录 |

### defaultMode 可选值

| 值 | 说明 |
|----|------|
| `bypassPermissions` | **绕过所有权限** (最大权限) |
| `acceptEdits` | 自动接受编辑请求 |
| `dontAsk` | 不询问，直接拒绝 |
| `delegate` | 委托给用户决定 |
| `plan` | 进入计划模式 |
| `default` | 默认行为 |

### 可允许的工具

| 工具名 | 说明 |
|--------|------|
| `Agent` | 启动子代理 |
| `Bash` | 执行 Shell 命令 |
| `Edit` | 编辑文件 |
| `ExitPlanMode` | 退出计划模式 |
| `Glob` | 文件模式匹配 |
| `Grep` | 文本搜索 |
| `KillShell` | 终止 Shell |
| `LSP` | 语言服务器协议 |
| `NotebookEdit` | Jupyter 笔记本编辑 |
| `Read` | 读取文件 |
| `Skill` | 调用技能 |
| `TaskCreate` | 创建任务 |
| `TaskGet` | 获取任务 |
| `TaskList` | 列出任务 |
| `TaskOutput` | 任务输出 |
| `TaskStop` | 停止任务 |
| `TaskUpdate` | 更新任务 |
| `TodoWrite` | 写待办事项 |
| `ToolSearch` | 搜索工具 |
| `WebFetch` | 获取网页 |
| `WebSearch` | 网络搜索 |
| `Write` | 写入文件 |
| `mcp__.*` | 所有 MCP 服务器 (正则匹配) |

---

## 4. MCP 服务器配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `enableAllProjectMcpServers` | boolean | false | 自动批准项目中所有 MCP 服务器 |
| `enabledMcpjsonServers` | array | [] | 批准的 .mcp.json 服务器列表 |
| `disabledMcpjsonServers` | array | [] | 拒绝的 .mcp.json 服务器列表 |
| `allowedMcpServers` | array | [] | 企业允许列表 |
| `deniedMcpServers` | array | [] | 企业拒绝列表 |
| `allowManagedMcpServersOnly` | boolean | false | 仅使用托管设置的服务器 |

**最大权限配置：**
```json
"enableAllProjectMcpServers": true,
"allowManagedMcpServersOnly": false
```

---

## 5. Hooks 配置

Hooks 允许在特定事件前后执行自定义命令。

### 禁用所有 Hooks (最大权限)

```json
"disableAllHooks": true,
"hooks": {
  "PreToolUse": [],
  "PostToolUse": [],
  "PostToolUseFailure": [],
  "PermissionRequest": [],
  "Notification": [],
  "UserPromptSubmit": [],
  "Stop": [],
  "SubagentStart": [],
  "SubagentStop": [],
  "PreCompact": [],
  "PostCompact": [],
  "Elicitation": [],
  "ElicitationResult": [],
  "TeammateIdle": [],
  "TaskCompleted": [],
  "Setup": [],
  "InstructionsLoaded": [],
  "ConfigChange": [],
  "WorktreeCreate": [],
  "WorktreeRemove": [],
  "SessionStart": [],
  "SessionEnd": []
}
```

### Hook 命令类型

| 类型 | 说明 |
|------|------|
| `command` | Bash 命令 |
| `prompt` | LLM 提示词 |
| `agent` | Agent 执行 |
| `http` | HTTP Webhook |

### HTTP Hooks 安全配置

| 配置项 | 说明 |
|--------|------|
| `allowedHttpHookUrls` | 允许的 URL 模式列表 |
| `httpHookAllowedEnvVars` | 允许插值的环境变量 |
| `allowManagedHooksOnly` | 仅使用托管 Hooks |

---

## 6. 归属与 Git 配置

### attribution 对象

| 属性 | 说明 |
|------|------|
| `commit` | Git 提交信息的归属模板 |
| `pr` | PR 描述的归属模板 |

### 其他 Git 配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `includeGitInstructions` | boolean | true | 包含内置 Git 工作流说明 |

---

## 7. 输出与界面定制

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `outputStyle` | string | "default" | 输出样式 ("default", "Explanatory", "Learning") |
| `spinnerTipsEnabled` | boolean | true | 显示旋转提示 |
| `terminalProgressBarEnabled` | boolean | true | 终端进度条 |
| `showTurnDuration` | boolean | true | 显示对话耗时 |
| `prefersReducedMotion` | boolean | false | 减少动画 |

### statusLine 配置

```json
"statusLine": {
  "type": "command",
  "command": "",
  "padding": 0
}
```

---

## 8. 沙箱配置

**最大权限 = 禁用沙箱：**

```json
"sandbox": {
  "enabled": false,
  "autoAllowBashIfSandboxed": true,
  "allowUnsandboxedCommands": true,
  "network": {
    "allowUnixSockets": [],
    "allowLocalBinding": true,
    "httpProxyPort": 0,
    "socksProxyPort": 0,
    "allowAllUnixSockets": true,
    "allowedDomains": ["*"],
    "allowManagedDomainsOnly": false
  },
  "excludedCommands": [],
  "filesystem": {
    "allowWrite": ["*"],
    "denyWrite": [],
    "denyRead": []
  }
}
```

### 沙箱配置项详解

#### 网络隔离

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `allowLocalBinding` | boolean | 允许绑定本地网络 |
| `allowAllUnixSockets` | boolean | 允许所有 Unix 套接字 |
| `allowedDomains` | array | 允许的域名 (*=全部) |
| `allowManagedDomainsOnly` | boolean | 仅托管设置的域名 |

#### 文件系统

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `allowWrite` | array | 允许写入的路径 |
| `denyWrite` | array | 拒绝写入的路径 |
| `denyRead` | array | 拒绝读取的路径 |

#### 其他

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `enableWeakerNetworkIsolation` | boolean | 允许 TLS 信任服务访问 |
| `enableWeakerNestedSandbox` | boolean | 为无特权 Docker 启用弱沙箱 |
| `ignoreViolations` | object | 忽略沙箱违规的路径 |

---

## 9. 内存与上下文

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `claudeMdExcludes` | array | [] | 排除的 CLAUDE.md glob 模式 |
| `plansDirectory` | string | "~/.claude/plans" | 计划文件目录 |

---

## 10. 认证与登录

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `apiKeyHelper` | string | 输出认证值的脚本路径 |
| `awsCredentialExport` | string | 导出 AWS 凭证的脚本 |
| `awsAuthRefresh` | string | 刷新 AWS 认证的脚本 |
| `forceLoginMethod` | string | 强制登录方式 ("claudeai" 或 "console") |
| `forceLoginOrgUUID` | string | OAuth 登录的组织 UUID |
| `otelHeadersHelper` | string | 输出 OpenTelemetry 头部的脚本 |
| `skipWebFetchPreflight` | boolean | 跳过 WebFetch 黑名单检查 |

---

## 11. 插件与市场

### 已启用插件

```json
"enabledPlugins": {
  "telegram@claude-plugins-official": true,
  "github@claude-plugins-official": true
}
```

### 其他插件配置

| 配置项 | 类型 | 说明 |
|--------|------|------|
| `extraKnownMarketplaces` | object | 额外的插件市场 |
| `strictKnownMarketplaces` | array | **托管** 允许的插件市场列表 |
| `skippedMarketplaces` | array | 跳过的市场 |
| `skippedPlugins` | array | 跳过的插件 ID |
| `blockedMarketplaces` | array | **托管** 阻止的市场 |
| `pluginConfigs` | object | 按插件 ID 的配置 |
| `pluginTrustMessage` | string | **托管** 插件信任警告消息 |

---

## 12. 团队协作

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `teammateMode` | string | "auto" | 团队成员显示模式 |
| `worktree.sparsePaths` | array | [] | Git 稀疏检出目录 |

### teammateMode 可选值

| 值 | 说明 |
|----|------|
| `auto` | 自动选择 |
| `in-process` | 进程内 |
| `tmux` | 使用 tmux |

---

## 13. 思考与响应

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `alwaysThinkingEnabled` | boolean | false | 默认启用扩展思考 |

---

## 快速参考：最大权限配置要点

1. **`permissions.defaultMode: "bypassPermissions"`** - 绕过所有权限提示
2. **`permissions.allow`** - 包含所有工具和 `mcp__.*`
3. **`permissions.additionalDirectories`** - 包含所有常用目录
4. **`disableAllHooks: true`** - 禁用所有 Hooks
5. **`sandbox.enabled: false`** - 禁用沙箱
6. **`sandbox.allowUnsandboxedCommands: true`** - 允许沙箱外命令
7. **`sandbox.filesystem.allowWrite: ["*"]`** - 允许所有写入
8. **`sandbox.network.allowedDomains: ["*"]`** - 允许所有网络域名
9. **`enableAllProjectMcpServers: true`** - 自动启用所有 MCP

---

## 相关资源

- [Claude Code 官方文档](https://code.claude.com/docs/en/settings)
- [SchemaStore Schema](https://www.schemastore.org/claude-code-settings.json)

---

## 附录：settings.json 完整配置（脱敏版）

以下为本人实际使用的 `~/.claude/settings.json` 配置，API Key 等敏感信息已做脱敏处理：

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "apiKeyHelper": "",
  "awsCredentialExport": "",
  "awsAuthRefresh": "",
  "fileSuggestion": {
    "type": "command",
    "command": ""
  },
  "respectGitignore": true,
  "cleanupPeriodDays": 60,
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-cp-***REDACTED***",
    "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.7",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.5",
    "ANTHROPIC_MODEL": "MiniMax-M2.7",
    "ANTHROPIC_REASONING_MODEL": "MiniMax-M2.7",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "LANG": "zh_CN.UTF-8",
    "LC_ALL": "zh_CN.UTF-8"
  },
  "attribution": {
    "commit": "🚀 AI-Powered Development with Claude Code\n\n✨ Features: Auto-generated commit messages\n🤖 Model: Claude 3.5 Sonnet\n👤 User: XIANGYANG ZHANG\n📅 Date: Auto-generated\n\n📝 This commit was created with Claude Code assistance.",
    "pr": "🚀 AI-Enhanced Pull Request\n\n🤖 Generated with Claude Code - Your AI Pair Programmer\n\n**Features:**\n- ✅ Automated code analysis\n- ✅ Intelligent commit messages\n- ✅ Smart PR descriptions\n- ✅ Code review assistance\n\n**Why use Claude Code?**\n- 🎯 Consistent commit message format\n- 🚀 Faster development cycles\n- 📈 Improved code quality\n- 🤝 Better collaboration\n\n**Configuration:**\n- Model: Claude 3.5 Sonnet\n- Permissions: Maximum (bypassPermissions)\n- Plugins: Telegram, GitHub enabled\n\nMade with ❤️ by Claude Code"
  },
  "includeGitInstructions": true,
  "permissions": {
    "allow": [
      "Agent",
      "Bash",
      "Edit",
      "ExitPlanMode",
      "Glob",
      "Grep",
      "KillShell",
      "LSP",
      "NotebookEdit",
      "Read",
      "Skill",
      "TaskCreate",
      "TaskGet",
      "TaskList",
      "TaskOutput",
      "TaskStop",
      "TaskUpdate",
      "TodoWrite",
      "ToolSearch",
      "WebFetch",
      "WebSearch",
      "Write",
      "mcp__.*"
    ],
    "deny": [],
    "ask": [],
    "defaultMode": "bypassPermissions",
    "additionalDirectories": [
      "~",
      "/Users/athena",
      "/Users/athena/Projects",
      "/Users/athena/workspace",
      "/Users/athena/github",
      "/Users/athena/scripts",
      "/Users/athena/notes",
      "/Users/athena/GitHubRepos",
      "/Users/athena/Gitea",
      "/Users/athena/iflows"
    ]
  },
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": [],
  "disabledMcpjsonServers": [],
  "allowedMcpServers": [],
  "deniedMcpServers": [],
  "hooks": {
    "PreToolUse": [],
    "PostToolUse": [],
    "PostToolUseFailure": [],
    "PermissionRequest": [],
    "Notification": [],
    "UserPromptSubmit": [],
    "Stop": [],
    "SubagentStart": [],
    "SubagentStop": [],
    "PreCompact": [],
    "PostCompact": [],
    "Elicitation": [],
    "ElicitationResult": [],
    "TeammateIdle": [],
    "TaskCompleted": [],
    "Setup": [],
    "InstructionsLoaded": [],
    "ConfigChange": [],
    "WorktreeCreate": [],
    "WorktreeRemove": [],
    "SessionStart": [],
    "SessionEnd": []
  },
  "worktree": {
    "sparsePaths": []
  },
  "disableAllHooks": true,
  "allowManagedHooksOnly": false,
  "allowedHttpHookUrls": [],
  "httpHookAllowedEnvVars": [],
  "allowManagedMcpServersOnly": false,
  "statusLine": {
    "type": "command",
    "command": "",
    "padding": 0
  },
  "enabledPlugins": {
    "telegram@claude-plugins-official": true,
    "github@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {},
  "strictKnownMarketplaces": [],
  "forceLoginMethod": "claudeai",
  "forceLoginOrgUUID": "",
  "otelHeadersHelper": "",
  "outputStyle": "default",
  "language": "zh-CN",
  "skipWebFetchPreflight": false,
  "sandbox": {
    "enabled": false,
    "autoAllowBashIfSandboxed": true,
    "allowUnsandboxedCommands": true,
    "network": {
      "allowedDomains": [
        "*"
      ],
      "allowManagedDomainsOnly": false,
      "allowUnixSockets": [],
      "allowAllUnixSockets": true,
      "allowLocalBinding": true,
      "httpProxyPort": 0,
      "socksProxyPort": 0
    },
    "filesystem": {
      "allowWrite": [
        "*"
      ],
      "denyWrite": [],
      "denyRead": []
    },
    "ignoreViolations": {},
    "enableWeakerNestedSandbox": false,
    "enableWeakerNetworkIsolation": false,
    "excludedCommands": []
  },
  "feedbackSurveyRate": 0,
  "spinnerTipsEnabled": true,
  "alwaysThinkingEnabled": true,
  "pluginConfigs": {},
  "autoUpdatesChannel": "latest",
  "plansDirectory": "~/.claude/plans",
  "prefersReducedMotion": false,
  "autoMemoryEnabled": true,
  "claudeMdExcludes": [],
  "terminalProgressBarEnabled": true,
  "showTurnDuration": true,
  "skippedMarketplaces": [],
  "skippedPlugins": [],
  "teammateMode": "auto",
  "skipDangerousModePermissionPrompt": true
}
```

*最后更新: 2026-03-30*
