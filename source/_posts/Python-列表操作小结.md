---
title: Python 列表操作小结
date: 2019-05-22 01:15:43
categories:
  - Python
tags:
  - Python
  - 列表
  - 入门
description: Python 列表常用操作，入门必学
---

# Python 列表操作小结

学 Python 那会儿，列表是最常用的数据结构。

记一些常用的操作，防止忘记。

## 创建列表

```python
# 空列表
nums = []
fruits = list()

# 有数据的列表
nums = [1, 2, 3, 4, 5]
fruits = ['apple', 'banana', 'orange']
mixed = [1, 'hello', True, 3.14]
```

## 常用操作

### 1. 添加元素

```python
fruits = ['apple', 'banana']

# 末尾添加
fruits.append('orange')  # ['apple', 'banana', 'orange']

# 指定位置插入
fruits.insert(1, 'grape')  # ['apple', 'grape', 'banana', 'orange']

# 扩展列表
fruits.extend(['pear', 'peach'])  # ['apple', 'grape', 'banana', 'orange', 'pear', 'peach']
```

### 2. 删除元素

```python
fruits = ['apple', 'banana', 'orange', 'grape']

# 删除指定元素
fruits.remove('banana')  # ['apple', 'orange', 'grape']

# 删除指定位置
fruits.pop()  # 默认删除最后一个: 'grape'
fruits.pop(0)  # 删除第一个: 'apple'

# 清空列表
fruits.clear()  # []
```

### 3. 切片

```python
nums = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

# 取单个
nums[0]   # 0
nums[-1]  # 9

# 切片
nums[1:4]    # [1, 2, 3]
nums[:4]     # [0, 1, 2, 3]
nums[4:]     # [4, 5, 6, 7, 8, 9]
nums[::2]    # [0, 2, 4, 6, 8]  步长2
nums[::-1]   # [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]  倒序
```

### 4. 遍历

```python
fruits = ['apple', 'banana', 'orange']

# 方法1
for fruit in fruits:
    print(fruit)

# 方法2：带索引
for i, fruit in enumerate(fruits):
    print(f"{i}: {fruit}")

# 方法3：倒序遍历
for fruit in reversed(fruits):
    print(fruit)
```

### 5. 排序

```python
nums = [3, 1, 4, 1, 5, 9, 2, 6]

# 原地排序
nums.sort()  # [1, 1, 2, 3, 4, 5, 6, 9]
nums.sort(reverse=True)  # 降序

# 降序新建列表
sorted_nums = sorted(nums, reverse=True)

# 自定义排序
words = ['apple', 'banana', 'Orange', 'grape']
sorted_words = sorted(words, key=str.lower)  # 忽略大小写

# 按长度排序
words = ['apple', 'hi', 'banana']
sorted(words, key=len)  # ['hi', 'apple', 'banana']
```

### 6. 列表推导式

```python
# 基础
squares = [x**2 for x in range(10)]
# [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]

# 带条件
evens = [x for x in range(10) if x % 2 == 0]
# [0, 2, 4, 6, 8]

# 嵌套
matrix = [[i*3+j for j in range(3)] for i in range(3)]
# [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
```

### 7. 常用函数

```python
nums = [1, 2, 3, 4, 5]

len(nums)      # 长度: 5
sum(nums)     # 求和: 15
max(nums)     # 最大: 5
min(nums)     # 最小: 1
nums.count(2) # 元素出现次数: 1
nums.index(3) # 元素索引: 2
```

### 8. 列表运算

```python
# 合并
[1, 2] + [3, 4]  # [1, 2, 3, 4]

# 重复
[1, 2] * 3  # [1, 2, 1, 2, 1, 2]

# 检查元素
3 in [1, 2, 3]  # True
```

## 高级技巧

### 解包

```python
a, b, c = [1, 2, 3]  # a=1, b=2, c=3

first, *middle, last = [1, 2, 3, 4, 5]
# first=1, middle=[2, 3, 4], last=5
```

### zip

```python
names = ['alice', 'bob', 'charlie']
ages = [25, 30, 35]

for name, age in zip(names, ages):
    print(f"{name}: {age}")

# alice: 25
# bob: 30
# charlie: 35
```

### enumerate

```python
fruits = ['apple', 'banana', 'orange']

for i, fruit in enumerate(fruits, 1):  # 从1开始计数
    print(f"{i}. {fruit}")

# 1. apple
# 2. banana
# 3. orange
```

## 总结

列表是 Python 最常用的数据结构。

这些操作看起来简单，但真正用起来的时候经常忘记怎么写。

这篇文章是 2026 年回头写的，算是给自己做个记录吧。