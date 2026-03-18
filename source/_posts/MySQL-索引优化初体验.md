---
topic: backend
title: MySQL 索引优化初体验
date: 2020-06-08 01:12:44
categories:
  - 数据库
  - MySQL
tags:
  - MySQL
  - 索引
  - 性能优化
description: 第一次因为索引问题导致的性能问题，以及排查和解决过程
---
topic: backend

# MySQL 索引优化初体验

2020 年 6 月，被一个 SQL 查询坑惨了。

## 问题

一个看起来很简单的查询，跑了 30 秒没出结果：

```sql
SELECT * FROM orders 
WHERE user_id = 123 
  AND status = 'paid' 
  AND created_at > '2020-01-01';
```

orders 表，100 万条数据。

## 排查

首先怀疑网络问题 ping 了一下，没问题。

然后看执行计划：

```sql
EXPLAIN SELECT * FROM orders 
WHERE user_id = 123 
  AND status = 'paid' 
  AND created_at > '2020-01-01';
```

结果吓一跳：type: ALL，rows: 1000000

全表扫描！100 万条数据一条一条遍历。

## 解决

加索引：

```sql
CREATE INDEX idx_user_status_time ON orders(user_id, status, created_at);
```

再跑一次：

```sql
EXPLAIN SELECT * FROM orders 
WHERE user_id = 123 
  AND status = 'paid' 
  AND created_at > '2020-01-01';
```

这次 type: ref，rows: 15

0.01 秒出结果。

## 索引知识总结

### 什么时候加索引

- WHERE 条件中经常出现的列
- JOIN 的关联列
- 排序 ORDER BY 的列
- 覆盖索引：查询的列正好在索引中

### 索引类型

- **主键索引**：唯一且非空
- **唯一索引**：唯一但允许空
- **普通索引**：普通列
- **复合索引**：多列组合

### 复合索引最左前缀

```sql
CREATE INDEX idx_a_b_c ON table(a, b, c);
```

这个索引可以用于：
- WHERE a = xxx
- WHERE a = xxx AND b = xxx
- WHERE a = xxx AND b = xxx AND c = xxx

但不能用于：
- WHERE b = xxx
- WHERE c = xxx

### 什么时候索引失效

- LIKE '%xxx%'
- OR 导致索引失效
- 函数作用于索引列
- 数据类型隐式转换

## 后续优化

### 1. 覆盖索引

```sql
CREATE INDEX idx_user_status_time ON orders(user_id, status, created_at)
  INCLUDING (order_id, amount, customer_name);
```

查询不需要回表。

### 2. 慢查询日志

开启慢查询日志：

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
```

定期分析慢查询，优化索引。

### 3. 分表

数据量太大，考虑分库分表：

- 水平分表：按时间、按用户ID
- 垂直分表：按业务拆分

## 感悟

索引是 MySQL 优化的第一步，也是最重要的一步。

但索引不是万能的：
- 索引占用空间
- 写入时维护索引有开销
- 过多索引反而变慢

经验：
- 善用 EXPLAIN
- 关注慢查询日志
- 索引优化是持续的过程

现在每次写 SQL，我都会先想：有没有索引？能不能用上？