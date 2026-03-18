---
title: 第一次接触 LLM
date: 2023-03-20 00:58:42
categories:
  - AI
  - LLM
tags:
  - LLM
  - ChatGPT
  - AI
---

# 第一次接触 LLM

被朋友强行安利，试了下 ChatGPT。

然后我失眠了。

## 震撼

让它写代码，真的能写。
让它解释概念，讲得比我清楚。
让它帮忙 debug，几秒钟找到问题。

## 担忧

这玩意儿会取代程序员吗？

目前看来不会替代，但不会用 AI 的人可能会被会用的人替代。

## 尝试

```python
import openai

response = openai.ChatCompletion.create(
  model="gpt-3.5-turbo",
  messages=[
    {"role": "user", "content": "帮我写个快速排序"}
  ]
)

print(response.choices[0].message.content)
```

这也太方便了。

决定好好研究一下 prompt engineering...
