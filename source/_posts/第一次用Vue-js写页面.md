---
title: 第一次用 Vue.js 写页面
date: 2020-09-17 00:38:27
categories:
  - 前端
  - Vue
tags:
  - Vue
  - 前端
  - JavaScript
---

# 第一次用 Vue.js 写页面

之前全是写后端，今天算是正式碰前端了。

用了 Vue，不得不说比原生 JS 省心多了。数据绑定、组件化，确实香。

```html
<div id="app">
  <h1>{{ title }}</h1>
  <ul>
    <li v-for="item in items">{{ item.name }}</li>
  </ul>
</div>

<script>
new Vue({
  el: '#app',
  data: {
    title: 'Hello Vue',
    items: [{name: 'a'}, {name: 'b'}]
  }
})
</script>
```

不过 CSS 还是写得烂...能不能有人帮我写样式啊。

前后端分离是真趋势，我得好好补一下前端了。
