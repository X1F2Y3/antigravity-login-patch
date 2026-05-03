<div align="right">

[![中文](https://img.shields.io/badge/语言-中文-blue)](#中文) [![English](https://img.shields.io/badge/Language-English-blue)](#english)

</div>

<a id="中文"></a>

# Antigravity 登录补丁

绕过 Antigravity（VS Code 魔改版）登录时 Google 账号资格检查的限制。

## 问题

登录 Antigravity 时，Google 可能会拒绝你的账号：

> "Your account is not eligible for Gemini Code Assist for individuals at this time"
>
> （你的账号目前没有资格使用 Gemini Code Assist 个人版）

即使浏览器端登录成功，应用内的 token 交换仍会因资格检查失败而报错。

## 原理

本补丁做了两件事：

**1. 代理拦截 (`proxy-main.cjs`)**
- 拦截 Electron 主进程入口，设置 HTTP/HTTPS 代理
- 覆盖 `http.globalAgent` / `https.globalAgent` 为代理版本
- 补丁 `https.request` / `http.request` 强制走代理

**2. 资格检查绕过 (`main.js` 补丁 × 5)**
- 将本地资格检查结果强制为 `true`（绕过 `allowedTiers` / `ineligibleTiers`）
- 将 `SET_INELIGIBLE` 事件转为 `AUTH_SUCCESS`（绕过验证错误）
- 将 `SET_ERROR` 事件转为 `AUTH_SUCCESS`（绕过服务器拒绝）
- `onboardUser` / `refreshUserStatus` 包裹 try/catch（忽略服务器端拒绝）
- 项目验证错误优雅处理

## 使用方法

```powershell
# 以管理员身份运行
.\apply-patch.ps1

# 或指定自定义路径
.\apply-patch.ps1 -AppPath "C:\path\to\Antigravity\resources\app"
```

运行后重启 Antigravity，用 Google 账号登录即可。

## 环境要求

- Windows + PowerShell
- Antigravity 默认安装在 `G:\Antigravity`（否则用 `-AppPath` 指定）
- 代理地址 `127.0.0.1:11119`（如不同请修改 `proxy-main.cjs`）

## 还原

```powershell
# 恢复原始文件
Copy-Item "G:\Antigravity\resources\app\out\main.js.bak" "G:\Antigravity\resources\app\out\main.js" -Force

# 编辑 package.json：把 "main" 改回 "./out/main.js"
```

## 注意事项

- `proxy-main.cjs` 中的代理配置是可选的，不需要代理可以简化
- 绕过资格检查后可以正常登录，但部分 Gemini Code Assist 功能仍可能受 Google 服务器端限制

---

<a id="english"></a>

# Antigravity Login Patch

Bypass Google account eligibility check when logging into Antigravity (a VS Code fork).

## Problem

When logging in to Antigravity, Google may reject your account:

> "Your account is not eligible for Gemini Code Assist for individuals at this time"

Even after successful browser authentication, the in-app token exchange fails due to eligibility checks.

## How It Works

**1. Proxy Interception (`proxy-main.cjs`)**
- Intercepts Electron main process entry to set HTTP/HTTPS proxy
- Overrides `http.globalAgent` / `https.globalAgent` with proxy agents
- Patches `https.request` / `http.request` to route through proxy

**2. Eligibility Bypass (`main.js` patches × 5)**
- Forces local eligibility check result to `true` (bypasses `allowedTiers` / `ineligibleTiers`)
- Converts `SET_INELIGIBLE` events to `AUTH_SUCCESS` (bypasses verification errors)
- Converts `SET_ERROR` events to `AUTH_SUCCESS` (bypasses server rejections)
- Wraps `onboardUser` / `refreshUserStatus` in try/catch (ignores server-side rejections)
- Graceful handling of project validation errors

## Usage

```powershell
# Run as Administrator
.\apply-patch.ps1

# Or specify custom path
.\apply-patch.ps1 -AppPath "C:\path\to\Antigravity\resources\app"
```

After running, restart Antigravity and log in with your Google account.

## Requirements

- Windows with PowerShell
- Antigravity installed at `G:\Antigravity` (or use `-AppPath` for custom path)
- Proxy at `127.0.0.1:11119` (modify `proxy-main.cjs` if different)

## Reverting

```powershell
# Restore original files
Copy-Item "G:\Antigravity\resources\app\out\main.js.bak" "G:\Antigravity\resources\app\out\main.js" -Force

# Edit package.json: change "main" back to "./out/main.js"
```

## Notes

- The proxy configuration in `proxy-main.cjs` is optional. Simplify if you don't need a proxy.
- The eligibility bypass allows login, but some Gemini Code Assist features may still be limited by Google's server-side checks.
