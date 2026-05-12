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

  // POST /api/write-doc — write a markdown file within project bounds
  if (pathname === '/api/write-doc' && req.method === 'POST') {
    const body    = await parseBody(req);
    const relPath = (body.path || '').trim();
    if (!relPath || relPath.startsWith('/') || relPath.includes('..')) {
      jsonResp(res, 400, { error: 'Invalid path' }); return;
    }
    const state = loadState();
    const root  = state.projectPath || path.dirname(DOCS_DIR);
    const full  = path.resolve(root, relPath);
    if (!full.startsWith(root + path.sep)) {
      jsonResp(res, 403, { error: 'Path outside project' }); return;
    }
    try {
      fs.mkdirSync(path.dirname(full), { recursive: true });
      fs.writeFileSync(full, body.content || '', 'utf8');
      jsonResp(res, 200, { ok: true });
    } catch (e) { jsonResp(res, 500, { error: e.message }); }
    return;
  }

  // GET /api/read-doc?path=... — read a file within project bounds
  if (pathname === '/api/read-doc' && req.method === 'GET') {
    const url2    = new URL(req.url, `http://localhost:${PORT}`);
    const relPath = (url2.searchParams.get('path') || '').trim();
    if (!relPath || relPath.startsWith('/') || relPath.includes('..')) {
      jsonResp(res, 400, { error: 'Invalid path' }); return;
    }
    const state = loadState();
    const root  = state.projectPath || path.dirname(DOCS_DIR);
    const full  = path.resolve(root, relPath);
    if (!full.startsWith(root + path.sep)) {
      jsonResp(res, 403, { error: 'Path outside project' }); return;
    }
    try {
      const content = fs.readFileSync(full, 'utf8');
      jsonResp(res, 200, { content, exists: true });
    } catch { jsonResp(res, 200, { content: '', exists: false }); }
    return;
  }

  // POST /api/open-claude — open Terminal/iTerm2 with claude
  // hint: only slash-command chars allowed (display only)
  // question: written to temp file, echoed before claude starts (content never in command string)
  if (pathname === '/api/open-claude' && req.method === 'POST') {
    const body  = await parseBody(req);
    const hint  = (body.command  || '').replace(/[^a-zA-Z0-9\-\/ ]/g, '');
    const state = loadState();
    const dir   = state.projectPath || os.homedir();

    // If a question was supplied, write it to a temp file; the shell will cat it
    let questionFile = '';
    if (body.question && typeof body.question === 'string') {
      const tmpQ = path.join(os.tmpdir(), `wf-q-${Date.now()}.txt`);
      // Write raw question content to file (never interpolated into shell command)
      fs.writeFileSync(tmpQ, body.question, 'utf8');
      questionFile = tmpQ;
    }

    // Build the shell snippet — only safe values used in the string
    // questionFile is a server-generated /tmp path with no user content
    const innerCmd = questionFile
      ? `cd ${JSON.stringify(dir)} && printf '\\033[36m\\n  ❓ Vraag aan Claude:\\n\\033[0m' && cat ${JSON.stringify(questionFile)} && echo && rm -f ${JSON.stringify(questionFile)} && claude`
      : `cd ${JSON.stringify(dir)} && printf '\\033[33m\\n  ⚡ Typ nu: ${hint}\\n\\033[0m' && claude`;

    const script = `set shellCmd to ${JSON.stringify(innerCmd)}
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
