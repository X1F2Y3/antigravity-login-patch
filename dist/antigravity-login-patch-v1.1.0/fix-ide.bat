@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Antigravity IDE - fix-ide (网络层 + 汉化)
echo =================================================
echo   Antigravity IDE 网络层修复 + 汉化检查
echo   (IDE 的 language_server 与桌面版同病: 不读代理)
echo =================================================
echo.

rem 可移植配置: 默认本机 Antigravity-Manager 代理; 可用环境变量或命令行参数覆盖
set "PROXY_IP=127.0.0.1"
set "PROXY_PORT=11119"
if not "%AG_PROXY_IP%"=="" set "PROXY_IP=%AG_PROXY_IP%"
if not "%AG_PROXY_PORT%"=="" set "PROXY_PORT=%AG_PROXY_PORT%"
if not "%1"=="" set "PROXY_PORT=%1"
set "IDE_DIR=%LOCALAPPDATA%\Programs\Antigravity IDE"
if not "%AG_IDE_DIR%"=="" set "IDE_DIR=%AG_IDE_DIR%"
set "IDE_LSBIN=%IDE_DIR%\resources\app\extensions\antigravity\bin"
set "IDE_SETTINGS=%APPDATA%\Antigravity IDE\User\settings.json"
echo  [配置] 代理: %PROXY_IP%:%PROXY_PORT%  IDE: %IDE_DIR%  (换端口: fix-ide.bat 端口 / set AG_PROXY_PORT=端口)
echo.

rem ---------- 0. 定位 IDE 安装目录 ----------
if not exist "%IDE_DIR%\Antigravity IDE.exe" (
    echo [ERROR] 未找到 Antigravity IDE。可用 set AG_IDE_DIR=你的目录 指定后重试。
    pause
    exit /b 1
)
echo [0/5] 检测到 IDE: %IDE_DIR%

rem ---------- 1. 准备 patch 源码 ----------
set "PATCH_ZIP=%TEMP%\ag-patch.zip"
set "PATCH_SRC=%TEMP%\ag-patch-src"
set "PATCH_AC=antigravity-patch-main\Antigravity 2\antigravity-proxy-patch"

if not exist "%PATCH_SRC%\%PATCH_AC%\proxy\version.dll" (
    if exist "%PATCH_SRC%" rmdir /s /q "%PATCH_SRC%"
    echo [1/5] 下载 antigravity-patch(kakajan/antigravity-patch)...
    curl.exe -s -L -o "%PATCH_ZIP%" -x "http://%PROXY_IP%:%PROXY_PORT%" "https://github.com/kakajan/antigravity-patch/archive/refs/heads/main.zip"
    if not exist "%PATCH_ZIP%" (
        echo [ERROR] 下载失败, 请检查代理 %PROXY_IP%:%PROXY_PORT% 是否可用。
        pause
        exit /b 1
    )
    powershell -NoProfile -Command "Expand-Archive -Path '%PATCH_ZIP%' -DestinationPath '%PATCH_SRC%' -Force"
)
if not exist "%PATCH_SRC%\%PATCH_AC%\proxy\version.dll" (
    echo [ERROR] 解压失败, 未找到 patch 目录。
    pause
    exit /b 1
)
echo [OK] patch 已就绪。

rem ---------- 2. 关闭 IDE 进程 ----------
echo [2/5] 关闭 Antigravity IDE 相关进程...
taskkill /f /im "Antigravity IDE.exe" >nul 2>nul
taskkill /f /im language_server_windows_x64.exe >nul 2>nul
timeout /t 3 /nobreak >nul

rem ---------- 3. 构建 config.proxy.json 并部署 DLL ----------
echo [3/5] 部署 DLL 注入 + 代理配置...
set "CONFIG=%TEMP%\ag-ide-config.proxy.json"
powershell -NoProfile -Command "$t=Get-Content '%PATCH_SRC%\%PATCH_AC%\config.proxy.template.json' -Raw; $t=$t.Replace('PROXY_HOST','%PROXY_IP%').Replace('PROXY_PORT','%PROXY_PORT%').Replace('PROXY_TYPE','http'); Set-Content -Path '%CONFIG%' -Value $t -Encoding UTF8"

copy /y "%PATCH_SRC%\%PATCH_AC%\proxy\version.dll" "%IDE_DIR%\version.dll" >nul
copy /y "%CONFIG%" "%IDE_DIR%\config.proxy.json" >nul
copy /y "%CONFIG%" "%IDE_DIR%\config.json" >nul

if exist "%IDE_LSBIN%" (
    copy /y "%PATCH_SRC%\%PATCH_AC%\proxy\version.dll" "%IDE_LSBIN%\version.dll" >nul
    copy /y "%CONFIG%" "%IDE_LSBIN%\config.json" >nul
) else (
    echo [WARN] 未找到 LS 目录, 已跳过: %IDE_LSBIN%
)
echo [OK] DLL 已部署 (主目录 + LS bin)。

rem ---------- 4. 写入 IDE User settings.json 代理 ----------
echo [4/5] 写入 IDE settings.json http.proxy...
if not exist "%APPDATA%\Antigravity IDE\User" mkdir "%APPDATA%\Antigravity IDE\User"
powershell -NoProfile -Command "$p='%IDE_SETTINGS%'; $o=[ordered]@{'http.proxy'='http://%PROXY_IP%:%PROXY_PORT%';'http.proxySupport'='override';'http.proxyStrictSSL'=$false;'http.useLocalProxyConfiguration'=$false}; if(Test-Path $p){try{$e=Get-Content $p -Raw|ConvertFrom-Json;$e.PSObject.Properties|ForEach-Object{if(-not $o.Contains($_.Name)){$o[$_.Name]=$_.Value}};$o['http.proxy']='http://%PROXY_IP%:%PROXY_PORT%'}catch{}}; ($o|ConvertTo-Json -Depth 10)|Set-Content $p -Encoding UTF8"
echo [OK] settings.json 已更新。

rem ---------- 5. 汉化检查 ----------
echo [5/5] 检查中文语言包...
if exist "%USERPROFILE%\.antigravity-ide\extensions\MS-CEINTL.vscode-language-pack-zh-hans*" (
    echo [OK] VS Code 中文语言包已安装。
) else (
    echo [提示] 未检测到 VS Code 中文语言包。汉化方法见 README.md。
)
if exist "%USERPROFILE%\Desktop\Antigravity IDE 中文.lnk" (
    echo [OK] 发现 中文快捷方式(antigravity-hans), 请用其启动以保持完整汉化。
)

echo.
echo =================================================
echo  IDE 网络层修复完成!
echo.
echo  启动 IDE 后登录即可。若无需浏览器跳转问题:
echo    - LS 直连已被 version.dll 强制走 %PROXY_IP%:%PROXY_PORT%
echo    - 登录流畅性由 DLL 注入保证
echo =================================================
pause