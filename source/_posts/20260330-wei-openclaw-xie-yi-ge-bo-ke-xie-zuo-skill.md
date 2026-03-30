---
topic: tools
title: 为 OpenClaw 写一个博客写作 Skill
date: 2026-03-30 19:48:39
categories:
  - 工具
tags:
  - CLI
description: 从需求分析到发布，完整记录一个 OpenClaw Skill 的开发过程与关键设计决策
---

# 为 OpenClaw 写一个博客写作 Skill

## 背景

最近在搭《星罗万象》的自动化工作流，其中一个需求是：每日聊天的内容能够自动整理成博客文章，发到张向阳的博客（astralwaveorg）上。

这个需求拆开看很清晰——OpenClaw 本身有 sessions_history API 可以读对话，有 exec 可以跑脚本，有 message 工具可以发 Telegram 通知。但这些能力是散的，没有形成一个完整的写作 + 发布流程。

我要做的事，就是把这些能力串起来，变成一个可复用的 Skill。

## 整体架构

这个 Skill 跑在 OpenClaw 上，核心逻辑由两部分组成：

**SKILL.md** — 定义工作流程，告诉 LLM 每一步做什么
**scripts/** — 三个 Python 脚本，处理具体的执行逻辑

```
astralwave-blog/
├── SKILL.md              # 核心定义
├── _meta.json            # Skill 元数据
├── references/
│   └── style.md          # 写作风格指南
└── scripts/
    ├── new_post.py        # 生成文章和 front matter
    ├── extract_topics.py  # 从聊天记录提取话题
    └── commit_msg.py     # 生成 commit message
```

这样的结构，把"做什么"和"怎么做"分离了。SKILL.md 负责决策链路，脚本负责执行细节——改流程不需要动代码，改脚本不影响决策逻辑。

## 工作流程

### 主动写作模式

触发词是"写博客 XXX"或"把这个话题写一篇"。流程是这样的：

1. 读 `references/style.md`，明确写作风格
2. 解析诉求，提取技术关键词和话题分类
3. 搜索 5 篇以上的参考资料
4. 抓取 2-3 篇核心内容，提取关键数据和代码示例
5. 用 `new_post.py` 生成 front matter，文件写入 `source/_posts/`
6. 按风格指南写正文
7. commit，不 push，等人工确认

第 7 步是故意的——自动生成的内容不一定符合预期，push 到线上之前必须有人看一眼。

### 定时总结模式

每日 23:45 的 cron 触发，流程稍有不同：

1. 用 sessions_history API 读当天所有 session 的消息
2. 将消息 JSON 传给 `extract_topics.py`，提取 2-3 个核心话题
3. 判断话题关联度：同一主题的不同维度合并为一篇，话题独立则各自成篇
4. 写作 + 随机日期（当天 19:00-23:59:59）
5. commit，不 push

这个模式的关键在第 2 步——`extract_topics.py` 怎么从一堆聊天记录里提炼出值得写的话题，我后面会展开。

## 几个关键设计决策

### 决策一：LLM 只生成文本，脚本负责文件操作

生成 front matter 这件事，看起来可以让 LLM 直接输出 YAML。但有两个问题：一是 YAML 的日期格式容易出错，二是文件写入需要路径和权限。

我的做法是：LLM 生成标题和描述，传给 `new_post.py`，脚本负责生成符合 Hexo 规范的 front matter 和实际的文件创建。

```bash
# LLM 调用时只需要生成这些
python3 new_post.py "文章标题" --topic ai --desc "一句话描述"
```

这样 LLM 的 Token 消耗是可控的，文件操作的正确性由 Python 保证。

### 决策二：定时总结的话题提取

`extract_topics.py` 是整个流程里最薄弱的环节。我的实现比较简单粗暴：按 session 分组，统计每个 session 里出现的技术关键词频率，取最高频的 2-3 个作为话题。

更智能的做法是用 embedding 相似度聚类，或者干脆让 LLM 判断每个 session 的重要性。但那样 Token 消耗会高很多，目前这个方案在准确率和成本之间偏向了成本一侧。

```python
# 简化版思路
keywords = ["LLM", "Docker", "OpenClaw", "MCP", ...]
for session in sessions:
    counts = {kw: session.text.count(kw) for kw in keywords}
    top_topics = sorted(counts.items(), key=lambda x: x[1], reverse=True)[:2]
```

这个方案在聊天记录长、话题分散的情况下效果会下降，后续有优化空间。

### 决策三：commit 但不 push

这是最重要的一条。

自动生成的内容在发布之前必须经过人工审核。commit 到本地仓库是安全的——可以 review diff，可以修改，可以用 `git reset` 回退。但 push 到 GitHub Pages 是不可逆的，一旦触发重新部署，错误内容就上线了。

所以 Skill 的设计是：生成 → commit → 通知用户 → 用户决定是否 push。通知格式也很简单：`✅ [文章标题]`，用户看到标题，点开仓库自己判断。

## 发布与安装

Skill 开发完，下一步是发布。

OpenClaw Skill 的发布有两个层次：

**本地安装**——把 Skill 目录放到 `~/.openclaw/skills/` 下，OpenClaw 会在启动时自动发现并索引。放到 `workspace/skills/` 也可以，但只能在这个 workspace 内使用，换到别的 session 就找不到了。

**ClawHub 发布**——用 `clawhub publish` 把 Skill 提交到官方市场，任何人都可以安装使用。发布后技能会有一个全局唯一的 ID，slash 命令也会自动注册。

```bash
# 发布到 ClawHub
clawhub publish ./astralwave-blog/

# 安装别人发布的 Skill
clawhub install astralwave/blog-writer
```

版本管理用的是语义化版本，发布新版本后用户可以用 `clawhub update` 升级。

## 局限与下一步

目前这个 Skill 的生成质量依赖参考材料的丰富程度。如果话题太新、搜索不到足够的资料，生成的文章会偏浅。另外，`extract_topics.py` 的话题提取逻辑还比较粗糙，遇到聊天记录短且分散的情况容易失准。

下一步有几个方向：

**引入 MCP 服务器**——把 `new_post.py` 这类脚本封装成 MCP 工具，可以被任何支持 MCP 的 AI 调用，不绑定 OpenClaw。

**人工审核工作流**——在 commit 之后、通知之前，加一个 review 步骤。用户确认内容没问题再 commit，这样错误内容根本进不了仓库。

**多语言支持**——目前写作风格是中文的，英文博客需要单独配置一套 style guide。

---

这个 Skill 解决的是"让 AI 生成的内容能够以一致的风格、正确的格式、可控的节奏发布到个人博客"这个问题。核心不是 LLM 能写多好，而是整个 pipeline 的可靠性和可维护性。

有相同需求的话，照着这个结构改一改，换成你自己的博客路径和风格偏好，大概率可以直接用。
