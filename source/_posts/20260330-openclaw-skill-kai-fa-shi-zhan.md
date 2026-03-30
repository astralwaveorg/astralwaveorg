---
topic: tools
title: OpenClaw Skill 开发实战：从需求到发布
date: 2026-03-30 19:36:52
categories:
  - 工具
tags:
  - CLI
description: 完整记录 OpenClaw Skill 的开发流程、关键设计决策与发布上线过程
---

# OpenClaw Skill 开发实战：从需求到发布

## 背景

OpenClaw 的能力是通用的，但每个人的工作流是独特的。它提供了 exec、message、sessions_history 这类底层工具，但如果每次做事都要从头拼装流程，效率上划不来。

Skill 就是来解决这个问题的——把一套固定的工作流打包成一个可复用的单元，触发词一来，LLM 按定义好的步骤执行，不用每次都重新设计。

这篇文章记录的是我写一个 Skill 的完整过程：怎么拆解需求、怎么组织代码结构、怎么做发布。

## Skill 是什么

在 OpenClaw 的体系里，Skill 不是可执行代码，本质上是一组指令。LLM 读取 SKILL.md 里的定义，然后调用 OpenClaw 的内置工具（exec、read、write、message 等）去完成任务。

Skill 解决的是"怎么让 AI 按我的流程做事"这个问题，而不是"怎么让 AI 做到某件具体的事"——后者靠的是工具本身的能力。

## 目录结构

一个 Skill 至少需要：

```
my-skill/
└── SKILL.md          # 核心定义，必须
```

但更完整的结构是这样的：

```
my-skill/
├── SKILL.md           # 核心定义
├── _meta.json          # 元数据（Name、版本、依赖）
├── references/         # 参考文档
│   └── guide.md
└── scripts/            # 执行脚本
    ├── helper.py
    └── utils.sh
```

SKILL.md 负责告诉 LLM"做什么"和"按什么顺序做"，scripts 负责"怎么做"的具体实现。两层分离的好处是改流程不需要动代码，改代码不影响决策链路。

## SKILL.md 怎么写

SKILL.md 分为两部分：**YAML Frontmatter** 和 **Markdown 正文**。

```yaml
---
name: my-skill
description: 简短描述这个 Skill 做什么，LLM 用这个判断是否匹配当前任务
user-invocable: true   # true = 注册为 slash 命令
metadata:
  openclaw:
    requires:
      bins: ["python3", "git"]   # 需要的二进制工具
      env: ["API_KEY"]           # 需要的环境变量
---
```

正文里定义工作流程，用编号列表说清楚每一步。要注意的是：指令要具体，但不要过度细节——LLM 需要知道做什么，但不需要知道怎么实现每个细节点。

```markdown
## 工作流程

1. 读取配置文件 `config.json`
2. 解析用户输入，提取关键参数
3. 调用 `scripts/validate.py` 验证参数合法性
4. 执行核心逻辑
5. 返回结果给用户
```

## 三个关键设计决策

### 决策一：LLM 只生成意图，脚本负责正确性

以生成带日期的文件名为例——让 LLM 输出标准化的日期格式容易出错，换行符、大小写、路径分隔符都可能出现偏差。

正确做法是：LLM 生成标题和关键参数，脚本负责按规范拼接出正确格式。

```bash
# LLM 只需要生成这些
python3 scripts/create_file.py "标题" --param value

# 脚本内部处理所有格式细节
filename = f"{date}_{slugify(title)}.md"
```

这样 LLM 的 Token 消耗可控，文件操作的正确性由 Python 保证。

### 决策二：按职责分离脚本

一个 Skill 里可能出现多种操作：读文件、执行命令、调用 API、发送消息。每种操作对应的工具不同，混在一起会导致 SKILL.md 变得复杂且难维护。

我的习惯是按操作类型拆分成独立脚本，SKILL.md 只负责调用链：

```
scripts/
├── parse_input.py      # 解析用户输入
├── fetch_data.py       # 获取外部数据
├── format_output.py    # 格式化结果
└── notify.py           # 发送通知
```

SKILL.md 里就是简单的步骤 1-2-3-4，具体逻辑在脚本里。

### 决策三：可观测性优先

Skill 执行过程中如果出错，最怕的就是不知道哪一步出了问题。OpenClaw 的 exec 工具会返回 stdout 和 exit code，但只靠这些调试不够。

我在每个关键步骤加了日志输出：

```python
import logging
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

logger.info(f"Step 2: Fetching data from {url}")
```

这样执行失败时可以从日志里精确还原到哪一步出了问题，而不需要重新跑一遍来复现。

## 发布与安装

Skill 开发完成后面临两个选择：本地安装还是发布到市场。

**本地安装**适合内部使用、不想公开的 Skill：

```bash
# 放到 OpenClaw 的 skills 目录
cp -r my-skill ~/.openclaw/skills/

# 或者放在 workspace 内，只在当前项目生效
mkdir -p ~/project/skills/
cp -r my-skill ~/project/skills/
```

OpenClaw 启动时会自动扫描这些路径，注册到 skill 索引里。

**发布到 ClawHub** 适合想复用在多个项目、或者分享给别人的情况：

```bash
# 安装 clawhub CLI
npm install -g clawhub

# 发布
clawhub publish ./my-skill/
```

发布时需要 GitHub OAuth 认证，账户必须注册满一周。发布后 Skill 会有一个全局唯一的 ID，其他人可以：

```bash
# 安装别人发布的 Skill
clawhub install username/my-skill

# 更新到新版本
clawhub update my-skill
```

版本管理用的是语义化版本（semver），变更日志会显示在 Skill 页面。

## 调试技巧

Skill 跑不起来是常有的事，几个我常用的调试方法：

**工具权限检查**——如果 Skill 里用了 exec 但没反应，先确认 openclaw.json 里的工具策略没有禁用 exec：

```bash
openclaw config get tools.exec.policy
```

**依赖检查**——用 `--verbose` 看 Skill 加载时的完整输出：

```bash
openclaw skills list --verbose
```

**日志追踪**——复杂 Skill 可以把日志写到 tmpfs 挂载的目录，避免 IO 影响性能：

```bash
tail -f /tmp/my-skill/*.log
```

## 局限与下一步

目前 OpenClaw 的 Skill 体系有一个限制：Skill 之间的依赖管理还很原始。如果 Skill A 依赖 Skill B，需要手动确保 B 先被安装。期待后续版本能支持类似 npm 的依赖声明。

另外，SKILL.md 的调试基本靠试错——没有本地预览环境，改完要重启 OpenClaw 才能验证。写了一个简单的热重载脚本，但还不完善。

---

Skill 是 OpenClaw 二次开发的核心单元。把高频重复的工作流封装成 Skill，触发词一来 AI 按定义好的路径执行，不用每次都重新拼装。这是让 AI 真正成为"同事"而不是"工具"的关键一步。
