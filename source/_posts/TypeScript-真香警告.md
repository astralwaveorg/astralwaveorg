---
topic: frontend
title: TypeScript 真香警告
date: 2022-02-18 01:18:45
categories:
  - 前端
  - TypeScript
tags:
  - TypeScript
  - JavaScript
  - 类型系统
description: 从拒绝到真香，TypeScript 给我带来了哪些改变
---
topic: frontend

# TypeScript 真香警告

2022 年之前，我一直拒绝 TypeScript。

"类型？NativeScript 就行了啊。"
"编译？浪费时间。"
"类型定义？写 any 就行。"

2022 年初，项目强制用 TS。用了三个月后，我道歉了。

## 为什么之前拒绝

1. **麻烦**：要写类型定义，代码变长了
2. **不习惯**：JavaScript 写久了，觉得类型是累赘
3. **学习成本**：新语法、新概念，又要学

但真正用了之后，我发现我错了。

## 真香现场

### 1. 编辑器报错提前知道

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

// 假如我传了字符串
getUser('123'); // 报错：Argument of type 'string' is not assignable to parameter of type 'number'.
```

还没运行，编辑器就告诉我错了。

### 2. 重构不再怕

```typescript
// 原来
function processUser(user) {
  return user.name.toUpperCase();
}

// 现在
function processUser(user: User): string {
  return user.name.toUpperCase();
}
```

改 User 接口，所有调用的地方都会报错。

### 3. 代码即文档

```typescript
// 看这个函数签名，我就知道怎么用
function createOrder(
  items: OrderItem[],
  shippingAddress: Address,
  paymentMethod: PaymentMethod,
  couponCode?: string
): Promise<Order>
```

参数类型、返回值，一目了然。

## 核心概念

### 1. 基础类型

```typescript
// 原始类型
let name: string = '张三';
let age: number = 25;
let isActive: boolean = true;
let hobbies: string[] = ['coding', 'music'];
let config: [string, number] = ['host', 8080];

// any 和 unknown
let anything: any = 'hello';      // 任意类型，静音
let something: unknown = 'hello'; // 任意类型，但使用时需要判断
```

### 2. 接口 vs 类型

```typescript
// 接口
interface User {
  id: number;
  name: string;
}

// 类型
type User = {
  id: number;
  name: string;
};

// 接口可以扩展
interface User {
  email: string;
}

// 类型可以用 & 组合
type Admin = User & { role: 'admin' };
```

### 3. 泛型

```typescript
// 简单泛型
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}

// 约束
function longest<T extends { length: number }>(a: T, b: T): T {
  return a.length > b.length ? a : b;
}

// 泛型接口
interface ApiResponse<T> {
  code: number;
  data: T;
  message: string;
}

function fetchUser(): ApiResponse<User> {
  // ...
}
```

### 4.  Utility Types

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
}

// 全部可选
type PartialUser = Partial<User>;

// 全部必填
type RequiredUser = Required<User>;

// 只读
type ReadonlyUser = ReadonlyUser;

// 提取部分
type UserBasic = Pick<User, 'id' | 'name'>;

// 排除部分
type UserPublic = Omit<User, 'password'>;
```

## 实战技巧

### 1. strict 模式一定要开

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}
```

### 2. 用 unknown 而不是 any

```typescript
// any：随便用，不报错
function parseJSON(json: any): any {
  return JSON.parse(json);
}

// unknown：用之前要判断
function parseJSON(json: string): object {
  const result = JSON.parse(json);
  if (typeof result !== 'object') {
    throw new Error('Invalid JSON');
  }
  return result;
}
```

### 3. 类型守卫

```typescript
function process(value: string | number) {
  if (typeof value === 'string') {
    // TypeScript 知道这是 string
    return value.toUpperCase();
  } else {
    // TypeScript 知道这是 number
    return value.toFixed(2);
  }
}

// typeof 之外
function process(value: User | Admin) {
  if ('role' in value) {
    // 这是 Admin
    console.log(value.role);
  } else {
    // 这是 User
    console.log(value.name);
  }
}
```

### 4. 类型断言

```typescript
// as 断言
const data = response.data as User;

// 非空断言
const name = user!.name;

// 双重断言
const name = response.data as unknown as User;
```

## 常见错误与解决

### 1. Object is possibly null

```typescript
// 解决1：可选链
const name = user?.name;

// 解决2：非空判断
if (user) {
  const name = user.name;
}

// 解决3：类型守卫
function isUser(obj: User | Admin): obj is User {
  return 'name' in obj;
}
```

### 2. Type is not assignable

```typescript
// 明明类型一样，为什么报错？
function greet(name: string) { }
function greet(name: string | undefined) { }

// 解决：函数重载
function greet(name: string): void;
function greet(name?: string): void;
function greet(name?: string) { }
```

### 3. 第三方库没有类型

```bash
# 安装类型定义
npm install @types/lodash

# 自己写声明
declare module 'some-library' {
  export function doSomething(): void;
}
```

## 感悟

TypeScript 不是负担，是保障。

它让代码更可靠，让协作更顺畅，让重构更安心。

现在让我回去写原生 JS，反而不会了。

**真香。**