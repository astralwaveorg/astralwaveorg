---
title: 私有化部署 LLM 的一些经验
date: 2024-02-12 00:47:53
categories:
  - AI
  - LLM
  - 运维
tags:
  - LLM
  - Ollama
  - 私有化
  - 部署
---

# 私有化部署 LLM 的一些经验

不想一直依赖 API，决定自己部署。

## 选型

- **Ollama**: 最简单，Mac 也能跑
- **llama.cpp**: 性能强，但配置复杂
- **vLLM**: 生产级别，但需要 GPU

## Mac 上跑 Ollama

```bash
brew install ollama
ollama serve
ollama run llama2
```

M 芯片Mac 居然能跑 7B 模型，虽然慢，但能用。

## 服务器部署

用了 3090，跑了 70B。

```bash
docker run -d -v models:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

## 经验

1. 显存不够就量化
2. 批量推理用 vLLM
3. 网络要做好安全

下一步调优 prompt 和 RAG...
