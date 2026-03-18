---
robots: noindex,nofollow
sitemap: false
menu_id: social
header: false
sidebar: [sociallist, welcome, recent]
title: 友链
h1: ''
breadcrumb: false
logo:
  subtitle: 快来交换友链吧～
comment_title: 快来交换友链吧～
giscus:
  data-mapping: number
  data-term: 22
---

{% banner 朋友们 一起成长的技术小伙伴 bg:/assets/banner/friends.jpg %}
{% navbar active:/friends/ [友链](/friends/) [关于](/about/) %}
{% endbanner %}

{% friends api:https://raw.github.xaox.cc/xaoxuu/friends/output/v2/data.json %}

{% box [欢迎] 友链交换说明 %}

如果你我的网站有内容交集，欢迎交换友链！

但请先满足以下条件：
- 原创内容为主，非采集站
- 网站稳定可访问
- 内容安全合规

满足条件后，请在下方评论或者直接提 Issue 申请。

{% endbox %}

{% quot icon:hashtag 朋友们近期的文章 %}

{% timeline type:fcircle limit:10 api:https://raw.github.xaox.cc/xaoxuu/friends-rss-generator/output/data.json %}
{% endtimeline %}

{% quot icon:hashtag 如何交换友链？ %}

1. **基本要求**：
   - HTTPS 站点，内容原创
   - 至少五篇原创文章
   - 无不良内容

2. **互动要求**：
   - 先行礼后君子，先打声招呼
   - 可以在文章下面留言，或者 GitHub 交流

{% folding 申请友链 %}

{% note color:warning 请确保满足以上条件再申请 %}

**第一步：留言或提 Issue**

在本文下方评论，或者去 GitHub 新建 Issue。

**第二步：添加本站友链**

```yaml
title: Astral Wave
url: https://astralwave.org
avatar: https://astralwave.org/assets/icon.svg
```

**第三步：等待审核**

一般 24 小时内处理，超过一周未处理可以提醒我。

{% endfolding %}