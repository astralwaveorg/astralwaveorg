---
topic: devops
title: iFlow CLI 最全配置指南 — 踩坑后整理的正确版本
date: 2026-03-19 11:00:00
categories:
  - 工具
  - AI
  - CLI
tags:
  - iFlow
  - AI工具
  - CLI
  - 配置
  - MCP
description: iFlow CLI settings.json 完整配置说明，bool/string 类型不要搞混
---

topic: devops

# iFlow CLI 最全配置指南 — 踩坑后整理的正确版本

用了大半年 iFlow，配置踩了不少坑。最核心的问题就是**字段类型**，`true`/`false` 有的是字符串，有的是布尔值，一旦写错整段配置就不生效，排查起来还很隐蔽。

记录一下目前最完整的配置，直接复制改 token 就能用。

## 核心认证

```json
"selectedAuthType": "iflow",
"apiKey": "[YOUR_IFLOW_API_KEY]",
"baseUrl": "https://apis.iflow.cn/v1",
"modelName": "glm-5",
```

- `selectedAuthType`：认证方式，`iflow` 用心流账号，`openai-compatible` 接其他兼容 OpenAI 协议的服务商
- `apiKey`：iFlow 账号的 API Key，从 Dashboard 获取
- `baseUrl`：心流 API 地址，固定填 `https://apis.iflow.cn/v1`
- `modelName`：默认模型，这里用的是 glm-5，也可以换成 `kimi`、`qwen` 等

---

## 执行模式（关键！）

```json
"approvalMode": "yolo",
"autoAccept": true,
"sandbox": false,
```

这三个字段决定了 iFlow 的行为模式，容易出错：

| 参数 | 类型 | 说明 |
|------|------|------|
| `approvalMode` | **字符串** | `"yolo"` = 自动接受所有输出；`"plan"` = 计划模式；`"autoEdit"` = 自动编辑；`"default"` = 默认确认 |
| `autoAccept` | **布尔值** | `true` = 自动执行安全的工具调用，无需二次确认 |
| `sandbox` | **布尔值** | `false` = 不启用沙箱；`true` 或 `"docker"` = 启用沙箱隔离执行 |

**踩坑点**：`approvalMode` 是**字符串**，要加引号；`sandbox` 和 `autoAccept` 是**布尔值**，不能加引号。我之前把 `sandbox: "false"` 写成字符串，结果沙箱一直异常开启。

---

## 思考模式

```json
"thinkingModeEnabled": "true",
```

**类型：字符串，不是布尔值。** 可选 `"true"` 或 `"false"`。开启后 AI 在给出答案前会展示推理过程，适合复杂问题的分析场景。

---

## 文件与目录

```json
"contextFileName": [
  "IFLOW.md",
  "AGENTS.md"
],
"includeDirectories": [
  "/Users/nora/workspace",
  "/Users/nora/Projects",
  "/Users/nora/scripts"
],
"fileFiltering": {
  "respectGitIgnore": true,
  "enableRecursiveFileSearch": true
},
```

- `contextFileName`：iFlow 启动时自动读取的上下文文件，可以是单个字符串或数组
- `includeDirectories`：AI 可以访问的额外工作目录，配合 `@` 上下文指定文件时很实用
- `fileFiltering`：控制 `@` 命令的文件发现行为
  - `respectGitIgnore`：是否遵循 `.gitignore`，`true` 时 `node_modules/`、`dist/` 等会自动排除
  - `enableRecursiveFileSearch`：是否在当前目录下递归搜索文件名

---

## 性能与行为

```json
"shellTimeout": 300000,
"compressionTokenThreshold": 0.9,
"maxSessionTurns": -1,
"tokensLimit": 200000,
"useRipgrep": true,
"skipNextSpeakerCheck": true,
"autoConfigureMaxOldSpaceSize": true,
```

- `shellTimeout`：Shell 命令超时时间，单位毫秒，`300000` = 5 分钟，适合长时构建任务
- `compressionTokenThreshold`：上下文压缩阈值，`0.9` 表示使用到 90% token 时触发压缩
- `maxSessionTurns`：单会话最大轮数，`-1` 表示不限制
- `tokensLimit`：模型上下文窗口长度，根据模型上限调整
- `useRipgrep`：优先使用 Ripgrep 搜索，性能比默认 grep 快很多
- `skipNextSpeakerCheck`：跳过任务结束检测，配合 `yolo` 模式使用
- `autoConfigureMaxOldSpaceSize`：自动配置 Node.js V8 引擎内存限制，避免大项目内存溢出

---

## 界面与交互

```json
"theme": "GitHub",
"language": "zh-CN",
"hideTips": true,
"hideBanner": true,
"hideWindowTitle": true,
"bootAnimationShown": true,
"pasteFromClipboard": true,
"accessibility": {
  "disableLoadingPhrases": true
},
```

