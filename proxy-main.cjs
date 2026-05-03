const PROXY_URL = 'http://127.0.0.1:11119';
const fs = require('fs');
const path = require('path');

const logFile = path.join(process.env.APPDATA || '', 'Antigravity', 'proxy-patch.log');
const log = (msg) => {
  const line = `[${new Date().toISOString()}] ${msg}\n`;
  try { fs.appendFileSync(logFile, line); } catch(e) {}
};

try { fs.writeFileSync(logFile, ''); } catch(e) {}
log(`[ProxyPatch] Starting with proxy: ${PROXY_URL}`);

process.env.HTTP_PROXY = PROXY_URL;
process.env.HTTPS_PROXY = PROXY_URL;
process.env.http_proxy = PROXY_URL;
process.env.https_proxy = PROXY_URL;
process.env.ALL_PROXY = PROXY_URL;
process.env.NO_PROXY = 'localhost,127.0.0.1';
process.env.GLOBAL_AGENT_HTTP_PROXY = PROXY_URL;
process.env.GLOBAL_AGENT_HTTPS_PROXY = PROXY_URL;
process.env.GLOBAL_AGENT_NO_PROXY = 'localhost,127.0.0.1';

try {
  const { app, session } = require('electron');
  if (app) {
    app.commandLine.appendSwitch('proxy-server', PROXY_URL);
    app.commandLine.appendSwitch('proxy-bypass-list', 'localhost,127.0.0.1');
    log('[ProxyPatch] Chromium proxy switches added');
    const setupProxy = () => {
      if (session?.defaultSession) {
        session.defaultSession.setProxy({
          proxyRules: `http=${PROXY_URL};https=${PROXY_URL}`,
          proxyBypassRules: 'localhost,127.0.0.1'
        }).then(() => log('[ProxyPatch] Session proxy OK')).catch(e => log(`[ProxyPatch] Session proxy err: ${e.message}`));
      }
    };
    app.isReady() ? setupProxy() : app.on('ready', setupProxy);
  }
} catch(e) { log(`[ProxyPatch] Electron err: ${e.message}`); }

try { require('global-agent').bootstrap(); log('[ProxyPatch] global-agent OK'); } catch(e) { log(`[ProxyPatch] global-agent err: ${e.message}`); }

try {
  const https = require('https');
  const http = require('http');
  const { HttpsProxyAgent } = require('https-proxy-agent');
  const { HttpProxyAgent } = require('http-proxy-agent');
  https.globalAgent = new HttpsProxyAgent(PROXY_URL);
  http.globalAgent = new HttpProxyAgent(PROXY_URL);
  log('[ProxyPatch] globalAgent overridden');
  const origHttpsReq = https.request;
  https.request = function(opts, cb) {
    if (typeof opts === 'object' && opts) {
      const host = opts.hostname || opts.host || '';
      if (!host.includes('localhost') && !host.includes('127.0.0.1')) {
        if (!opts.agent) opts.agent = https.globalAgent;
      }
    }
    return origHttpsReq.apply(this, arguments);
  };
  const origHttpReq = http.request;
  http.request = function(opts, cb) {
    if (typeof opts === 'object' && opts) {
      const host = opts.hostname || opts.host || '';
      if (!host.includes('localhost') && !host.includes('127.0.0.1')) {
        if (!opts.agent) opts.agent = http.globalAgent;
      }
    }
    return origHttpReq.apply(this, arguments);
  };
  log('[ProxyPatch] https/http.request patched');
} catch(e) { log(`[ProxyPatch] https patch err: ${e.message}`); }

log('[ProxyPatch] Loading main.js');
module.exports = require('./main.js');
