# dsh-sts2

让 DSH 直接玩《杀戮尖塔 2》。

装上之后，DSH 里的 AI 会作为一个**正常玩家（玩家 ID 1001）**，和你、和你的 Steam 好友坐在同一个房间里：能读局面、能出牌、能被打死，也能说话。

它不是观战席、不是托管、不是外挂旁观。

核心定位：**多人游戏永远卡在三缺一——让 AI 坐那个空位。**

---

## 安装

```bash
dsh plugin --profile desktop add link:C:/path/to/dsh-sts2
```

或者从本地目录：

```bash
cd C:/path/to/dsh-sts2
dsh plugin --profile desktop add link:.
```

装完确认 profile 的 `package.json` 里：

```json
{
  "dependencies": { "dsh-sts2": "link:..." },
  "dsh": { "profile": { "bundles": [ ..., "dsh-sts2" ] } }
}
```

**bundle 层的改动要重启 DSH 才生效。**

卸载：

```bash
dsh plugin --profile desktop remove dsh-sts2
```

---

## 游戏侧要准备什么

| 项 | 说明 |
|---|---|
| **STS2-Agent 模组** | 必需。把游戏状态暴露成 MCP 接口 |
| **DirectConnectIP 模组** | 异地联机必需（IP 直连） |
| **Tailscale** | 虚拟局域网，双方加入同一 tailnet 并互相授权 |
| **版本一致** | 所有人同一个游戏版本，否则连不上 |

**模组必须是文件夹**，散放的 dll 不会被加载：

```
正确  mods\STS2Agent\*.dll
错误  mods\STS2Agent.dll
```

进游戏后：

```
F8 -> Connect -> 勾选启用 MCP 服务
```

默认端口分工：

```
8080  人类操作窗口
8081  MCP 服务（本插件连这个）
```

---

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File verify.ps1
```

会检查：8080/8081 是否在听、MCP 接口是否响应、插件是否已挂上。

---

## 怎么用

新开一个 DSH 会话，把 `prompts/ai-play.md` 的内容作为系统提示或第一条消息。

然后正常说话：

```
"帮我打这一局"
"现在该出什么牌"
"看一下场上什么情况"
```

AI 会调用：

| 工具 | 作用 |
|---|---|
| `get_game_state` | 读当前局面（手牌、敌人、血量、能量） |
| `get_available_actions` | 现在能做哪些操作 |
| `act` | 执行一个动作 |
| `wait_until_actionable` | 等动画/切屏 |
| `get_game_data_item` | 查卡牌/遗物/敌人数据 |
| `decide` | 一次拿全状态 + 可选动作 + 建议 |

---

## 常见坑

| 现象 | 原因 | 解决 |
|---|---|---|
| 连不上 8081 | 游戏里没开 MCP 服务 | F8 → Connect → 勾选 |
| 模组列表里看不到 | 文件散放在 mods 根目录 | 改文件夹 |
| 直连找不到房间 | 版本不一致 / 没装 DirectConnectIP | 核对版本 |
| AI 收到打牌指令却一直等 | 提示词里还在等 QQ 消息 | 用 `prompts/ai-play.md` 的硬规则 |
| 越打越慢 | 上下文爆炸 | 40 轮重置一次会话 |

---

## 和 QQ 桥接的关系

这个插件**只负责打牌**。

想让 AI 同时在 QQ 群里说话，那是另一套东西（SnowLuma + qq-bridge），见 [QQ 桥接搭建说明](docs/qq-bridge.md)。

两者可以一起用：桥接负责"她是谁、怎么说话"，本插件负责"她能看见牌桌"。

---

## 文档

- 安装与游戏侧要求（本页）
- [QQ 桥接搭建说明](docs/qq-bridge.md) —— 想让 AI 同时在群里说话，看这份

---

## 许可

MIT。游戏模组（STS2-Agent、DirectConnectIP）版权归各自作者。
