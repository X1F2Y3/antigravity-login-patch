@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Antigravity - fix-network (网络层修复)
echo =================================================
echo   Antigravity 网络层一键修复
echo   (针对 language_server 不读系统代理的官方 bug)
echo =================================================
echo.

set "PROXY_IP=127.0.0.1"
set "PROXY_PORT=11119"

rem ---------- 1. 定位安装目录 ----------
set "DETECTED="
if exist "%LOCALAPPDATA%\Programs\antigravity\Antigravity.exe" set "DETECTED=%LOCALAPPDATA%\Programs\antigravity"
if exist "%LOCALAPPDATA%\Programs\Antigravity\Antigravity.exe" set "DETECTED=%LOCALAPPDATA%\Programs\Antigravity"
if exist "%LOCALAPPDATA%\Programs\Antigravity IDE\Antigravity.exe" set "DETECTED=%LOCALAPPDATA%\Programs\Antigravity IDE"
if exist "%LOCALAPPDATA%\Programs\antigravity_v2\Antigravity.exe" set "DETECTED=%LOCALAPPDATA%\Programs\antigravity_v2"

if not defined DETECTED (
    echo [ERROR] 未找到 Antigravity 安装目录。请手动设置 APP_DIR 变量后重试。
    echo         常见位置: %LOCALAPPDATA%\Programs\antigravity
    pause
    exit /b 1
)
echo [1/5] 检测到安装目录: !DETECTED!

rem ---------- 2. 准备 patch 源码 ----------
set "PATCH_ZIP=%TEMP%\ag-patch.zip"
set "PATCH_SRC=%TEMP%\ag-patch-src"
set "PATCH_AC=antigravity-patch-main\Antigravity 2\antigravity-proxy-patch"

if exist "%PATCH_SRC%" rmdir /s /q "%PATCH_SRC%"
echo [2/5] 下载 antigravity-patch(kakajan/antigravity-patch)...

curl.exe -s -L -o "%PATCH_ZIP%" -x "http://%PROXY_IP%:%PROXY_PORT%" "https://github.com/kakajan/antigravity-patch/archive/refs/heads/main.zip"
if not exist "%PATCH_ZIP%" (
    echo [ERROR] 下载失败, 请检查代理 %PROXY_IP%:%PROXY_PORT% 是否可用。
    pause
    exit /b 1
)

powershell -NoProfile -Command "Expand-Archive -Path '%PATCH_ZIP%' -DestinationPath '%PATCH_SRC%' -Force"
if not exist "%PATCH_SRC%\%PATCH_AC%" (
    echo [ERROR] 解压失败, 未找到 patch 目录。
    pause
    exit /b 1
)
echo [OK] patch 已解压。

rem ---------- 3. 写入用户代理配置 ----------
echo [3/5] 写入代理配置: %PROXY_IP%:%PROXY_PORT%
set "SETTINGS=%PATCH_SRC%\%PATCH_AC%\proxy.settings.txt"

> "%SETTINGS%" (
    echo # Edit these values before running Install-Patch.bat on a new PC.
    echo # Lines starting with # are ignored.
    echo.
    echo HOST=%PROXY_IP%
    echo PORT=%PROXY_PORT%
    echo TYPE=http
)

rem allowed_ports 同步加入代理端口, 防止注入规则拒绝
powershell -NoProfile -Command "$p='%PATCH_SRC%\%PATCH_AC%\config.proxy.template.json'; $j=Get-Content $p -Raw | ConvertFrom-Json; $j.proxy_rules.allowed_ports += %PROXY_PORT%; $j.proxy.HttpType='http'; ($j | ConvertTo-Json -Depth 10) | Set-Content $p -Encoding UTF8"

echo [OK] 代理配置已写入。

rem ---------- 4. 关闭 Antigravity 进程 ----------
echo [4/5] 关闭 Antigravity 相关进程...
taskkill /f /im Antigravity.exe >nul 2>nul
taskkill /f /im language_server.exe >nul 2>nul
taskkill /f /im node.exe /fi "WINDOWTITLE eq Antigravity*" >nul 2>nul
timeout /t 3 /nobreak >nul

rem ---------- 5. 运行安装脚本 ----------
echo [5/5] 安装 DLL 注入 (version.dll)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PATCH_SRC%\%PATCH_AC%\Install-Patch.ps1" -Quiet -AntigravityDir "!DETECTED!"
if errorlevel 1 (
    echo [ERROR] 安装脚本执行失败, 请查看上方报错。
    pause
    exit /b 1
)

echo.
echo =================================================
echo  网络层修复完成!
echo.
echo  以后每次启动 Antigravity 请使用:
echo     "!DETECTED!\Antigravity-with-proxy.bat"
echo  或直接双击 Antigravity.exe (同目录 version.dll 会生效)
echo =================================================
pause