# QQ 桥接搭建说明（让 AI 在群里说话）

> 这一份比 MCP 配置复杂得多，因为每个人环境不同。
> 阅读顺序：先跑通 MCP（见 README.md），再搭 QQ 桥接。

---

## 它解决什么问题

DSH 本身是个本地 AI 客户端，它不认识 QQ。
桥接程序干的事：**把 QQ 的消息搬进 DSH，把 DSH 说的话搬回 QQ**，并在中间处理唤醒、限流、人设、记忆。

```
QQ 群 ──> SnowLuma（OneBot 实现）──> qq-bridge（Node）──> DSH HTTP API
                     ↑                                        │
                     └──────────── 发消息 ────────────────────┘
```

---

## 组件清单

| 组件 | 作用 | 必需 |
|---|---|---|
| **SnowLuma** | QQ 协议端，把 QQ 变成 OneBot 接口 | 是 |
| **qq-bridge** | 中间层：转发、唤醒、人设、限流 | 是 |
| **DSH** | 真正生成回复的 AI | 是 |
| **Node.js** | 跑 qq-bridge | 是 |

---

## 第一步：SnowLuma

1. 下载 SnowLuma，放在固定目录，例如 `C:\DSQQ\SNOWLUMA`
2. 登录你的 QQ 小号（**不要用主号**，有封号风险）
3. 开启 OneBot v11 服务：
   ```
   WebSocket  3001
   HTTP       3000
   access_token  自己设一个随机字符串
   ```
4. 记住这个 token，下一步要用

---

## 第二步：qq-bridge

```bash
cd C:\DSQQ\qq-bridge
npm install
node src/bridge.js
```

首次启动会生成 `config.json`，需要改这些：

```jsonc
{
  "dsh": {
    "baseUrl": "http://127.0.0.1:XXXXX",   // DSH 的端口，每次启动可能变
    "provider": "deepseek-account",
    "model": "deepseek-flash",
    "reasoningEffort": "high"
  },
  "snowluma": {
    "wsUrl": "ws://127.0.0.1:3001",        // 上一步的 WS 端口
    "httpUrl": "http://127.0.0.1:3000",
    "accessToken": "上一步设的 token"
  },
  "ownerQQ": 你的QQ号,                      // 只有这个人能私聊指挥
  "allow": {
    "private": [好友QQ号],
    "groups": [群号]                        // 白名单，不在里面的群一律不理
  },
  "consolePort": 3100                       // 网页控制台
}
```

**白名单是硬边界**：不在 `allow` 里的群/人，桥接不会读也不会回。

---

## 第三步：接上 DSH 的 MCP

桥接给 DSH 提供三个 MCP 服务（在你自己的 `cordis.patch.yml` 里配）：

```yaml
- insert:
    - id: mcp-snowluma
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: snowluma
        transport: stdio
        command: '<node.exe 路径>'
        args: ['<qq-bridge>/src/mcp-snowluma-safe.js']
        toolCallTimeoutMs: 725000
- insert:
    - id: mcp-snowluma-host
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: snowluma-host
        transport: stdio
        command: '<node.exe 路径>'
        args: ['<qq-bridge>/src/mcp-host-server.js']
```

**如果要让 AI 能打杀戮尖塔**，还要把 `mcp__sts2__` 加进工具白名单：

```
插件目录：~/.dsh/plugins/qq-agent-presets/qq-tool-restrict.mjs
找到 SAFE_PREFIXES 数组，加一行：
  'mcp__sts2__',
```

**改完必须重启 DSH**，否则 preset 不重新加载。

---

## 第四步：人设（角色卡）

桥接目录下 `roles/` 里放人设文件，例如：

```
roles/人物速查.md    她是谁、怎么说话、跟谁什么关系
roles/小鲸鱼.md      备用人格/另一个群
```

写人设的关键几条（我踩过的）：

```
· 明确"谁能指挥她"（owner）
· 明确括号动作的用法：私聊可以写（笑），群里只允许（乐）（绷）这种
· 明确"打游戏时不要调等消息工具"——否则她会在游戏里站着不动
· 删掉所有"总结/汇报/收尾"式的表达，真人不会那么说话
```

---

## 第五步：唤醒策略

桥接支持多种唤醒方式（都在 `config.json` 的 `social` 里）：

```jsonc
{
  "social": {
    "enabled": true,
    "triggerProbability": 0.1,      // 普通消息 10% 概率唤醒
    "contextWindow": 20,            // 带最近 20 条上下文
    "activeDurationMinMs": 1200000  // 活跃状态最短 20 分钟
  }
}
```

还能按会话单独设（`qq_set_wake_config`）：@ 唤醒、名字唤醒、关键词、被拍、指定人发言、任意消息。

**别把唤醒调太密**。我试过 10 秒一次，桥接直接"会话繁忙"排队，回复延迟爆炸。

---

## 常见坑

| 现象 | 原因 | 解决 |
|---|---|---|
| 一直"会话繁忙" | 唤醒太频繁，上一轮还没结束 | 拉长间隔，或降低触发概率 |
| 回复越来越慢 | DSH 会话上下文太大 | 定期重置会话（我设 40 轮自动重置）|
| 说到一半断掉 | 模型输出被截断 | 提高 max_tokens，或在提示词里限制句数 |
| 游戏里站住不动 | 她调了等消息工具（阻塞 120 秒） | 提示词里写死"打牌时禁止调 waitMessages" |
| 改了配置没生效 | preset 需要重启 | 重启 DSH |
| 群里不理人 | 群号不在白名单 | 加进 `allow.groups` |

---

## 成本

```
一条群消息回复 ≈ 2000~5000 token
DeepSeek 计费下，一天活跃聊天 ≈ 几块钱
打游戏时更贵：一步 4000 token，一局 1.5~2.5 块
```

---

## 安全提醒

```
· 用 QQ 小号，别用主号
· access_token 别外泄
· allow 白名单是最重要的边界，别设成 allowAll
· 桥接只在本机监听，不要暴露到公网
```
