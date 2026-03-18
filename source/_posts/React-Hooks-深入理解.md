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
description: React Hooks 原理详解，从 useState 到 useEffect 彻底搞懂
---

# React Hooks 深入理解

用了两年 React，Hooks 天天用，但原理一直没深究。

2022 年底，总算是把原理搞明白了点。

## Hooks 是什么

Hook 是 React 16.8 引入的新特性，让函数组件也能用 state 和生命周期。

```jsx
// 类组件
class Counter extends React.Component {
  state = { count: 0 };
  
  render() {
    return <div>{this.state.count}</div>;
  }
}

// 函数组件 + Hooks
function Counter() {
  const [count, setCount] = useState(0);
  
  return <div>{count}</div>;
}
```

## useState

### 基本用法

```jsx
const [count, setCount] = useState(0);
```

返回：
- `count`：当前状态值
- `setCount`：更新状态的函数

### 原理

每次渲染，useState 返回一个数组：
- 当前状态值
- 更新状态的函数（始终是稳定的）

```javascript
// 伪代码实现
let state;
let setters = [];

function useState(initialValue) {
  if (!state) {
    state = initialValue;
  }
  
  const index = setters.length;
  
  if (!setters[index]) {
    setters[index] = (newValue) => {
      state = newValue;
      // 触发重新渲染
      render();
    };
  }
  
  return [state, setters[index]];
}
```

### 闭包问题

```jsx
// ❌ 常见错误
function Counter() {
  const [count, setCount] = useState(0);
  
  useEffect(() => {
    const timer = setInterval(() => {
      console.log(count); // 这里永远是 0！
    }, 1000);
    
    return () => clearInterval(timer);
  }, []); // 依赖数组为空
  
  return <div>{count}</div>;
}

// ✅ 正确方式
function Counter() {
  const [count, setCount] = useState(0);
  
  useEffect(() => {
    const timer = setInterval(() => {
      // 用函数式更新
      setCount(c => c + 1);
    }, 1000);
    
    return () => clearInterval(timer);
  }, []);
  
  return <div>{count}</div>;
}

// ✅ 或者把 count 放依赖数组
function Counter() {
  const [count, setCount] = useState(0);
  
  useEffect(() => {
    const timer = setInterval(() => {
      console.log(count);
    }, 1000);
    
    return () => clearInterval(timer);
  }, [count]); // 依赖 count
  
  return <div>{count}</div>;
}
```

## useEffect

### 基本用法

```jsx
useEffect(() => {
  // 副作用逻辑
  
  return () => {
    // 清理函数
  };
}, [deps]); // 依赖数组
```

### 执行时机

- 首次渲染后执行
- 依赖变化后执行
- 组件卸载时执行清理

### 依赖数组

```jsx
// 不写：每次渲染都执行
useEffect(() => {
  console.log('每次都执行');
});

// 空数组：只在 mount 时执行一次
useEffect(() => {
  console.log('只执行一次');
}, []);

// 有依赖：依赖变化时执行
useEffect(() => {
  console.log('count 变化了', count);
}, [count]);
```

### 清理函数

```jsx
useEffect(() => {
  // 订阅
  const subscription = api.subscribe(data => {
    setData(data);
  });
  
  // 返回清理函数
  return () => {
    subscription.unsubscribe();
  };
}, []);
```

## useRef

### 基本用法

```jsx
const inputRef = useRef(null);

function handleClick() {
  inputRef.current.focus();
}

return <input ref={inputRef} />;
```

### 特点

- 变化不触发重新渲染
- 值持久化
- 可变

### 用途

```jsx
// 1. 访问 DOM
const inputRef = useRef(null);

// 2. 存储可变值（不触发渲染）
const countRef = useRef(0);
countRef.current++;

// 3. 上一轮的值
const prevCountRef = useRef(0);
prevCountRef.current = count;
```

## useCallback vs useMemo

### useCallback

缓存函数：

```jsx
const memoizedCallback = useCallback(() => {
  doSomething(a, b);
}, [a, b]);
```

### useMemo

缓存计算结果：

```jsx
const memoizedValue = useMemo(() => {
  return computeExpensiveValue(a, b);
}, [a, b]);
```

### 区别

- `useCallback`：缓存函数
- `useMemo`：缓存值

```jsx
// 等价于
const memoizedCallback = useCallback(fn, deps);
// 等价于
const memoizedCallback = useMemo(() => fn, deps);
```

## 自定义 Hook

### 什么是自定义 Hook

封装可复用的逻辑：

```javascript
function useLocalStorage(key, initialValue) {
  const [value, setValue] = useState(() => {
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : initialValue;
  });
  
  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);
  
  return [value, setValue];
}

// 使用
function App() {
  const [name, setName] = useLocalStorage('name', '');
  return <input value={name} onChange={e => setName(e.target.value)} />;
}
```

### 常见自定义 Hook

```javascript
// useDebounce
function useDebounce(value, delay) {
  const [debouncedValue, setDebouncedValue] = useState(value);
  
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    
    return () => clearTimeout(handler);
  }, [value, delay]);
  
  return debouncedValue;
}

// usePrevious
function usePrevious(value) {
  const ref = useRef();
  useEffect(() => {
    ref.current = value;
  }, [value]);
  return ref.current;
}

// useOnClickOutside
function useOnClickOutside(ref, handler) {
  useEffect(() => {
    const listener = (event) => {
      if (!ref.current || ref.current.contains(event.target)) {
        return;
      }
      handler(event);
    };
    
    document.addEventListener('mousedown', listener);
    document.addEventListener('touchstart', listener);
    
    return () => {
      document.removeEventListener('mousedown', listener);
      document.removeEventListener('touchstart', listener);
    };
  }, [ref, handler]);
}
```

## Hooks 规则

### 1. 只在顶层调用

```jsx
// ❌ 错误：循环中调用
for (let i = 0; i < 10; i++) {
  const [state, setState] = useState(i); // 错误！
}

// ✅ 正确
const [states, setStates] = useState(new Array(10).fill(0));
```

### 2. 只在 React 函数中调用

```jsx
// ❌ 错误：普通函数中调用
function handleClick() {
  const [count, setCount] = useState(0); // 错误！
}

// ✅ 正确：React 函数组件中
function App() {
  const [count, setCount] = useState(0);
  // ...
}
```

### 3. 使用 ESLint 插件

```bash
npm install eslint-plugin-react-hooks
```

## 总结

Hooks 让函数组件更强大。

- **useState**：状态管理
- **useEffect**：副作用
- **useRef**：DOM 和可变值
- **useMemo/useCallback**：性能优化
- **自定义 Hook**：逻辑复用

理解原理，用起来更顺手。