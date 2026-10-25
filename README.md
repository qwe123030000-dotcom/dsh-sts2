# dsh-sts2

让 DSH 直接玩《杀戮尖塔 2》。

装上之后，DSH 里的 AI 会作为一个**正常玩家（玩家 ID 1001）**，和你、和你的 Steam 好友坐在同一个房间里：能读局面、能出牌、能被打死，也能说话。

它不是观战席、不是托管、不是外挂旁观。

核心定位：**多人游戏永远卡在三缺一——让 AI 坐那个空位。**

---

## 一条链接，全自动

把你的 DSH 打开，直接跟它说：

> 读 https://github.com/qwe123030000-dotcom/dsh-sts2 的 README，把插件装好、模组装好，然后验证能不能连上。

它会做这些事：

1. `dsh plugin --profile desktop add github:qwe123030000-dotcom/dsh-sts2`
2. 提示你重启 DSH（插件只在启动时组装）
3. 跑 `tools/install-mods.ps1`，自动找到游戏目录并把两个模组装进 `mods\`
4. 跑 `verify.ps1` 检查端口和 MCP 接口

**最后只剩一件它替你做不了的事**：进游戏按 `F8` → `Connect` → 勾选 MCP 服务。

---

## 仓库里自带模组

```
mods/STS2AIAgent/        STS2AIAgent.dll / .pck / mod_id.json
mods/DirectConnectIP/    DirectConnectIP.dll / .pck / .json
```

模组版权归各自作者（见 `THIRD_PARTY.md`），这里只是打包方便一键安装。
版本：DirectConnectIP 2.111.0（适配游戏 v0.111），STS2-Agent v0.16.2。

手动装也可以：

```powershell
powershell -ExecutionPolicy Bypass -File tools/install-mods.ps1
# 找不到目录时手动指定
powershell -ExecutionPolicy Bypass -File tools/install-mods.ps1 -GameDir "D:\SteamLibrary\steamapps\common\Slay the Spire 2"
```

---

## 手动安装插件

```bash
dsh plugin --profile desktop add github:qwe123030000-dotcom/dsh-sts2
```

装完**必须重启 DSH**——插件只在启动时组装，不重启就看不到 `sts2_*` 这些工具。

确认 profile 的 `package.json` 里出现了：

```json
{
  "dependencies": { "dsh-sts2": "github:..." },
  "dsh": { "profile": { "bundles": [ ..., "dsh-sts2" ] } }
}
```

不想要了（可选）：

```bash
dsh plugin --profile desktop remove dsh-sts2
```

---

## 游戏侧要准备什么

| 项 | 说明 |
|---|---|
| **STS2-Agent 模组** | 必需，本仓库自带，`install-mods.ps1` 会装 |
| **DirectConnectIP 模组** | 异地联机必需，本仓库自带 |
| **Tailscale** | 虚拟局域网，双方加入同一 tailnet 并互相授权 |
| **版本一致** | 所有人同一个游戏版本，否则连不上 |

模组必须放成**文件夹**，散放的 dll 不会被加载（脚本已经按正确结构放好）：

```
正确  mods\STS2AIAgent\*.dll
错误  mods\STS2AIAgent.dll
```

进游戏后：

```
F8 -> Connect -> 勾选启用 MCP 服务
```

端口分工：

```
8080  人类操作窗口
8081  MCP 服务（本插件连这个）
```

---

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File verify.ps1
```

检查：8080/8081 是否在听、MCP 接口是否响应、插件是否已挂上。

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
| 模组列表里看不到 | 文件散放在 mods 根目录 | 用 `install-mods.ps1` 重装 |
| 直连找不到房间 | 版本不一致 / 没装 DirectConnectIP | 核对版本 |
| AI 收到打牌指令却一直等 | 提示词里还在等 QQ 消息 | 用 `prompts/ai-play.md` 的硬规则 |
| 越打越慢 | 上下文爆炸 | 40 轮重置一次会话 |

---

## 装不上怎么办（国内网络 / pnpm 拦截）

**症状 1：pnpm 报 `git-hosted plugins build on install ...`**

pnpm 默认不信任 git 包的 prepare 脚本，需要放行。打开 profile 的 `pnpm-workspace.yaml`，加上：

```yaml
allowBuilds:
  - dsh-sts2
```

**症状 2：报 `Failed to connect to github.com:443`**

国内直连 github 常常不通。让 git 把 https 换成 ssh（需要先在 GitHub 上配好 SSH key）：

```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

**症状 3：什么都不想折腾**

下载仓库 zip，解压到本地，用本地路径安装：

```bash
dsh plugin --profile desktop add link:C:/path/to/dsh-sts2
```

---

## 和 QQ 桥接的关系

这个插件**只负责打牌**。

想让 AI 同时在 QQ 群里说话，那是另一套东西（SnowLuma + qq-bridge），见 [QQ 桥接搭建说明](docs/qq-bridge.md)。

两者可以一起用：桥接负责"她是谁、怎么说话"，本插件负责"她能看见牌桌"。

---

## 文档

- 安装与游戏侧要求（本页）
- [QQ 桥接搭建说明](docs/qq-bridge.md) —— 想让 AI 同时在群里说话，看这份
- [第三方说明](THIRD_PARTY.md)

---

## 许可

MIT（本项目代码）。游戏模组版权归各自作者，详见 `THIRD_PARTY.md`。
