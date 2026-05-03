# Antigravity Login Patch
# Bypasses Google account eligibility check for Gemini Code Assist
# Usage: Run this script as Administrator

param(
    [string]$AppPath = "G:\Antigravity\resources\app"
)

$ErrorActionPreference = "Stop"
$MainJs = Join-Path $AppPath "out\main.js"
$MainJsBak = Join-Path $AppPath "out\main.js.bak"
$ProxyMain = Join-Path $AppPath "out\proxy-main.cjs"
$PackageJson = Join-Path $AppPath "package.json"

Write-Host "=== Antigravity Login Patch ===" -ForegroundColor Cyan
Write-Host "App path: $AppPath"

# Check files exist
if (-not (Test-Path $MainJs)) { Write-Host "ERROR: main.js not found at $MainJs" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $PackageJson)) { Write-Host "ERROR: package.json not found" -ForegroundColor Red; exit 1 }

# Backup main.js if not already backed up
if (-not (Test-Path $MainJsBak)) {
    Write-Host "Backing up main.js..." -ForegroundColor Yellow
    Copy-Item $MainJs $MainJsBak
    Write-Host "Backup created: main.js.bak"
} else {
    Write-Host "Backup already exists, skipping." -ForegroundColor Yellow
    # Restore from backup first to ensure clean patches
    Copy-Item $MainJsBak $MainJs
    Write-Host "Restored main.js from backup for clean patch."
}

# Copy proxy-main.cjs
Write-Host "Installing proxy-main.cjs..." -ForegroundColor Yellow
Copy-Item (Join-Path $PSScriptRoot "proxy-main.cjs") $ProxyMain -Force
Write-Host "proxy-main.cjs installed."

# Patch package.json
Write-Host "Patching package.json..." -ForegroundColor Yellow
$pkg = Get-Content $PackageJson -Raw
if ($pkg -match '"main"\s*:\s*"\./out/main\.js"') {
    $pkg = $pkg -replace '"main"\s*:\s*"\./out/main\.js"', '"main": "./out/proxy-main.cjs"'
    Set-Content $PackageJson $pkg -NoNewline
    Write-Host "package.json patched: main -> proxy-main.cjs"
} else {
    Write-Host "package.json already patched or different format, checking..." -ForegroundColor Yellow
    if ($pkg -match '"main"\s*:\s*"\./out/proxy-main\.cjs"') {
        Write-Host "Already patched." -ForegroundColor Green
    } else {
        Write-Host "WARNING: Unknown main field format, please check manually." -ForegroundColor Red
    }
}

# Patch main.js
Write-Host "Patching main.js..." -ForegroundColor Yellow
$content = Get-Content $MainJs -Raw

# Patch 1: Bypass eligibility check (s=!!n||!a -> s=true)
$old1 = 'const s=!!n||!a'
$new1 = 'const s=true'
if ($content.Contains($old1)) {
    $content = $content.Replace($old1, $new1)
    Write-Host "  [1/5] Eligibility check bypassed" -ForegroundColor Green
} else {
    Write-Host "  [1/5] Already patched or not found" -ForegroundColor Yellow
}

# Patch 2: P method - always send AUTH_SUCCESS
$old2 = 'P(t){const r=Ade(t),n=vde(t);if(r)this.t.send({type:"SET_INELIGIBLE",message:Twe(t)??"Account verification required",verificationUrl:r});else if(n)this.t.send({type:"SET_INELIGIBLE",message:n.message,appealUrl:n.appealUrl,appealLinkText:n.appealLinkText});else{const a=Twe(t)??"An error occurred";this.t.send({type:"SET_ERROR",message:a})}'
$new2 = 'P(t){this.t.send({type:"AUTH_SUCCESS",tokenInfo:null})}'
if ($content.Contains($old2)) {
    $content = $content.Replace($old2, $new2)
    Write-Host "  [2/5] P method patched to always succeed" -ForegroundColor Green
} else {
    Write-Host "  [2/5] Already patched or not found" -ForegroundColor Yellow
}

# Patch 3: Outer catch - always send AUTH_SUCCESS
$old3 = '}catch(n){this.g.error("Error confirming user for service:",n),this.P(n?.response?.data),this.h.fire({errorType:"error",reason:Twe(n?.response?.data),verificationUrl:Ade(n?.response?.data),tosErrorInfo:vde(n?.response?.data)}),this.C.logObservabilityData(MT({type:"CONFIRM_USER_FOR_SERVICE_ERROR",sensitiveData:{loadCodeAssistResponse:JSON.stringify(r),error:n'
$new3 = '}catch(n){this.t.send({type:"AUTH_SUCCESS",tokenInfo:null})'
if ($content.Contains($old3)) {
    $content = $content.Replace($old3, $new3)
    Write-Host "  [3/5] Outer catch patched to always succeed" -ForegroundColor Green
} else {
    Write-Host "  [3/5] Already patched or not found" -ForegroundColor Yellow
}

# Patch 4: onboardUser/refreshUserStatus wrapped in try/catch
$old4 = 'if(s){await this.y.onboardUser("free-tier",t),await this.refreshUserStatus(t);const u=Ufe(t);this.F.pushUpdate(u),this.t.send({type:"AUTH_SUCCESS",tokenInfo:t})}'
$new4 = 'if(s){try{await this.y.onboardUser("free-tier",t)}catch(e){}try{await this.refreshUserStatus(t)}catch(e){}const u=Ufe(t);this.F.pushUpdate(u),this.t.send({type:"AUTH_SUCCESS",tokenInfo:t})}'
if ($content.Contains($old4)) {
    $content = $content.Replace($old4, $new4)
    Write-Host "  [4/5] onboardUser/refreshUserStatus error-proofed" -ForegroundColor Green
} else {
    Write-Host "  [4/5] Already patched or not found" -ForegroundColor Yellow
}

# Patch 5: U method catch - send AUTH_SUCCESS instead of SET_ERROR
$old5 = 'try{await this.U(t,y)}catch(v){this.t.send({type:"SET_ERROR",message:v instanceof Error?v.message:String(v)}),this.h.fire({errorType:"error",reason:v instanceof Error?v.message:String(v)});retur'
$new5 = 'try{await this.U(t,y)}catch(v){this.t.send({type:"AUTH_SUCCESS",tokenInfo:t});return}n}else{const y=this.H.getFocusedWindow'
if ($content.Contains($old5)) {
    $content = $content.Replace($old5, $new5)
    Write-Host "  [5/5] U method catch patched" -ForegroundColor Green
} else {
    Write-Host "  [5/5] Already patched or not found" -ForegroundColor Yellow
}

# Save patched main.js
Set-Content $MainJs $content -NoNewline
Write-Host "main.js patched and saved." -ForegroundColor Green

Write-Host ""
Write-Host "=== Patch complete! ===" -ForegroundColor Green
Write-Host "Restart Antigravity and login with your Google account."
Write-Host ""
Write-Host "To revert: restore main.js from main.js.bak and reset package.json"
