# Changelog

本仓库所有发布版本的变更记录。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-09-13

首个正式 Release。

### 新增

- **"三道门槛"完整排障框架**：网络层（`language_server` 不读代理 → DLL 分流）、账号授权（官方 CLI 生成一次性验证链接、自动补全 `&authuser=0`）、账号户口（Google Play 国家决定 Google One / AI Pro 购买资格，含 `1008 UNSUPPORTED_LOCATION` 处置）。
- **`AGENTS.md`**：给 AI 助手的"症状原文 → 关卡 → 修复"速查表，报错原文直接路由到对应 .bat。
- **`build-release.ps1` + GitHub Actions** 自动打包发布流程（打 `v*` tag 即产出 zip 并上传 Release）。
- **Issue 模板**：报错原文 / 产品 / 复现步骤 / 环境 / 日志关键行，形成排障反馈闭环。
- **MIT License**。

### 修复

- 硬编码路径全部可移植化：官方 CLI 目录由专属路径改为 `%LOCALAPPDATA%\agy-cli`，并支持 `AG_CLI_DIR` 覆盖；`fix-ide.bat` 支持 `AG_IDE_DIR` 指定 IDE 目录。
- 代理端口可配置：新增 `AG_PROXY_IP` / `AG_PROXY_PORT` 环境变量，同时支持命令行传参 `fix-xxx.bat <端口>`，README 新增"自定义代理/端口"章节。
- 修正第三方引用错误（`editorss/AntigravityChinesePack` → `Muskupecli/AntigravityChinesePack`）与过时星数（kakajan 90★、Antigravity-Hans 134★）。
- `dist/` 构建产物纳入 `.gitignore`，避免误提交。