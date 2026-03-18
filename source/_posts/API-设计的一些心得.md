---
topic: backend
title: API 设计的一些心得
date: 2021-05-12 00:45:19
categories:
  - 后端
  - API
tags:
  - API
  - REST
  - 设计
description: 2021年做 API 开发的经验总结，RESTful API 设计规范与最佳实践
---
topic: backend

# API 设计的一些心得

2021 年，做了半年 API 开发。前前后后设计了十几套接口，总结了一些经验。

## 为什么 API 设计重要

API 是系统的门面。

- 对前端：API 好不好用，直接决定开发体验
- 对后端：API 写得好，联调少一半时间
- 对未来：API 改一次，调用方要跟着改一堆

好的 API 设计，让协作更高效。

## RESTful 规范

### 1. URL 要有意义

```
✓ GET    /api/users/123        # 获取用户 123
✓ POST   /api/users            # 创建用户
✓ PUT    /api/users/123        # 更新用户 123
✓ DELETE /api/users/123        # 删除用户 123

✗ GET /api/getUser?id=123    # 动词冗余
✗ POST /api/user/create      # 用 POST 模拟其他方法
```

### 2. 资源命名

- 用名词复数：`/users` 而非 `/user`
- 用小写加连字符：`/user-profiles` 而非 `/userProfiles`
- 层级不要过深：`/users/123/orders/456` 最多三层

### 3. HTTP 方法要对

| 方法 | 语义 | 幂等 |
|------|------|------|
| GET | 查询 | ✓ |
| POST | 创建 | ✗ |
| PUT | 全量更新 | ✓ |
| PATCH | 部分更新 | ✗ |
| DELETE | 删除 | ✓ |

### 4. 状态码要规范

```javascript
// 成功
200 OK                    // 查询/更新成功
201 Created              // 创建成功
204 No Content           // 删除成功

// 客户端错误
400 Bad Request          // 参数错误
401 Unauthorized         // 未认证
403 Forbidden            // 无权限
404 Not Found            // 资源不存在
422 Unprocessable Entity // 业务逻辑错误

// 服务端错误
500 Internal Server Error // 服务器错误
503 Service Unavailable   // 服务不可用
```

### 5. 统一返回格式

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 123,
    "name": "张三",
    "email": "zhangsan@example.com"
  },
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 100
  }
}
```

错误时：

```json
{
  "code": 4001,
  "message": "用户名已存在",
  "data": null
}
```

## 实战经验

### 1. 版本号管理

```nginx
# URL 中带版本
/api/v1/users
/api/v2/users

# 或者用 Header
Accept: application/vnd.myapp.v2+json
```

推荐 URL 方式，更直观。

### 2. 分页

```javascript
// 请求
GET /api/users?page=1&pageSize=20

// 响应
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 1000,
    "totalPages": 50
  }
}
```

### 3. 排序与过滤

```javascript
// 排序
GET /api/users?sort=created_at,desc

// 过滤
GET /api/users?status=active&role=admin

// 组合
GET /api/users?status=active&sort=created_at,desc&page=1&pageSize=20
```

### 4. 模糊搜索

```javascript
GET /api/users?name_like=张&email_like=gmail
```

### 5. 批量操作

```javascript
// 批量创建
POST /api/users/batch
{
  "users": [
    {"name": "张三", "email": "z1@example.com"},
    {"name": "李四", "email": "l4@example.com"}
  ]
}

// 批量更新
PUT /api/users/batch
{
  "users": [
    {"id": 1, "status": "active"},
    {"id": 2, "status": "inactive"}
  ]
}
```

## 安全性

### 1. 认证

```javascript
// Header 方式
Authorization: Bearer <token>

// Cookie 方式（前端慎用）
Cookie: session_id=xxx
```

### 2. 限流

```javascript
// 响应头
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

超过限制返回：

```json
{
  "code": 429,
  "message": "请求过于频繁，请稍后再试"
}
```

### 3. CORS

```javascript
// 后端配置
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', 'https://yourdomain.com')
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE')
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
  next()
})
```

## 文档

好的 API 必须有文档。

推荐工具：
- Swagger / OpenAPI
- Apifox
- Postman

文档示例：

```yaml
/api/users/{id}:
  get:
    summary: 获取用户详情
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: integer
    responses:
      '200':
        description: 成功
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/User'
```

## 总结

API 设计看似简单，实际门道很多。

核心原则：
- **简洁**：URL 清晰，参数明确
- **一致**：风格统一，减少学习成本
- **安全**：认证、限流、校验
- **文档**：好文档省一半沟通成本

这半年最大的感悟：好的 API 是改出来的。多倾听调用方的反馈，持续优化。