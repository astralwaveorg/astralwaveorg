---
topic: ai
title: OpenClaw memory_search 恢复实录：plugin ID 不是你想的那个
date: 2026-04-10 21:35:35
categories:
  - AI
tags:
  - LLM
description: 记录一次 OpenClaw memory_search 插件加载失败的排查过程。错误提示让你加 embedding，但 embedding 根本不是 plugin ID。
---

# OpenClaw memory_search 恢复实录：plugin ID 不是你想的那个

## 问题怎么发现的

某个下午，`memory_search` 突然返回空结果，没有任何错误信息，但就是查不到东西。

以为是模型问题，先是检查 endpoint、模型名称、ollama 服务状态——都是好的。翻了半天日志，发现这样一条 warning：

```
plugins.allow excludes "embedding". Add "embedding" to plugins.allow
```

提示很清楚：把你的 `embedding` 加到 `plugins.allow` 里。

照做了。restart。等了。没用。

再查，这条 warning 消失了，但 `memory_search` 还是不返回结果。

## 真正的根因

后来发现，这条 warning 本身是个误导。

`embedding` 不是 plugin ID。OpenClaw 里真正的插件 ID 是 `ollama`，`embedding` 只是 ollama 插件提供的某个功能命名。

所以你加了 `"embedding"` 到 `plugins.allow`，配置写入没问题，但插件系统根本不认这个名字，等于白加。

正确做法是把 `"ollama"` 加进去。

```json
// openclaw.json
{
  "plugins": {
    "allow": ["ollama"]
  }
}
```

加完之后 restart，memory-core 插件正常加载，`vector ready`。

`memory_search` 恢复正常。

## 教训

1. **错误信息不等于答案**。warning 告诉你"加 embedding"，但它只是告诉你缺少什么，不是告诉你应该填什么值。plugin ID 和功能名称是两回事。

2. **先确认 key 存在，再修改配置**。我之前就是看到提示就直接填，没有验证这个 key 在 schema 里是不是合法的、值域对不对。后来 AGENTS.md 里补了一条规则：修改配置前必须先 `config.schema.lookup` 验证 key 存在且值在合法枚举范围内。

3. **重启验证是必要的**。配置改了但没 restart，旧的插件加载状态不会变。看起来没生效，不一定是配置写错了，也可能是没 restart。

## 怎么验证修复

```bash
# 验证 memory_search 恢复
memory_search "随便一个词"

# 看 provider 是否正确加载
# 应该看到 provider: ollama / model: nomic-embed-text

# 用 openclaw doctor 做全面检查
openclaw doctor --non-interactive
```

这次 doctor 输出 0 errors，50 个插件加载正常。

---

**结论**：配置项的"提示"和"正确答案"之间可能有偏差。排查时先确认系统实际识别的 ID 是什么，再动手改。
