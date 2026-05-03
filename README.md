# Antigravity Login Patch

Bypasses Google account eligibility check for Gemini Code Assist in Antigravity (VS Code fork).

## Problem

When logging in to Antigravity, Google may reject your account with:
> "Your account is not eligible for Gemini Code Assist for individuals at this time"

This patch bypasses both client-side and server-side eligibility checks.

## What it does

1. **proxy-main.cjs** - Intercepts the main process entry point to:
   - Set HTTP/HTTPS proxy for network requests
   - Override `http.globalAgent` and `https.globalAgent` with proxy agents
   - Patch `https.request` and `http.request` to route through proxy

2. **main.js patches** (5 patches total):
   - Bypass local eligibility check (`allowedTiers` / `ineligibleTiers`)
   - Convert `SET_INELIGIBLE` events to `AUTH_SUCCESS`
   - Convert `SET_ERROR` events to `AUTH_SUCCESS`
   - Wrap `onboardUser` and `refreshUserStatus` in try/catch
   - Handle project validation errors gracefully

## Usage

```powershell
# Run as Administrator
.\apply-patch.ps1

# Or specify custom path
.\apply-patch.ps1 -AppPath "C:\path\to\Antigravity\resources\app"
```

## Requirements

- Windows with PowerShell
- Antigravity installed at `G:\Antigravity` (or specify custom path)
- Proxy at `127.0.0.1:11119` (modify `proxy-main.cjs` if different)

## Reverting

```powershell
# Restore original files
Copy-Item "G:\Antigravity\resources\app\out\main.js.bak" "G:\Antigravity\resources\app\out\main.js" -Force

# Edit package.json: change "main" back to "./out/main.js"
```

## Notes

- The proxy configuration in `proxy-main.cjs` is optional. If you don't need a proxy, you can simplify it.
- The eligibility bypass means you can log in, but some Gemini Code Assist features may still be limited by Google's server-side checks.
