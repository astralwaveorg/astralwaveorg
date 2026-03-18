---
title: Docker 入门小结
date: 2020-02-14 00:55:38
categories:
  - 运维
  - Docker
tags:
  - Docker
  - 容器
  - 入门
---

# Docker 入门小结

总算是把 Docker 装明白了。

之前一直听别人说"容器化"，但不知道具体能干嘛。自己用了两周，感觉真香。

## 几个常用命令

```bash
# 跑容器
docker run -d -p 80:80 nginx

# 看运行状态
docker ps

# 进入容器
docker exec -it container_id /bin/bash

# 看日志
docker logs -f container_id
```

最爽的是，不用再担心"在我电脑上能跑"的问题了。打包好镜像，跑到哪儿都一样。

下一步研究 docker-compose，感觉可以省很多事。
