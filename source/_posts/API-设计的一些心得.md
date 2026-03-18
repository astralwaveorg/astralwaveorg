---
title: API 设计的一些心得
date: 2021-05-12 00:45:19
categories:
  - 后端
  - API
tags:
  - API
  - REST
  - 设计
---

# API 设计的一些心得

做了半年 API 开发，总结几点：

## 1. URL 要有意义

```
GET /api/users/123  ✓
GET /api/getUser?id=123  ✗
```

## 2. HTTP 方法要对

- GET: 查询
- POST: 创建
- PUT: 更新
- DELETE: 删除

## 3. 状态码要规范

- 200: 成功
- 400: 参数错误
- 401: 未认证
- 403: 无权限
- 404: 资源不存在
- 500: 服务器错误

## 4. 返回格式统一

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

别返回一会儿对象一会儿数组，很烦。

## 5. 版本号

```
/api/v1/users
/api/v2/users
```

不然后面改结构会死人的。
