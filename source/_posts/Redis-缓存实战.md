---
title: Redis 缓存实战
date: 2021-01-25 01:28:53
categories:
  - 后端
  - Redis
tags:
  - Redis
  - 缓存
  - 性能
---

# Redis 缓存实战

终于在项目里用上 Redis 了。

之前一直听说缓存多好用，这次算是真真切切体会到了。

## 场景

用户接口，原来查数据库，每次 200ms。套上 Redis 之后：

```python
# 伪代码
cache_key = f"user:{user_id}"
cached = redis.get(cache_key)

if cached:
    return json.loads(cached)

user = db.query(f"SELECT * FROM users WHERE id = {user_id}")
redis.setex(cache_key, 3600, json.dumps(user))
return user
```

直接干到 5ms。

爽。但是也遇到问题了：
- 缓存穿透
- 缓存雪崩
- 数据一致性问题

得好好研究一下。
