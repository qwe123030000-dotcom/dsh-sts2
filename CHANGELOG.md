# 更新记录

## 0.1.0

首个版本。

- 通过 bundle patch 往 profile 里插入 `sts2` 的 MCP 客户端（streamable-http，默认 `http://127.0.0.1:8081/mcp`）
- 附带打牌提示词 `prompts/ai-play.md`（含"打牌时禁止调等消息工具"的硬规则）
- 附带自检脚本 `verify.ps1`
- 安装方式：`dsh plugin --profile desktop add link:<路径>`
