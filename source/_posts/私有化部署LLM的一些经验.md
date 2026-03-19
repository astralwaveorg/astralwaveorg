---
topic: ai
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
description: 本地部署大模型，Ollama + GPU 完整配置指南
---

# 私有化部署 LLM 的一些经验

2024 年，不想一直依赖 API，决定自己部署。

原因：
- API 费用越来越贵
- 数据隐私考虑
- 想本地调试和微调

## 选型

### 方案对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| Ollama | 简单，Mac 也能跑 | 功能有限 |
| llama.cpp | 性能强 | 配置复杂 |
| vLLM | 生产级别 | 需要 GPU |
| Text Generation WebUI | 界面友好 | 占用高 |

最终选了 **Ollama**，先跑起来再说。

## Mac 本地部署

### 安装

```bash
brew install ollama
```

### 运行

```bash
# 列出可用模型
ollama list

# 拉取模型
ollama pull llama2
ollama pull mistral
ollama pull codellama

# 运行
ollama run llama2
```

### 效果

M1/M2 Mac 跑 7B 模型：
- 能跑，但慢
- 适合测试和调试
- 生产环境还是需要服务器

## 服务器部署

### 硬件

- GPU：RTX 3090 (24GB)
- 内存：64GB
- 系统：Ubuntu 22.04

### Docker 部署

```bash
# 拉取镜像
docker pull ollama/ollama

# 运行
docker run -d \
  --name ollama \
  -v models:/root/.ollama \
  -p 11434:11434 \
  ollama/ollama

# 进入容器
docker exec -it ollama bash

# 拉取模型
ollama pull llama2:70b
```

### GPU 支持

```bash
# 安装 nvidia-docker
apt install nvidia-docker2

# 运行时加 GPU
docker run -d \
  --gpus all \
  --name ollama \
  -v models:/root/.ollama \
  -p 11434:11434 \
  ollama/ollama
```

## API 调用

### OpenAI 兼容 API

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"  # 任意字符串
)

response = client.chat.completions.create(
    model="llama2",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)

print(response.choices[0].message.content)
```

### 直接调用

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

## 性能优化

### 1. 量化

模型太大？量化！

```bash
# Q4_0 量化（最小，最慢）
# Q4_1 量化
# Q5_0, Q5_1 平衡
# Q8_0 接近原版

ollama run llama2:70b-q4_0
```

| 量化 | 70B 原始大小 | 量化后大小 |
|------|-------------|------------|
| FP16 | 140GB | 35GB |
| Q8_0 | - | 70GB |
| Q4_1 | - | 35GB |
| Q4_0 | - | 26GB |

### 2. 批量推理

vLLM 适合批量：

```bash
docker run -d \
  --gpus all \
  -p 8000:8000 \
  -v ./models:/models \
  vllm/vllm-openai \
  --model meta-llama/Llama-2-70b-hf \
  --tensor-parallel-size 2
```

### 3. 量化工具

```bash
# 安装 llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# 量化
python convert.py models/llama-2-70b/
python quantize ./models/llama-2-70b/ggml-model-f16.gguf ./models/llama-2-70b/ggml-model-q4_0.gguf q4_0
```

## 经验总结

### 1. 显存不够就量化

70B 模型 FP16 需要 140GB 显存，大部分机器跑不了。

量化到 Q4_0，35GB，3090 就能跑。

### 2. 网络安全

本地部署也要注意安全：

```nginx
# 只允许内网访问
location / {
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;
}
```

### 3. 选对模型

| 用途 | 推荐模型 |
|------|----------|
| 对话 | llama2, mistral |
| 代码 | codellama |
| 中文 | qwen, chatglm |

## 下一步

- 微调模型
- RAG 接入
- Agent 应用

路还长，慢慢来。