---
title: React Hooks 深入理解
date: 2022-11-08 01:25:33
categories:
  - 前端
  - React
tags:
  - React
  - Hooks
  - 原理
---

# React Hooks 深入理解

用了两年 React，今天总算是把 Hooks 原理搞明白了一点。

## useState

```jsx
const [count, setCount] = useState(0);
```

每次渲染，useState 返回一个数组：
- 当前状态值
- 更新状态的函数

## useEffect

```jsx
useEffect(() => {
  console.log('mount or update');
  
  return () => {
    console.log('cleanup');
  };
}, [deps]);
```

第二个参数是依赖数组：
- `[]`: 只在 mount 时执行
- `[dep]`: dep 变化时执行
- 不写: 每次渲染都执行

## 闭包问题

```jsx
const [count, setCount] = useState(0);

useEffect(() => {
  const timer = setInterval(() => {
    console.log(count); // 这里会一直是 0！
  }, 1000);
  
  return () => clearInterval(timer);
}, []); // 依赖数组为空
```

解决：用 `setCount(c => c + 1)` 或者把 count 放依赖数组里。

原理理解了，用起来更顺手。
