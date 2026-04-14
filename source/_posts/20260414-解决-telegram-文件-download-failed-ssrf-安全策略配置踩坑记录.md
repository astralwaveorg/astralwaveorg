# 解决 Telegram 文件下载失败：一次 SSRF 安全策略配置踩坑记录

## 背景

用户在 Telegram 给 OpenClaw 发文件时遇到"Failed to download media"错误。最开始以为是文件本身的问题，后来发现是 Telegram bot 侧在尝试下载用户发的文件时请求被拦截了。

## 问题排查

错误日志显示：

```
blocked URL fetch (url-fetch) target=https://api.telegram.org/file/bot.../documents/file_40.md 
reason=Blocked: resolves to private/internal/special-use IP address
```

OpenClaw 的 SSRF 安全策略把 Telegram 文件下载的请求拦截了。`api.telegram.org` 的文件下载 CDN 在当前网络环境下（受代理影响）解析到了一个被判定为"私有/内网/特殊用途"的 IP 地址。

查了一下 DNS，`api.telegram.org` 当前解析到 `198.27.124.186`，这是一个公网 IP。但问题在于**在 OpenClaw 运行时**的网络环境（可能受到 Surge 代理的 DNS 劫持），解析到了 fake IP。

## 根因

用户使用 Surge 作为代理。Surge 的 fake IP 机制会把某些域名劫持到特定的 IP 段，以便实现本地代理。RFC 2544 标准定义的基准测试范围 `198.18.0.0/15` 就是 Surge 使用的 fake IP 段。

OpenClaw 的 SSRF 防护默认不允许访问这个范围，所以 Telegram 文件下载请求被误拦截。

## 解决方案

修改 OpenClaw Gateway 配置，添加 RFC 2544 基准测试范围的白名单：

```bash
openclaw config.patch tools.web.fetch.ssrfPolicy.allowRfc2544BenchmarkRange=true
```

这个配置项允许 web_fetch 访问 RFC 2544 定义的基准测试范围 IP（198.18.0.0/15），兼容 Surge、Clash 等fake-IP 代理场景。

## 验证

配置生效后重启 Gateway，用户重新发送文件测试，问题解决。

## 踩坑总结

1. **DNS 解析不一致**：本地 DNS 查询结果和 OpenClaw 运行时的解析结果可能不同（受代理影响）
2. **SSRF 防护误判**：公网 IP 在当前网络环境下被误判为特殊用途 IP
3. **配置修改谨慎**：任何 Gateway 配置修改都需要 schema 验证，不能凭"经验"添加字段

## 适用场景

- 使用 Surge/Clash 等代理软件
- 遇到 Telegram 文件下载失败
- 其他被 SSRF 防护误拦截的外部服务请求

后续如果还有类似问题，可以考虑针对特定域名添加白名单，而不是放宽整个 RFC 2544 范围。