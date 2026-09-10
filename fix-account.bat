@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Antigravity - fix-account (账号资格验证)
echo =================================================
echo   Antigravity 账号资格一键验证
echo   (重装 / 换新账号后第一步: 让 Google 侧授权你的账号)
echo =================================================
echo.
echo  说明: Antigravity 需要你的 Google 账号完成一次产品授权
echo        (auth_success_gemini), 否则登录只会"跳转后没反应"。
echo        CLI 会自动生成验证链接, 你在浏览器点开授权即可。
echo.

set "PROXY_IP=127.0.0.1"
set "PROXY_PORT=11119"
set "CLI_DIR=C:\Users\Administrator\agy-cli"
set "CLI_EXE=%CLI_DIR%\antigravity.exe"

rem ---------- 1. 检查/安装官方 CLI ----------
if not exist "%CLI_EXE%" (
    echo [1/4] 未检测到官方 CLI, 正在下载 agy_cli(1.2.0)...
    curl.exe -s -L -o "%TEMP%\agy_cli.zip" -x "http://%PROXY_IP%:%PROXY_PORT%" "https://github.com/google-antigravity/antigravity-cli/releases/latest/download/agy_cli_windows_x64.zip"
    if not exist "%TEMP%\agy_cli.zip" (
        echo [ERROR] CLI 下载失败, 请检查代理。
        pause
        exit /b 1
    )
    powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\agy_cli.zip' -DestinationPath '%CLI_DIR%' -Force"
)
if not exist "%CLI_EXE%" (
    echo [ERROR] CLI 解压失败。
    pause
    exit /b 1
)
echo [1/4] 官方 CLI 就绪。

rem ---------- 2. 触发资格检查, 抓取验证链接 ----------
echo [2/4] 正在询问后端账号资格 (需 5-30 秒)...
set "HTTPS_PROXY=http://%PROXY_IP%:%PROXY_PORT%"
set "HTTP_PROXY=http://%PROXY_IP%:%PROXY_PORT%"
set "NO_PROXY=localhost,127.0.0.1"
set "ERRLOG=%TEMP%\fix-account-err.txt"

"%CLI_EXE%" --print=hi >nul 2>"%ERRLOG%"

rem ---------- 3. 从输出提取验证链接 ----------
set "URL="
for /f "usebackq delims=" %%L in (`findstr /c:"accounts.google.com/signin/continue" "%ERRLOG%"`) do set "URL=%%L"
set "URL=!URL:*https=https!"

echo [3/4] 直线输出的检查结果:
findstr "eligible ineligible Verify" "%ERRLOG%" | findstr /v accounts
echo.

if not defined URL (
    echo.
    echo [结果] 未发现验证链接 —— 这通常是好消息:
    if exist "%ERRLOG%" findstr /i "Hello\!" "%ERRLOG%" >nul 2>nul
    echo       如果上面无 "not eligible" 字样, 说明账号已合格, 直接启动 Antigravity 即可。
    pause
    exit /b 0
)

rem 修复 CLI 生成的残缺 URL (末位 authuser 缺失 =0)
echo !URL!| findstr /e "authuser" >nul && set "URL=!URL!=0"

echo.
echo =================================================
echo  请复制下面的链接, 用你的 Pro 账号在浏览器登录,
echo  完成"身份验证成功"页面(含 Antigravity 授权)后关闭。
echo =================================================
echo.
echo !URL!
echo.
echo !URL!| clip
echo (已复制到剪贴板)
echo.
echo 完成后: 启动 Antigravity-with-proxy.bat 即可正常登录。
pause