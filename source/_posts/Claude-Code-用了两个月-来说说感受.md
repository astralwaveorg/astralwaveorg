---
topic: ai
title: Claude Code 用了两个月，来说说感受
date: 2025-03-12 21:30:00
categories:
  - AI
  - 编程工具
tags:
  - Claude
  - Claude Code
  - AI编程
  - Agent
description: 用了两个月 Claude Code，真实感受，不是软文
---

topic: ai

# Claude Code 用了两个月，来说说感受

今年初开始正式用 Claude Code，到现在已经两个月了。期间经历了好几次大的版本更新，能力也在不断变化。说说我的真实感受，不恰饭，不水文。

## 为什么换掉 Copilot

其实 Copilot 用得也挺顺手的，换过去有点冲动。但那时候 Copilot 的代码补全老是慢半拍，加上 Claude 的上下文理解能力确实更强，就试了试。

第一个月其实还在适应期。Claude Code 的交互方式和 Copilot 完全不同——Copilot 是默默在后台补全，你需要就瞟一眼，不需要就无视它。但 Claude Code 是对话式的，你得主动问它，甚至得主动告诉它你想怎么写。

这个切换过程大概花了两周。

## 真正好用的场景

**重构代码**，这个是真的好用。

以前重构一段代码，要么自己一行行改，要么用 IDE 的批量替换。Claude Code 好处是你可以直接说"把这块改成 Strategy 模式"，它会理解你的意图，然后给出修改方案，你确认了它再去改。

```python
# 之前的状态，大量 if-else 嵌套
def process_order(order):
    if order.type == 'normal':
        if order.payment == 'card':
            # ... 200行嵌套逻辑
            pass
        elif order.payment == 'alipay':
            pass
    elif order.type == 'vip':
        # 又一套嵌套
        pass
```

Claude Code 看完之后，直接说"帮我重构，用工厂模式分离支付逻辑"，它给了我一版清晰的设计，然后又帮我把旧代码一点点迁移过去。这在我之前的工作流里至少要花半天。

**写测试用例**，也很省心。

以前写测试用例是痛苦的事，总是拖延。Claude Code 的话，我会让它先给我一个测试覆盖框架，然后逐个填充。它写的测试不一定完美，但至少是一个很好的起点。

```python
# 扔给 Claude: "给这个函数写完整测试，要覆盖边界情况"
def calculate_discount(price: float, level: str, coupon_code: str = None) -> float:
    """计算折后价格"""
    base_discount = {'silver': 0.9, 'gold': 0.8, 'platinum': 0.7}.get(level, 1.0)
    final = price * base_discount

    if coupon_code and len(coupon_code) == 8:
        final *= 0.95

    return max(final, 0)
```

它会想到边界条件：price 为 0 怎么办，level 不存在怎么办，coupon 格式错误怎么办。比我凭直觉写的测试全面多了。

## 让我不适应的地方

**太"话多"了**。

Claude Code 有时候会过度解释，写一段代码给你贴上来，还要跟你讲为什么要这么写。我更喜欢的是你直接给我代码，有问题我再问。这点可以通过调整 prompt 来控制，但每次都要说"不要解释，直接写"还是有点烦。

**对项目结构的理解有时候会出错**。

它有时候会想当然地认为某个文件存在，或者某个依赖已经安装了。我遇到好几次它引用了一个不存在的工具类，然后写出来的代码自然也跑不通。这种时候调试反而比我自己写还费劲。

**上下文窗口的问题**。

虽然 Claude 的上下文很长，但用久了还是会有"它忘了之前说啥"的情况。我现在的做法是开多个会话，每个功能模块一个会话，不要把什么都塞到一个对话里。

## 总结

两个字：**值得**。

但不是那种"Copilot 可以扔了"的感觉。两者定位不太一样——Copilot 更适合小步快走的日常补全，Claude Code 更适合需要思考的重度任务。我现在日常是两兄弟一起用，Copilot 处理碎片，Claude Code 处理完整功能的开发和重构。

至于值不值每月 20 美元的订阅费，对于职业写代码的人来说，这个投入产出比还是可以的。毕竟帮你省的时间，按工资算一算就回来了。

---

以上是两个月使用下来的真实感受，没有收钱，不恰饭。
