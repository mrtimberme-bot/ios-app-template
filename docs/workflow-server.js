#!/usr/bin/env node
'use strict';

const http             = require('http');
const fs               = require('fs');
const path             = require('path');
const { execFile }     = require('child_process');
const os               = require('os');

const PORT       = 7842;
const DOCS_DIR   = __dirname;
const HTML_FILE  = path.join(DOCS_DIR, 'workflow-visual.html');
const STATE_FILE = path.join(DOCS_DIR, 'workflow-state.json');

// ─── Whitelisted commands (no user input in args) ──────────────────────────────
const SAFE_CMDS = {
  'git-status':  { bin: 'git',  args: ['status',  '--short']                },
  'git-log':     { bin: 'git',  args: ['log',     '--oneline', '-10']       },
  'git-branch':  { bin: 'git',  args: ['branch',  '--show-current']         },
  'ci-list':     { bin: 'gh',   args: ['run',     'list', '--limit', '5']   },
  'pr-list':     { bin: 'gh',   args: ['pr',      'list']                   },
  'daily-log':   { bin: 'tail', args: ['-50',     'docs/tasks/daily-log.md']},
};

// ─── State helpers ─────────────────────────────────────────────────────────────
function loadState() {
  try { return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); }
  catch { return buildDefault(); }
}

function buildDefault() {
  const projectPath = path.dirname(DOCS_DIR);
  let appName = path.basename(projectPath);
  try {
    const f = fs.readdirSync(projectPath).find(x => x.endsWith('.xcodeproj'));
    if (f) appName = f.replace('.xcodeproj', '');
  } catch {}

  const phases = {};
  [
    'initiation','discovery','feature_collection','architecture','core_domain',
    'infrastructure','vertical_slice','features','polish','stabilisation',
    'app_store_readiness','pre_go_to_apple','publication','post_launch','update_cycle',
  ].forEach(p => { phases[p] = { status: 'not_started', notes: '', updatedAt: null }; });

  return { appName, projectPath, phases, updatedAt: new Date().toISOString() };
}

function saveState(state) {
  state.updatedAt = new Date().toISOString();
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2), 'utf8');
}

// ─── HTTP helpers ──────────────────────────────────────────────────────────────
function parseBody(req) {
  return new Promise(resolve => {
    let buf = '';
    req.on('data', d => buf += d);
    req.on('end', () => { try { resolve(JSON.parse(buf || '{}')); } catch { resolve({}); } });
  });
}

function jsonResp(res, status, data) {
  const body = JSON.stringify(data);
  res.writeHead(status, {
    'Content-Type':                 'application/json',
    'Access-Control-Allow-Origin':  '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(body);
}

// ─── Server ────────────────────────────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  const { pathname } = new URL(req.url, `http://localhost:${PORT}`);
  if (req.method === 'OPTIONS') { jsonResp(res, 200, {}); return; }

  // Serve HTML
  if (req.method === 'GET' && (pathname === '/' || pathname === '/index.html')) {
    try {
      const html = fs.readFileSync(HTML_FILE, 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(html);
    } catch (e) { res.writeHead(500); res.end('HTML not found: ' + e.message); }
    return;
  }

  // GET /api/state
  if (pathname === '/api/state' && req.method === 'GET') {
    jsonResp(res, 200, loadState()); return;
  }

  // POST /api/state — partial merge
  if (pathname === '/api/state' && req.method === 'POST') {
    const body  = await parseBody(req);
    const state = loadState();
    if (body.phases) {
      Object.entries(body.phases).forEach(([k, v]) => {
        state.phases[k] = { ...(state.phases[k] || {}), ...v, updatedAt: new Date().toISOString() };
      });
    }
    ['appName','projectPath'].forEach(k => { if (body[k] !== undefined) state[k] = body[k]; });
    saveState(state);
    jsonResp(res, 200, state); return;
  }

  // POST /api/exec — run a whitelisted command
  if (pathname === '/api/exec' && req.method === 'POST') {
    const body = await parseBody(req);
    const def  = SAFE_CMDS[body.cmd];
    if (!def) { jsonResp(res, 400, { error: 'Unknown command: ' + body.cmd }); return; }
    const cwd  = loadState().projectPath || path.dirname(DOCS_DIR);
    execFile(def.bin, def.args, { cwd, timeout: 20000, env: { ...process.env } }, (err, stdout, stderr) => {
      jsonResp(res, 200, {
        output:  (stdout + stderr).trim() || (err ? err.message : '(geen output)'),
        success: !err,
        cmd:     [def.bin, ...def.args].join(' '),
      });
    });
    return;
  }

  // POST /api/open-claude — open Terminal/iTerm2 and start claude
  // The claude command hint is only used as display text, never passed to a shell
  if (pathname === '/api/open-claude' && req.method === 'POST') {
    const body  = await parseBody(req);
    // Sanitise: only allow slash-commands (letters, digits, hyphen, slash, space)
    const hint  = (body.command || '').replace(/[^a-zA-Z0-9\-\/ ]/g, '');
    const state = loadState();
    const dir   = state.projectPath || os.homedir();

    // Write AppleScript to a temp file so no shell-injection path exists
    const script = `set d to ${JSON.stringify(dir)}
set h to ${JSON.stringify(hint)}
set shellCmd to "cd " & quoted form of d & " && printf '\\033[33m\\n  ⚡ Typ nu: " & h & "\\n\\033[0m' && claude"
if application "iTerm" is running or application "iTerm2" is running then
  tell application "iTerm"
    activate
    tell current window
      create tab with default profile
      tell current session of current tab
        write text shellCmd
      end tell
    end tell
  end tell
else
  tell application "Terminal"
    activate
    do script shellCmd
  end tell
end if`;

    const tmp = path.join(os.tmpdir(), `wf-open-${Date.now()}.scpt`);
    fs.writeFileSync(tmp, script, 'utf8');
    execFile('osascript', [tmp], err => {
      try { fs.unlinkSync(tmp); } catch {}
      jsonResp(res, 200, { ok: !err, error: err ? err.message : null });
    });
    return;
  }

  jsonResp(res, 404, { error: 'Not found' });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`\n  ✅  Workflow Dashboard  →  http://localhost:${PORT}\n`);
  execFile('open', [`http://localhost:${PORT}`]);
});

process.on('SIGINT', () => { console.log('\n  Server gestopt.\n'); process.exit(0); });
