---
topic: backend
topic: backend
title: Redis 缓存实战
date: 2021-01-25 01:28:53
categories:
  - 后端
  - Redis
tags:
  - Redis
  - 缓存
  - 性能
description: 项目中第一次使用 Redis 做缓存，从 200ms 优化到 5ms
---
topic: backend

# Redis 缓存实战

2021 年初，公司项目遇到了性能瓶颈。数据库被查询打爆了，老大让我研究一下 Redis 缓存。

## 问题背景

接口响应时间越来越慢，数据库 CPU 经常性 100%。

分析了一下，90% 的请求都是查询：
- 用户信息查询
- 商品列表查询
- 配置参数查询

这些数据的特点：变动不频繁，但被频繁读取。

## 解决方案：Redis 缓存

### 第一次尝试

```python
import redis
import json

r = redis.Redis(host='localhost', port=6379, db=0)

def get_user(user_id):
    # 先查缓存
    cache_key = f"user:{user_id}"
    cached = r.get(cache_key)
    
    if cached:
        return json.loads(cached)
    
    # 缓存没有，查数据库
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")
    
    # 写入缓存，过期时间 1 小时
    r.setex(cache_key, 3600, json.dumps(user))
    
    return user
```

效果：
- 优化前：200ms
- 优化后：5ms

爽！但随之而来的是各种问题。

## 遇到的问题

### 问题1：缓存穿透

大量请求查询不存在的数据，直接打到数据库。

比如：黑客用不存在的 user_id 疯狂请求。

解决：布隆过滤器 + 空值缓存

```python
def get_user(user_id):
    # 布隆过滤器判断是否存在
    if not bf.exists(f"user:{user_id}"):
        return None
    
    cache_key = f"user:{user_id}"
    cached = r.get(cache_key)
    
    if cached:
        return json.loads(cached)
    
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")
    
    if user:
        r.setex(cache_key, 3600, json.dumps(user))
    else:
        # 空值也缓存，过期时间短一点
        r.setex(cache_key, 60, "")
    
    return user
```

### 问题2：缓存雪崩

大量缓存同时过期，请求全部打到数据库。

比如：高峰期大量缓存同时过期。

解决：随机过期时间 + 永不过期

```python
# 随机过期时间，范围 1-2 小时
import random
expire_time = random.randint(3600, 7200)

r.setex(cache_key, expire_time, json.dumps(user))
```

### 问题3：数据一致性

数据库更新了，缓存还是旧的。

解决：
1. 先更新数据库，再删缓存（延迟删）
2. 延迟双删

```python
def update_user(user_id, data):
    # 1. 先更新数据库
    db.execute(f"UPDATE users SET ... WHERE id = {user_id}")
    
    # 2. 删除缓存
    r.delete(f"user:{user_id}")
    
    # 3. 延迟双删（防并发）
    time.sleep(0.1)
    r.delete(f"user:{user_id}")
```

## Redis 数据结构

Redis 不只是缓存，还有很多强大的数据结构。

### String

最常用，存储字符串、JSON。

```python
r.set("key", "value")
r.get("key")

# 数字操作
r.incr("counter")
r.decr("counter")
```

### Hash

存储对象，类似于 Python 的 dict。

```python
r.hset("user:1", "name", "张三")
r.hset("user:1", "age", "25")
r.hgetall("user:1")

# 批量操作
r.hmset("user:1", {"name": "张三", "age": "25"})
```

### List

队列、列表。

```python
r.lpush("tasks", "task1")
r.lpop("tasks")

# 范围查询
r.lrange("tasks", 0, 10)
```

### Set

去重、交集、并集。

```python
r.sadd("tags:python", "t1", "t2", "t3")
r.smembers("tags:python")

# 交集
r.sinter("tags:python", "tags:ai")
```

### Sorted Set

排行榜、权重队列。

```python
# 添加分数
r.zadd("leaderboard", {"user1": 100, "user2": 90})

# 按分数排序
r.zrevrange("leaderboard", 0, 10, withscores=True)
```

## Redis 集群

单节点 Redis 不够用？考虑集群方案：

### 1. 主从复制

一主多从，读写分离。

```bash
# 主节点
redis-server --port 6379

# 从节点
redis-server --port 6380 --replicaof 127.0.0.1 6379
```

### 2. Redis Sentinel

自动故障转移。

### 3. Redis Cluster

数据分片，自动路由。

## 总结

Redis 是后端开发的必备技能。

缓存用得好，接口快到飞起。但也要注意：
- 缓存不是银弹
- 一致性问题是难点
- 内存有限，合理规划

从那以后，我养成了习惯：任何频繁查询的数据，先考虑缓存。