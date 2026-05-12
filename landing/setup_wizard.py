"""
KOPI Siew Dai — Web Setup Wizard
Runs on port 8899 after install. Client opens http://VPS_IP:8899 to configure.
"""

import os
import json
import subprocess
import secrets
from pathlib import Path

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="KOPI Setup Wizard")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

KOPI_HOME = os.getenv("KOPI_HOME", os.path.expanduser("~/.kopi"))
CONFIG_PATH = os.path.join(KOPI_HOME, "config.yaml")
SETUP_TOKEN = os.getenv("SETUP_TOKEN", "")

# ── HTML UI ─────────────────────────────────────────────────────────
SETUP_HTML = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KOPI Siew Dai — Setup Wizard</title>
<style>
:root{--blue:#2563eb;--gold:#f59e0b;--green:#22c55e;--red:#ef4444;--gray:#6b7280;--bg:#f9fafb;--card:#fff;--border:#e5e7eb}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Inter',-apple-system,sans-serif;background:var(--bg);color:#1f2937;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}
.container{max-width:560px;width:100%}
.logo{text-align:center;margin-bottom:32px}
.logo h1{font-size:28px;font-weight:800;background:linear-gradient(135deg,var(--blue),var(--gold));-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.logo p{color:var(--gray);font-size:14px;margin-top:4px}
.card{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:32px;margin-bottom:20px;box-shadow:0 1px 3px rgba(0,0,0,.06)}
.card h2{font-size:18px;font-weight:700;margin-bottom:4px;display:flex;align-items:center;gap:8px}
.card .desc{color:var(--gray);font-size:13px;margin-bottom:20px}
label{display:block;font-size:13px;font-weight:600;margin-bottom:6px;color:#374151}
input,select{width:100%;padding:10px 14px;border:1px solid var(--border);border-radius:10px;font-size:14px;outline:none;transition:border .2s}
input:focus,select:focus{border-color:var(--blue);box-shadow:0 0 0 3px rgba(37,99,235,.1)}
.field{margin-bottom:16px}
.field .hint{font-size:11px;color:var(--gray);margin-top:4px}
.btn{display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:12px 24px;border:none;border-radius:10px;font-size:14px;font-weight:600;cursor:pointer;transition:all .2s;width:100%}
.btn-blue{background:linear-gradient(135deg,var(--blue),#1d4ed8);color:#fff}
.btn-blue:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(37,99,235,.3)}
.btn-blue:disabled{opacity:.5;cursor:not-allowed;transform:none}
.btn-green{background:linear-gradient(135deg,var(--green),#16a34a);color:#fff}
.btn-outline{background:transparent;border:1px solid var(--border);color:var(--gray)}
.btn-outline:hover{border-color:var(--blue);color:var(--blue)}
.divider{display:flex;align-items:center;gap:12px;margin:20px 0;color:var(--gray);font-size:12px}
.divider::before,.divider::after{content:'';flex:1;height:1px;background:var(--border)}
.tabs{display:flex;gap:4px;margin-bottom:20px}
.tab{flex:1;padding:10px;text-align:center;border-radius:10px;font-size:13px;font-weight:600;cursor:pointer;border:1px solid var(--border);background:var(--card);transition:all .2s}
.tab.active{background:var(--blue);color:#fff;border-color:var(--blue)}
.tab-content{display:none}
.tab-content.active{display:block}
.status{padding:12px 16px;border-radius:10px;font-size:13px;margin-top:12px;display:none}
.status.ok{display:block;background:#f0fdf4;color:#166534;border:1px solid #bbf7d0}
.status.err{display:block;background:#fef2f2;color:#991b1b;border:1px solid #fecaca}
.spinner{display:inline-block;width:16px;height:16px;border:2px solid #fff;border-top-color:transparent;border-radius:50%;animation:spin .6s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}
.step-indicator{display:flex;justify-content:center;gap:8px;margin-bottom:24px}
.step-dot{width:10px;height:10px;border-radius:50%;background:var(--border)}
.step-dot.active{background:var(--blue)}
.step-dot.done{background:var(--green)}
.footer{text-align:center;color:var(--gray);font-size:11px;margin-top:24px}
.hidden{display:none!important}
</style>
</head>
<body>
<div class="container">
  <div class="logo">
    <h1>☕ KOPI Siew Dai Setup</h1>
    <p>by Xing Bao Ku PTE LTD · Singapore 🇸🇬</p>
  </div>

  <!-- Step Indicator -->
  <div class="step-indicator">
    <div class="step-dot active" id="dot1"></div>
    <div class="step-dot" id="dot2"></div>
    <div class="step-dot" id="dot3"></div>
  </div>

  <!-- STEP 1: Choose Platform -->
  <div class="card" id="step1">
    <h2>📡 选择通讯平台</h2>
    <p class="desc">你想通过哪个平台使用 KOPI Agent？</p>
    <div style="display:flex;flex-direction:column;gap:10px">
      <button class="btn btn-outline" onclick="selectPlatform('telegram')" style="justify-content:flex-start;padding:16px">
        <span style="font-size:24px">📱</span>
        <div style="text-align:left">
          <div style="font-weight:700">Telegram</div>
          <div style="font-size:12px;color:var(--gray)">推荐 · 3分钟配置</div>
        </div>
      </button>
      <button class="btn btn-outline" onclick="selectPlatform('wechat')" style="justify-content:flex-start;padding:16px">
        <span style="font-size:24px">💬</span>
        <div style="text-align:left">
          <div style="font-weight:700">微信</div>
          <div style="font-size:12px;color:var(--gray)">iLink Gateway · 5分钟配置</div>
        </div>
      </button>
      <button class="btn btn-outline" onclick="selectPlatform('both')" style="justify-content:flex-start;padding:16px">
        <span style="font-size:24px">🔥</span>
        <div style="text-align:left">
          <div style="font-weight:700">两个都要</div>
          <div style="font-size:12px;color:var(--gray)">Telegram + 微信同时在线</div>
        </div>
      </button>
    </div>
  </div>

  <!-- STEP 2: Telegram Config -->
  <div class="card hidden" id="step2-telegram">
    <h2>📱 Telegram 配置</h2>
    <p class="desc">在 @BotFather 创建一个 Bot，把 Token 粘贴到这里</p>
    <div class="field">
      <label>Bot Token</label>
      <input type="text" id="tg-token" placeholder="123456789:ABCdefGhIjKlMnOpQrStUvWxYz">
      <div class="hint">打开 Telegram → 搜索 @BotFather → /newbot → 复制 Token</div>
    </div>
    <div class="field">
      <label>允许的用户 ID（可选）</label>
      <input type="text" id="tg-allowed" placeholder="留空=所有人可用，或填你的 Telegram 数字 ID">
      <div class="hint">发送 /start 给 @userinfobot 获取你的 ID</div>
    </div>
    <button class="btn btn-blue" onclick="saveTelegram()" id="btn-tg">
      <span id="btn-tg-text">保存并启动 Telegram Bot</span>
    </button>
    <div class="status" id="status-tg"></div>
  </div>

  <!-- STEP 2: WeChat Config -->
  <div class="card hidden" id="step2-wechat">
    <h2>💬 微信配置</h2>
    <p class="desc">通过 iLink Gateway 接入微信</p>
    <div class="field">
      <label>iLink Bot Token</label>
      <input type="text" id="wx-token" placeholder="ilink-bot-token">
    </div>
    <div class="field">
      <label>iLink Bot ID</label>
      <input type="text" id="wx-bot-id" placeholder="ilink-bot-id">
    </div>
    <div class="field">
      <label>Gateway 地址</label>
      <input type="text" id="wx-gateway" placeholder="http://localhost:8080" value="http://localhost:8080">
      <div class="hint">iLink Gateway 服务地址</div>
    </div>
    <button class="btn btn-blue" onclick="saveWechat()" id="btn-wx">
      <span id="btn-wx-text">保存并启动微信 Gateway</span>
    </button>
    <div class="status" id="status-wx"></div>
  </div>

  <!-- STEP 3: Done -->
  <div class="card hidden" id="step3">
    <h2>🎉 配置完成！</h2>
    <p class="desc">你的 KOPI Agent 已经就绪</p>
    <div style="background:var(--bg);border-radius:12px;padding:20px;margin:16px 0">
      <div style="font-size:13px;color:var(--gray);margin-bottom:8px">测试你的 Bot：</div>
      <div id="test-link" style="font-size:16px;font-weight:700;color:var(--blue)"></div>
    </div>
    <div style="font-size:13px;color:var(--gray);line-height:1.8">
      <p>📌 <strong>常用命令：</strong></p>
      <p>• 发送 <code>/help</code> 查看所有命令</p>
      <p>• 发送 <code>/skill</code> 查看已安装技能</p>
      <p>• 发送任意消息开始对话</p>
    </div>
  </div>

  <div class="footer">
    KOPI Siew Dai Agent v1.0 · Powered by Xing Bao Ku PTE LTD<br>
    <a href="https://github.com/LINYIQ66/kopi-siew-dai" style="color:var(--blue)">GitHub</a> ·
    <a href="https://kopi.readinghero.xyz" style="color:var(--blue)">官网</a>
  </div>
</div>

<script>
const HOST = location.hostname;
let selectedPlatform = '';

function selectPlatform(p) {
  selectedPlatform = p;
  document.getElementById('step1').classList.add('hidden');
  document.getElementById('dot1').classList.remove('active');
  document.getElementById('dot1').classList.add('done');
  document.getElementById('dot2').classList.add('active');

  if (p === 'telegram' || p === 'both') {
    document.getElementById('step2-telegram').classList.remove('hidden');
  }
  if (p === 'wechat' || p === 'both') {
    document.getElementById('step2-wechat').classList.remove('hidden');
  }
  if (p === 'both') {
    document.getElementById('step2-telegram').querySelector('.desc').textContent = '第一步：配置 Telegram';
    document.getElementById('step2-wechat').querySelector('.desc').textContent = '第二步：配置微信';
  }
}

function showStatus(id, msg, type) {
  const el = document.getElementById(id);
  el.textContent = msg;
  el.className = 'status ' + type;
}

async function saveTelegram() {
  const token = document.getElementById('tg-token').value.trim();
  if (!token) { showStatus('status-tg', '请输入 Bot Token', 'err'); return; }

  const btn = document.getElementById('btn-tg');
  btn.disabled = true;
  document.getElementById('btn-tg-text').innerHTML = '<span class="spinner"></span> 配置中...';

  try {
    const resp = await fetch('/api/setup/telegram', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        bot_token: token,
        allowed_users: document.getElementById('tg-allowed').value.trim()
      })
    });
    const data = await resp.json();
    if (data.ok) {
      showStatus('status-tg', '✅ Telegram Bot 已启动！', 'ok');
      setTimeout(() => goToDone('telegram'), 1000);
    } else {
      showStatus('status-tg', '❌ ' + (data.error || '配置失败'), 'err');
      btn.disabled = false;
      document.getElementById('btn-tg-text').textContent = '保存并启动 Telegram Bot';
    }
  } catch(e) {
    showStatus('status-tg', '❌ 连接失败: ' + e.message, 'err');
    btn.disabled = false;
    document.getElementById('btn-tg-text').textContent = '保存并启动 Telegram Bot';
  }
}

async function saveWechat() {
  const token = document.getElementById('wx-token').value.trim();
  const botId = document.getElementById('wx-bot-id').value.trim();
  if (!token || !botId) { showStatus('status-wx', '请填写完整信息', 'err'); return; }

  const btn = document.getElementById('btn-wx');
  btn.disabled = true;
  document.getElementById('btn-wx-text').innerHTML = '<span class="spinner"></span> 配置中...';

  try {
    const resp = await fetch('/api/setup/wechat', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        bot_token: token,
        bot_id: botId,
        gateway_url: document.getElementById('wx-gateway').value.trim()
      })
    });
    const data = await resp.json();
    if (data.ok) {
      showStatus('status-wx', '✅ 微信 Gateway 已启动！', 'ok');
      setTimeout(() => goToDone('wechat'), 1000);
    } else {
      showStatus('status-wx', '❌ ' + (data.error || '配置失败'), 'err');
      btn.disabled = false;
      document.getElementById('btn-wx-text').textContent = '保存并启动微信 Gateway';
    }
  } catch(e) {
    showStatus('status-wx', '❌ 连接失败: ' + e.message, 'err');
    btn.disabled = false;
    document.getElementById('btn-wx-text').textContent = '保存并启动微信 Gateway';
  }
}

function goToDone(platform) {
  document.getElementById('step2-telegram').classList.add('hidden');
  document.getElementById('step2-wechat').classList.add('hidden');
  document.getElementById('dot2').classList.remove('active');
  document.getElementById('dot2').classList.add('done');
  document.getElementById('dot3').classList.add('active');
  document.getElementById('step3').classList.remove('hidden');

  if (platform === 'telegram') {
    document.getElementById('test-link').textContent = 'https://t.me/你的Bot用户名';
    document.getElementById('test-link').href = '#';
  } else {
    document.getElementById('test-link').textContent = '打开微信对话测试';
  }
}
</script>
</body>
</html>"""

# ── Routes ──────────────────────────────────────────────────────────
@app.get("/", response_class=HTMLResponse)
async def index():
    return SETUP_HTML

@app.get("/health")
async def health():
    return {"status": "ok", "service": "kopi-setup-wizard"}

@app.post("/api/setup/telegram")
async def setup_telegram(request: Request):
    body = await request.json()
    bot_token = body.get("bot_token", "").strip()
    allowed_users = body.get("allowed_users", "").strip()

    if not bot_token:
        return JSONResponse({"ok": False, "error": "Bot Token 不能为空"})

    # Validate token format
    if ":" not in bot_token or len(bot_token) < 20:
        return JSONResponse({"ok": False, "error": "Token 格式不对，应该类似 123456789:ABCdef..."})

    # Write config
    try:
        config_path = Path(CONFIG_PATH)
        config_path.parent.mkdir(parents=True, exist_ok=True)

        # Read existing config or create new
        existing = ""
        if config_path.exists():
            existing = config_path.read_text()

        # Update telegram section
        if "telegram:" in existing:
            # Replace existing telegram config
            import re
            existing = re.sub(
                r'telegram:\s*\n(?:  .*\n)*',
                f'telegram:\n  bot_token: "{bot_token}"\n',
                existing
            )
            config_path.write_text(existing)
        else:
            # Append telegram config
            with open(config_path, "a") as f:
                f.write(f'\ntelegram:\n  bot_token: "{bot_token}"\n')

        # Restart gateway if running
        subprocess.run(["systemctl", "restart", "kopi-gateway"], capture_output=True)
        # Or start it
        subprocess.run(["systemctl", "start", "kopi-gateway"], capture_output=True)

        return JSONResponse({"ok": True, "message": "Telegram Bot 已配置并启动"})
    except Exception as e:
        return JSONResponse({"ok": False, "error": str(e)})

@app.post("/api/setup/wechat")
async def setup_wechat(request: Request):
    body = await request.json()
    bot_token = body.get("bot_token", "").strip()
    bot_id = body.get("bot_id", "").strip()
    gateway_url = body.get("gateway_url", "http://localhost:8080").strip()

    if not bot_token or not bot_id:
        return JSONResponse({"ok": False, "error": "请填写完整信息"})

    try:
        config_path = Path(CONFIG_PATH)
        config_path.parent.mkdir(parents=True, exist_ok=True)

        existing = ""
        if config_path.exists():
            existing = config_path.read_text()

        wx_config = f'''whatsapp:
  enabled: true

weixin:
  bot_token: "{bot_token}"
  bot_id: "{bot_id}"
  gateway_url: "{gateway_url}"
'''
        if "weixin:" in existing:
            import re
            existing = re.sub(
                r'weixin:\s*\n(?:  .*\n)*',
                f'weixin:\n  bot_token: "{bot_token}"\n  bot_id: "{bot_id}"\n  gateway_url: "{gateway_url}"\n',
                existing
            )
            config_path.write_text(existing)
        else:
            with open(config_path, "a") as f:
                f.write(f'\nweixin:\n  bot_token: "{bot_token}"\n  bot_id: "{bot_id}"\n  gateway_url: "{gateway_url}"\n')

        subprocess.run(["systemctl", "restart", "kopi-gateway"], capture_output=True)
        subprocess.run(["systemctl", "start", "kopi-gateway"], capture_output=True)

        return JSONResponse({"ok": True, "message": "微信 Gateway 已配置并启动"})
    except Exception as e:
        return JSONResponse({"ok": False, "error": str(e)})

@app.get("/api/status")
async def get_status():
    """Check current gateway status"""
    result = subprocess.run(["systemctl", "is-active", "kopi-gateway"], capture_output=True, text=True)
    gw_status = result.stdout.strip()

    config_exists = Path(CONFIG_PATH).exists()
    has_telegram = False
    has_wechat = False

    if config_exists:
        content = Path(CONFIG_PATH).read_text()
        has_telegram = "telegram:" in content and "bot_token:" in content
        has_wechat = "weixin:" in content

    return {
        "gateway": gw_status,
        "config_exists": config_exists,
        "telegram_configured": has_telegram,
        "wechat_configured": has_wechat
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8899"))
    print(f"[KOPI Setup] Wizard running on http://0.0.0.0:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
