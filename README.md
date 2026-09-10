<div align="right">

[![中文](https://img.shields.io/badge/语言-中文-blue)](#中文) [![English](https://img.shields.io/badge/Language-English-blue)](#english)

</div>

<a id="中文"></a>

# Antigravity 登录修复套件

> 中文（翻自实际排障记录）；解决 Antigravity（反重力）在大陆/代理网络环境下的登录卡死问题。
> **正道**：真实打通网络 + 完成账号授权，不改任何应用代码。

## 为什么一直"登不进去"？

Antigravity 登录卡死由**两道独立门槛**叠加造成，只修其一必然失败：

### 门槛一：网络层 —— `language_server` 不读代理（官方 bug）
官方 `language_server.exe`（Go 程序）直连 Google API，**忽略系统代理 + 忽略 HTTP(S)_PROXY 环境变量**（官方 CLI 仓库 issue #72 / #181 已确认为多年未修 bug）。大陆网络下表现为：

```
There was an unexpected issue setting up your account.
context deadline exceeded
```

修复：**DLL 注入**（`kakajan/antigravity-patch`，90+★）——在 Antigravity 目录植入 `version.dll`，接管 `language_server.exe` 等进程的出站连接，强制全部走本地代理。安装后日志可见：

```
HTTP CONNECT: 隧道建立成功, 目标=172.217.119.4:443, 代理=127.0.0.1:11119
```

### 门槛二：账号层 —— 从未完成 Google 侧产品授权（隐藏开关）
网络通了之后才暴露：就算浏览器 OAuth 成功，后端仍会拒绝：

> `Your current account is not eligible for Antigravity. Verify your account to continue.`

官方 **UI 会静默吞掉这个错误** → 表现就是"点击登录跳转，但应用毫无反应 / 一直 Welcome"。只有官方 CLI 会明文报错。修复 = 用官方 CLI（`google-antigravity/antigravity-cli`）生成一次性验证链接，浏览器完成 `auth_success_gemini` 授权即可。

> 坑：CLI 生成的链接末尾残缺（`...&authuser` 缺 `=0`），直接打开报 **400 that's an error**。本套件已自动补全。

---

## 使用（30 秒）

**首次 / 重装后，两步全走：**

```bat
# 1. 修网络（下载 patch → 注入 DLL → 写代理 127.0.0.1:11119）
fix-network.bat

# 2. 修账号（询问后端资格，若不合格自动打印验证链接并复制到剪贴板）
fix-account.bat
```

**换新账号后**，只需 `fix-account.bat`（新账号没有授权）；网络层修复跟账号无关，永久生效。

**启动**：以后请用安装目录下的 `Antigravity-with-proxy.bat`（或直接双击 `Antigravity.exe`，同目录 `version.dll` 自动生效）。

---

## 持久性（重装 / 换号会不会回到原点？）

| 状态 | 重装应用 | 换新账号 |
|---|---|---|
| 网络修复（DLL+config） | 会丢 → 重跑 fix-network.bat（1 分钟） | 不丢 |
| 凭据/token（`.gemini\`） | 不丢 | 被新号覆盖 |
| **账号资格验证**（Google 侧云端状态） | **不丢** | **丢 → 每号一次 fix-account.bat** |

一句话：**重装不慌（跑 fix-network）；换号只补一次账号验证（跑 fix-account）。**

---

## 关键文件/路径

| 项 | 路径 |
|---|---|
| 安装目录 | `%LOCALAPPDATA%\Programs\antigravity\` |
| DLL 分流日志 | `安装目录\logs\proxy-*.log` |
| LS 日志 | `%APPDATA%\Antigravity\logs\language_server.log` |
| 凭据 | `%USERPROFILE%\.gemini\oauth_creds.json` `.gemini\google_accounts.json` |
| 官方 CLI | `C:\Users\Administrator\agy-cli\antigravity.exe` （fix-account 自动下载） |

更多排障细节见 [recovery.md](recovery.md)。

---

## 对比旧版（master 分支，已废弃）

旧方案是**本地 hack**：改 Electron `main.js` 把资格检查强制置 `true`、伪造 `AUTH_SUCCESS` 事件，只骗前端、后端照样拒绝，且客户端一更新就失效。本套件全程系统级/账号级真实通道，**不触碰应用代码，更新后续用**。

---

## 致谢

- `kakajan/antigravity-patch` — 网络层 DLL 强制分流
- `google-antigravity/antigravity-cli` — 官方 CLI（账号验证入口 + issue 佐证）
- `lbjlaq/Antigravity-Manager` — 账号/代理管理参考

<a id="english"></a>

# Antigravity Login Fix Suite

This is a **fix kit** (not a hack): it unblocks Antigravity login in proxied networks by fixing two independent gates —— (1) the official `language_server` ignores system proxy (patch via `kakajan/antigravity-patch` DLL injection), and (2) the Google account has never completed the product eligibility verification (one-time browser authorization via official CLI). No application code is modified.