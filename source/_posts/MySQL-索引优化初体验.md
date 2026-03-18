---
title: MySQL 索引优化初体验
date: 2020-06-08 01:12:44
categories:
  - 数据库
  - MySQL
tags:
  - MySQL
  - 索引
  - 性能优化
---

# MySQL 索引优化初体验

今天被一个查询坑惨了。

一个看起来很简单的 SQL，跑了 30 秒没出结果。查了一下表，100 万条数据，没有索引。

```sql
SELECT * FROM orders WHERE user_id = 123 AND status = 'paid';
```

加了复合索引之后：

```sql
CREATE INDEX idx_user_status ON orders(user_id, status);
```

再跑，0.01 秒。

有点心疼之前等待的时间，但也算是记住了：数据量大了必须加索引。

接下来想研究一下 EXPLAIN怎么看...
