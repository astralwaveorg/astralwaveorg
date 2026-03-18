---
title: TypeScript 真香警告
date: 2022-02-18 01:18:45
categories:
  - 前端
  - TypeScript
tags:
  - TypeScript
  - JavaScript
  - 类型系统
---

# TypeScript 真香警告

之前一直拒绝 TypeScript，觉得麻烦。

最近项目用了 TS，打脸了。

## 类型带来安全感

```typescript
interface User {
  id: number;
  name: string;
  email?: string;
}

function getUser(id: number): Promise<User> {
  return fetch(`/api/users/${id}`)
    .then(res => res.json());
}
```

编辑器直接报错，总比上线后 crash 好。

## 几个技巧

1. `strict: true` 一定要开
2. 善用 `interface` 和 `type`
3. `unknown` 比 `any` 安全
4. 配置 `tsconfig.json` 要仔细

现在让我回去写原生 JS，反而不会了...
