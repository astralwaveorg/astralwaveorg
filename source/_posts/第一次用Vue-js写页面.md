---
topic: frontend
topic: frontend
title: 第一次用 Vue.js 写页面
date: 2020-09-17 00:38:27
categories:
  - 前端
  - Vue
tags:
  - Vue
  - 前端
  - JavaScript
description: 2020年第一次使用 Vue.js 开发前端页面，从后端到前端的转型经历
---
topic: frontend

# 第一次用 Vue.js 写页面

2020 年之前，我一直在写后端。前端？顶多也就是用 jQuery 糊弄一下。

2020 年，公司项目需要做一个管理后台。老大说："用 Vue 吧，现在流行。"

于是我的前端之路开始了。

## 为什么是 Vue

当时主要考虑了三个框架：React、Vue、Angular。

- Angular：太重，学习曲线陡峭
- React：Facebook 的，JSX 语法一开始不太适应
- Vue：国 人写的，文档中文友好，上手快

最终选了 Vue 3。

## 环境搭建

### 安装 Node.js

```bash
# Mac
brew install node

# 验证
node -v
npm -v
```

### 创建项目

```bash
npm init vue@latest my-project

# 或者使用 Vite（更快）
npm create vite@latest my-project -- --template vue
```

我用的是 Vue CLI：

```bash
npm install -g @vue/cli
vue create my-admin
```

## 第一个组件

Vue 的核心是组件化。

```vue
<template>
  <div class="user-card">
    <h2>{{ user.name }}</h2>
    <p>{{ user.email }}</p>
    <button @click="handleClick">点击</button>
  </div>
</template>

<script>
export default {
  name: 'UserCard',
  props: {
    user: {
      type: Object,
      required: true
    }
  },
  methods: {
    handleClick() {
      this.$emit('click', this.user.id)
    }
  }
}
</script>

<style scoped>
.user-card {
  padding: 16px;
  border: 1px solid #ddd;
  border-radius: 8px;
}
</style>
```

## 数据绑定

Vue 的响应式是真的香。

```javascript
export default {
  data() {
    return {
      count: 0,
      message: 'Hello Vue',
      users: []
    }
  },
  computed: {
    reversedMessage() {
      return this.message.split('').reverse().join('')
    }
  },
  watch: {
    count(newVal, oldVal) {
      console.log(`count 从 ${oldVal} 变成 ${newVal}`)
    }
  }
}
```

## 路由配置

```javascript
// router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import Home from '@/views/Home.vue'
import About from '@/views/About.vue'

const routes = [
  { path: '/', name: 'Home', component: Home },
  { path: '/about', name: 'About', component: About }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
```

## 状态管理：Pinia

后来项目大了，用 Pinia 做状态管理：

```javascript
// stores/user.js
import { defineStore } from 'pinia'

export const useUserStore = defineStore('user', {
  state: () => ({
    userInfo: null,
    token: ''
  }),
  getters: {
    isLoggedIn: (state) => !!state.token
  },
  actions: {
    async login(username, password) {
      const res = await fetch('/api/login', {
        method: 'POST',
        body: JSON.stringify({ username, password })
      })
      const data = await res.json()
      this.token = data.token
      this.userInfo = data.user
    },
    logout() {
      this.token = ''
      this.userInfo = null
    }
  }
})
```

## 踩过的坑

### 坑1：响应式失效

```javascript
// 这样改数据，页面不会更新
this.user.name = '新名字'

// 正确方式
this.user = { ...this.user, name: '新名字' }
```

### 坑2：组件通信

- 父子通信：props + emit
- 兄弟通信：EventBus / Pinia
- 跨级通信：provide / inject

### 坑3：生命周期

```
created → mounted → updated → unmounted
```

异步操作要在 mounted 之后执行。

## 整体评价

Vue 上手确实快，文档清晰，生态也很完善。

但我的 CSS 还是写得烂...每次都是调样式调半天。

前后端分离是真趋势，2020 年之后，我开始认真补前端了。

## Vue 3 组合式 API

后来 Vue 3 出了 Composition API，更灵活：

```vue
<script setup>
import { ref, computed, onMounted } from 'vue'

const count = ref(0)
const double = computed(() => count.value * 2)

function increment() {
  count.value++
}

onMounted(() => {
  console.log('组件挂载完成')
})
</script>

<template>
  <div>
    <p>Count: {{ count }}</p>
    <p>Double: {{ double }}</p>
    <button @click="increment">+1</button>
  </div>
</template>
```

Composition API 让逻辑复用更方便了。