- `theme`：界面主题，支持 `Default`、`GitHub`、`Dracula` 等
- `language`：CLI 默认语言，`zh-CN` 或 `en-US`
- `hideTips`：`true` 隐藏底部帮助提示，界面更干净
- `hideBanner`：`true` 隐藏启动时的 ASCII Art logo
- `hideWindowTitle`：`true` 不在终端窗口显示标题
- `bootAnimationShown`：启动动画是否显示
- `pasteFromClipboard`：`true` 优化剪贴板粘贴体验，支持图片文件粘贴
- `accessibility.disableLoadingPhrases`：`true` 禁用加载时的提示短语

---

## MCP 服务器（重点）

```json
"mcpServers": {
  "ZaiVision": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@z_ai/mcp-server"],
    "env": {
      "Z_AI_API_KEY": "[YOUR_ZAI_API_KEY]",
      "Z_AI_MODE": "ZAI"
    },
    "trust": true
  },
  "MiniMax": {
    "command": "uvx",
    "args": ["minimax-coding-plan-mcp", "-y"],
    "env": {
      "MINIMAX_API_KEY": "[YOUR_MINIMAX_API_KEY]",
      "MINIMAX_API_HOST": "https://api.minimaxi.com"
    },
    "trust": true
  },
  "ZaiWebSearch": {
    "type": "http",
    "url": "https://api.z.ai/api/mcp/web_search_prime/mcp",
    "headers": {
      "Authorization": "Bearer [YOUR_ZAI_API_KEY]"
    },
    "trust": true
  },
  "ZaiWebReader": {
    "type": "http",
    "url": "https://api.z.ai/api/mcp/web_reader/mcp",
    "headers": {
      "Authorization": "Bearer [YOUR_ZAI_API_KEY]"
    },
    "trust": true
  },
  "ZaiZread": {
    "type": "http",
    "url": "https://api.z.ai/api/mcp/zread/mcp",
    "headers": {
      "Authorization": "Bearer [YOUR_ZAI_API_KEY]"
    },
    "trust": true
  },
  "github": {
    "command": "npx",
    "args": ["-y", "@iflow-mcp/server-github@0.6.2"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "[YOUR_GH_TOKEN]"
    },
    "trust": true
  },
  "chrome-devtools": {
    "command": "npx",
    "args": ["-y", "@iflow-mcp/chrome-devtools-mcp"],
    "trust": true
  },
  "playwright": {
    "command": "npx",
    "args": ["-y", "@iflow-mcp/playwright-mcp@0.0.32"],
    "trust": true
  },
  "desktop-commander": {
    "command": "npx",
    "args": ["-y", "@iflow-mcp/desktop-commander"],
    "trust": true
  },
  "mcp-server-code-runner": {
    "command": "npx",
    "args": ["-y", "@iflow-mcp/mcp-server-code-runner"],
    "trust": true
  },
  "bilibili-mcp-server": {
    "command": "uvx",
    "args": ["--from", "iflow-mcp-bilibili-mcp-server", "bilibili"],
    "trust": true
  },
  "amap-maps-streamableHTTP": {
    "httpUrl": "https://mcp.amap.com/mcp?key=[YOUR_AMAP_KEY]",
    "trust": true
  },
  "helms-ai-openclaw-mcp-server": {
    "command": "npx",
    "args": ["-y", "@iflow-mcp/helms-ai-openclaw-mcp-server"],
    "trust": true
  },
  "filesystem": {
    "command": "npx",
    "args": [
      "-y",
      "@anthropic-ai/mcp-server-filesystem",
      "[WORKSPACE_PATH]",
      "[PROJECTS_PATH]",
      "[SCRIPTS_PATH]"
    ],
    "trust": true
  },
  "memory": {
    "command": "npx",
    "args": ["-y", "@anthropic-ai/mcp-server-memory"],
    "trust": true
  },
  "sqlite": {
    "command": "uvx",
    "args": ["mcp-server-sqlite"],
    "trust": true
  }
}
```

### MCP 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `type` | stdio 服务必填 | `stdio` = 标准输入输出；`http` = HTTP 请求（用于远程 MCP） |
| `command` | 必填 | 启动命令，常用 `npx`、`uvx`、`node`、`python` |
| `args` | 可选 | 传递给命令的参数数组 |
| `env` | 可选 | 环境变量，**密钥不要硬写在配置里，通过 `$ENV_VAR` 引用** |
| `trust` | 推荐 `true` | 信任此 MCP 服务器，跳过工具调用的二次确认 |
| `httpUrl` | HTTP 类型必填 | 远程 MCP 服务器的 URL |
| `headers` | HTTP 类型可选 | 请求头，`Authorization` 等认证信息放这里 |

### 推荐的 MCP 组合

