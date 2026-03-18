---
title: Prompt Engineering 实践总结
date: 2023-07-15 01:08:29
categories:
  - AI
  - Prompt
tags:
  - Prompt
  - AI
  - 提示词
---

# Prompt Engineering 实践总结

用了一段时间 LLM，总结点 prompt 技巧。

## 基础原则

1. **明确任务**: 别让它猜你要什么
2. **给出例子**: Few-shot 效果往往更好
3. **分解任务**: 复杂问题拆成几步

## 实用技巧

### 指定角色
```
你是一个资深后端工程师，擅长 Python 和 Go...
```

### 指定格式
```
请用 JSON 格式返回，包含以下字段：id, name, description
```

### 思维链
```
请分步骤思考，先分析问题，再给出解决方案，最后提供代码
```

## 避坑

- 别问太开放的问题
- 上下文不要过长
- 重要内容放在前面

感觉这玩意儿和编程差不多，得练。
