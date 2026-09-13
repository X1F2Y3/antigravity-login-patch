# Antigravity 登录修复手册（网络层 + 账号层）

## 这套工具解决什么

Antigravity（反重力）= Google 官方 AI IDE + CLI + 桌面端。在需要代理的网络环境下，登录会卡死。整套问题由**三道独立门槛**叠加而成（前两道管"登得进去"，第三道管"能不能买 Pro/户口地区"），必须分别处理：

| 门槛 | 症状 | 修复 | 工具 |
|---|---|---|---|
| 1. 网络层 | `context deadline exceeded`、卡在 onboarding | DLL 注入强制 language_server 走代理 | `fix-network.bat` |
| 2. 账号层 | 登录"跳转后没反应"、登录页一直 Welcome | 完成 Google 侧 Antigravity 产品授权 | `fix-account.bat` |
| 3. 账号户口（进阶） | 免费档能用但 `one.google.com` 拒绝买 AI Pro："目前尚不支持 Google One"；或含 403 `UNSUPPORTED_LOCATION`(1008) | Google Play 国家切到美国（官方改区通道）后重买 | README 门槛三 |

> 只修其一都会失败。顺序无所谓，但两关都要过。

---

## 根因解释

### 网络层：language_server 不读系统代理（官方 bug）
官方 `language_server.exe`（Go）直连 Google API（`daily-cloudcode-pa.googleapis.com` / `generativelanguage.googleapis.com`），**忽略系统代理和环境变量**。No.72 / No.181（google-antigravity/antigravity-cli）已确认这是多年未修的官方 bug。修复手段只能是**进程级强制分流**：
- 本项目采用 `kakajan/antigravity-patch`（GitHub, 90+★）：向 Antigravity 目录植入 `version.dll`（模拟 version.dll 的代理 DLL），自动注入并接管 `language_server.exe` / `Antigravity.exe` / `node.exe` 的 ConnectEx → 全部流量经指定代理。

**安装目录中出现的文件（罪证）**：
- `version.dll`（主目录 + `resources\bin\`）
- `config.json` / `config.proxy.json`（注入规则）
- `Antigravity-with-proxy.bat`（推荐启动方式）

### 账号层：未做过 Google 侧产品授权
即便网络全通、OAuth 授权也成功，Google 后端仍会返回：
> `Your current account is not eligible for Antigravity. Verify your account to continue.`

官方 UI **静默吞掉这个错误**，表现为"点击登录后跳转但应用无反应"。报错只有在官方 CLI 里会明文显示（用 `antigravity.exe --print=hi` 触发）。修复 = 用 CLI 生成一次性验证链接（`accounts.google.com/signin/continue?...auth_success_gemini`）+ 浏览器授权。

> 注意：CLI 生成的链接末尾是残缺的（`...&authuser` 缺 `=0`），直接打开会报 **400 malformed**。`fix-account.bat` 已自动补全。

---

## 快速使用

### 首次 / 重装后（网络和账号都未知）
```bat
1. 双击 fix-network.bat     :: 下载 patch + 注入 DLL + 写代理 127.0.0.1:11119
2. 重装确认                 :: 重装后 AppData 等保留，凭据：不丢，Google 侧授权：不丢
3. 双击 fix-account.bat     :: 若提示验证链接 → 浏览器授权一次
4. 用 Antigravity-with-proxy.bat 启动
```

### 换新账号后
```bat
只需 fix-account.bat（新账号无授权），网络层修复仍生效。
```

---

## 常见失败定位

| 现象 | 排查 |
|---|---|
| `context deadline exceeded` | 网络层没装好：确认 `version.dll` 在安装目录、日志 `Programs\antigravity\logs\proxy-*.log` 有 `HTTP CONNECT: 隧道建立成功` |
| 登录跳转后没反应 / 一直 Welcome | 账号层没过：跑 fix-account.bat 看有没有验证链接 |
| `one.google.com` 提示"您的 Google 帐户目前尚不支持 Google One"，而地址/支付/卡全是美区 | 门槛三：Play 国家=大陆。`payments.google.com/settings` 把国家改为美国 → `play.google.com` 确认国家=美国 → 回 one.google.com 重买 |
| 403 `UNSUPPORTED_LOCATION` / error 1008 | 免费档：确认出口为干净美区住宅 IP 并重走 OAuth/授权；购买档：按门槛三换 Play 国家 |
| Electron 本地页面 `ERR_TIMED_OUT` | 曾手动设过 HTTPS_PROXY 环境变量 → 删除 `setx HTTPS_PROXY`（DLL 方案不需要它） |
| 打开验证链接 400 | 链接末尾 `&authuser` 缺 `=0`，手动补全，或直接用 fix-account.bat |
| CLI 报 not eligible 且链接打开后要等传播 | Google 侧授权成功后通常立即生效，重启桌面端即可 |

---

## 关键路径速查

- 官方桌面端：`%LOCALAPPDATA%\Programs\antigravity\`
- DLL 日志：`%LOCALAPPDATA%\Programs\antigravity\logs\proxy-*.log`
- LS 日志：`%APPDATA%\Antigravity\logs\language_server.log`
- 凭据：`%USERPROFILE%\.gemini\oauth_creds.json`、`.gemini\google_accounts.json`
- 官方 CLI：`%LOCALAPPDATA%\agy-cli\antigravity.exe`

---

## 为什么旧方案（master 分支）是废的

旧方案是**本地 hack**：改 Electron `main.js` 把资格检查强制置 `true`、把 `SET_INELIGIBLE`/`SET_ERROR` 事件伪造为 `AUTH_SUCCESS`。它只是骗前端"你登录了"，后端照样拒绝，且每次客户端更新（asar 重打包）即失效。本方案不触碰应用代码，全部走系统级/账号级真实通道，更新后续用。