| 用途 | MCP | 说明 |
|------|-----|------|
| 图像理解 | ZaiVision | GLM-4.6V 能力，本地 stdio |
| 实时搜索 | ZaiWebSearch | 替代传统 web search |
| 网页读取 | ZaiWebReader | 结构化提取网页内容 |
| GitHub | github | 仓库操作、PR、Issues |
| 浏览器控制 | playwright / chrome-devtools | UI 自动化测试 |
| 文件系统 | filesystem | 指定目录的文件读写 |

---

## 工具输出摘要

```json
"summarizeToolOutput": {
  "run_shell_command": {
    "tokenBudget": 2000
  }
}
```

对 Shell 命令的输出做 token 预算限制，`2000` 表示摘要最多用 2000 tokens。防止长命令输出撑爆上下文。

---

## 错误日志

```json
"errorLog": {
  "enabled": true,
  "maxInMemoryErrors": 50,
  "enableFileLogging": false
}
```

- `enabled`：开启错误日志记录
- `maxInMemoryErrors`：内存中最多缓存 50 条错误
- `enableFileLogging`：`false` = 不写文件日志，避免占用磁盘空间

---

## 完整模板

把 `[YOUR_XXX]` 全部替换成你自己的值，就是一个可直接使用的完整配置：

```json
{
  "$schema": "https://schemas.iflow.ai/settings.v1.json",
  "selectedAuthType": "iflow",
  "apiKey": "[YOUR_IFLOW_API_KEY]",
  "baseUrl": "https://apis.iflow.cn/v1",
  "modelName": "glm-5",
  "contextFileName": ["IFLOW.md", "AGENTS.md"],
  "includeDirectories": [
    "[你的工作目录路径]"
  ],
  "tokensLimit": 200000,
  "approvalMode": "yolo",
  "autoAccept": true,
  "theme": "GitHub",
  "thinkingModeEnabled": "true",
  "sandbox": false,
  "useRipgrep": true,
  "autoConfigureMaxOldSpaceSize": true,
  "enableBuildInTask": "true",
  "fileFiltering": {
    "respectGitIgnore": true,
    "enableRecursiveFileSearch": true
  },
  "language": "zh-CN",
  "shellTimeout": 300000,
  "compressionTokenThreshold": 0.9,
  "maxSessionTurns": -1,
  "hideTips": true,
  "hideBanner": true,
  "hideWindowTitle": true,
  "pasteFromClipboard": true,
  "disableTelemetry": true,
  "skipNextSpeakerCheck": true,
  "accessibility": {
    "disableLoadingPhrases": true
  },
  "summarizeToolOutput": {
    "run_shell_command": {
      "tokenBudget": 2000
    }
  },
  "errorLog": {
    "enabled": true,
    "maxInMemoryErrors": 50,
    "enableFileLogging": false
  },
  "mcpServers": {
    "ZaiVision": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@z_ai/mcp-server"],
      "env": {
        "Z_AI_API_KEY": "[YOUR_ZAI_API_KEY]",
        "Z_AI_MODE": "ZAI"
      },
      "trust": true
    },
    "MiniMax": {
      "command": "uvx",
      "args": ["minimax-coding-plan-mcp", "-y"],
      "env": {
        "MINIMAX_API_KEY": "[YOUR_MINIMAX_API_KEY]",
        "MINIMAX_API_HOST": "https://api.minimaxi.com"
      },
      "trust": true
    },
    "ZaiWebSearch": {
      "type": "http",
      "url": "https://api.z.ai/api/mcp/web_search_prime/mcp",
      "headers": {
        "Authorization": "Bearer [YOUR_ZAI_API_KEY]"
      },
      "trust": true
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@iflow-mcp/server-github@0.6.2"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "[YOUR_GH_TOKEN]"
      },
      "trust": true
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic-ai/mcp-server-filesystem",
        "[WORKSPACE_PATH]"
      ],
      "trust": true
    },
    "sqlite": {
      "command": "uvx",
      "args": ["mcp-server-sqlite"],
      "trust": true
    }
  }
}
```

---

## 类型对照表（防止再踩坑）

| 参数 | 类型 | 常见错误 |
|------|------|---------|
| `approvalMode` | 字符串 | ❌ 写成布尔值 `true` |
| `sandbox` | 布尔值 | ❌ 写成字符串 `"false"` |
| `autoAccept` | 布尔值 | ❌ 写成字符串 `"true"` |
| `thinkingModeEnabled` | 字符串 | ❌ 写成布尔值 `true` |
| `enableBuildInTask` | 字符串 | ❌ 写成布尔值 |
| `fileFiltering.*` | 布尔值 | ✅ 正确 |
| `useRipgrep` | 布尔值 | ✅ 正确 |
| `hideTips` | 布尔值 | ✅ 正确 |
| `shellTimeout` | 数字 | ✅ 正确 |
| `maxSessionTurns` | 数字 | ✅ 正确 |

---

配好了重启 iFlow（`exit` 再进），用 `iflow /stats model` 看看是否正常调用到模型。
