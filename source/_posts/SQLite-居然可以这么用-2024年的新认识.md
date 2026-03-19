---
topic: backend
title: SQLite 居然可以这么用 — 2024年的新认识
date: 2024-12-03 20:15:00
categories:
  - 数据库
  - 后端
tags:
  - SQLite
  - 数据库
  - 轻量级
  - SQL
description: 重新认识 SQLite，不只是嵌入式数据库
---

topic: backend

# SQLite 居然可以这么用 — 2024年的新认识

我一直觉得 SQLite 是个挺鸡肋的东西。说是数据库，但功能有限；说不是吧，它又确实能跑 SQL。这么多年用下来，我对它的印象就是：小型工具里用一用，测试环境撑个场面，仅此而已。

今年因为一个个人项目，不得不认真研究了一下 SQLite。结果发现这玩意儿在 2024 年的今天已经完全不一样了。

## 先说个事实

SQLite 是世界上部署最广泛的数据库引擎。这个说法我以前听过，没当回事。直到今年看到数据：保守估计，全球有超过一万亿个 SQLite 实例在运行，涵盖了手机、应用、浏览器、无人机——基本上你能想到的嵌入式场景全是它。

这个量级是其他所有数据库加起来都打不过的。

## WAL 模式解决了我的痛点

以前最烦 SQLite 的点：读写不能并发。写的时候整个数据库是锁住的，高并发场景直接爆炸。

今年才知道，2010 年 SQLite 就引入了 WAL（Write-Ahead Logging）模式，彻底解决这个问题。

```sql
-- 开启 WAL 模式
PRAGMA journal_mode=WAL;

-- 之后读写就可以并发了
PRAGMA synchronous=NORMAL;
```

开启 WAL 之后，写操作会先写到一个单独的日志文件里，不会阻塞读。读操作也不会阻塞写。对于我那个单用户但读写都挺频繁的个人项目，这个改动让响应时间直接降了 60%。

## JSON 支持比我想象的好用

SQLite 3.38（2022年发布）加入了完整的 JSON 支持，函数库还挺全的。

```sql
-- 存一个 JSON 字段，直接按字段查
CREATE TABLE events (
    id INTEGER PRIMARY KEY,
    name TEXT,
    meta TEXT -- 存 JSON 字符串
);

-- 按 JSON 里的字段查询
SELECT * FROM events
WHERE json_extract(meta, '$.type') = 'click'
  AND json_extract(meta, '$.region') = '华东';

-- 更新 JSON 字段里的某个值
UPDATE events
SET meta = json_set(meta, '$.status', 'processed')
WHERE id = 1;
```

以前这种需求要么拆表，要么把 MySQL 的 JSON 函数搬过来。SQLite 这套操作很顺手，配合 `json_each()` 还能做数组展开。

## 全文搜索，不是凑合用的那种

SQLite 的 FTS5（Full-Text Search 5）我之前试过，太难用就没继续。今年重新看了一下，发现已经相当成熟了。

```sql
-- 创建全文搜索虚拟表
CREATE VIRTUAL TABLE articles_fts USING fts5(
    title,
    content,
    content='articles',
    content_rowid='id'
);

-- 插入数据的时候同步
INSERT INTO articles_fts(rowid, title, content)
SELECT id, title, content FROM articles;

-- 搜索，支持布尔运算
SELECT a.*, bm25(articles_fts) as rank
FROM articles_fts f
JOIN articles a ON a.id = f.rowid
WHERE articles_fts MATCH '"深度学习" AND "优化" NOT "训练"'
ORDER BY rank
LIMIT 20;
```

支持中文分词需要额外配一下 `icu`，但配置好了之后搜索质量很可以。我给博客加站内搜索就是用这个方案，响应速度快得离谱。

## 性能优化几个关键点

说 SQLite 慢的，大概率是没配好。以下几点搞清楚，性能能翻几倍。

**`PRAGMA cache_size`**：默认 2MB，改大点效果显著。

```sql
PRAGMA cache_size = -64000;  -- 64MB，负数表示 KB
```

**`PRAGMA temp_store = MEMORY`**：临时表和排序全部放内存。

```sql
PRAGMA temp_store = MEMORY;
PRAGMA mmap_size = 268435456;  -- 256MB 内存映射
```

**建索引**：这个不用多说，但 SQLite 有个坑——索引在 WAL 模式下的表现和默认模式不一样。`REINDEX` 定期跑一下能让查询保持稳定。

## 实际案例

我的个人博客评论系统，之前用 MongoDB Atlas，后来切到了 SQLite + Cloudflare D1。怎么说呢——

- 查询响应从平均 80ms 降到了 5ms 以内
- 数据库文件只有 12MB，备份就是复制一个文件
- 零运维成本，不需要管连接池

当然，D1 是 Cloudflare 托管的版本，有它的局限性。但如果你的场景是中小型应用，SQLite 的能力其实被严重低估了。

---

回头看，SQLite 在 2024 年的今天已经不是"凑合用"的选择了。WAL 解决了并发问题，JSON 支持补齐了半结构化数据，全文搜索 FTS5 也足够实用。对很多场景来说，上一套 PostgreSQL 的复杂度是完全没必要的。

值得重新认识一下。
