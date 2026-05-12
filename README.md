<p align="center">
  <img src="website/assets/banner.png" alt="KOPI Siew Dai Agent" width="100%">
</p>

# ☕ KOPI Siew Dai Agent

<p align="center">
  <a href="https://kopi.readinghero.xyz/docs/en/"><img src="https://img.shields.io/badge/Docs-kopi.readinghero.xyz-FFD700?style=for-the-badge" alt="Documentation"></a>
  <a href="https://github.com/LINYIQ66/kopi-siew-dai/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
  <a href="https://kopi.readinghero.xyz"><img src="https://img.shields.io/badge/Built%20by-Xing%20Bao%20Ku%20PTE%20LTD-blueviolet?style=for-the-badge" alt="Built by Xing Bao Ku PTE LTD"></a>
</p>

**KOPI Siew Dai Agent** — an AI agent for Singapore SMEs by [Xing Bao Ku PTE LTD](https://kopi.readinghero.xyz). Less sugar, full power.

Built on [Hermes Agent](https://github.com/nousresearch/hermes-agent), deeply customized for Singapore and Southeast Asia. One command install, zero configuration, 107+ skills pre-loaded.

> **"Siew Dai"** (少糖) is Hokkien for "less sugar" — the Singapore way of ordering coffee with less sweetness. Our AI agent follows the same philosophy: remove the complexity, keep the capability.

---

## 🚀 Quick Start

```bash
curl -fsSL https://kopi.readinghero.xyz/install-siew-dai.sh | bash
```

That's it. In 3 minutes you have a fully configured AI agent with:
- ✅ API key auto-provisioned (no signup needed)
- ✅ 107+ skills pre-installed
- ✅ Telegram / WeChat gateway ready to configure
- ✅ MiMo v2.5 Pro model via KOPI Proxy

## ☕ What is KOPI?

In Singapore's kopitiams, ordering coffee is an art:

| Order | Meaning |
|-------|---------|
| **KOPI O** | Black coffee, no milk |
| **KOPI Siew Dai** | Less sugar ⭐ *Our pick* |
| **KOPI Gau** | Strong / thick |
| **KOPI Peng** | Iced |
| **KOPI C** | With evaporated milk |
| **KOPI Kosong** | No sugar, no milk |
| **KOPI Po** | Weak / diluted |
| **KOPI Gah Dai** | Extra sweet |

KOPI Siew Dai Agent = less sugar, full flavor. Minimum config, maximum capability.

---

## 🎯 Features

- **One command install** — `curl | bash`, zero manual config
- **API key auto-provisioned** — no signup, no credit card, just works
- **107+ pre-installed skills** — GitHub, Telegram, YouTube, Docker, Obsidian, Notion, and more
- **Multi-platform messaging** — Telegram + WeChat gateway, configure after install
- **KOPI Proxy** — built-in model proxy, customers never see API keys or model names
- **Auto-updates** — skills sync automatically, agent evolves over time
- **Secure** — API keys stored at system level, invisible to users
- **Bilingual** — Chinese and English support out of the box

## 🤖 Models

All models proxied through KOPI Proxy — no API key needed.

| Client Model | Upstream | Notes |
|-------------|----------|-------|
| `kopi-siew-dai` | MiMo v2.5 Pro | Default, strongest |
| `kopi-siew-dai-flash` | MiMo v2 Flash | Fast responses |
| `kopi-gau` | DeepSeek v4 Flash | Strong reasoning |
| `kopi-o` | MiMo v2.5 Pro | Classic |
| `kopi-o-flash` | MiMo v2 Flash | Classic fast |

Switch models in chat: `/model kopi-gau`

## 💬 Usage

```bash
# Interactive chat
kopi

# One-shot query
kopi "write a Python script to rename files"

# Start messaging gateway
kopi gateway setup

# Check health
kopi doctor
```

## 📋 Common Commands

| Command | Description |
|---------|-------------|
| `kopi` | Start interactive chat |
| `kopi gateway setup` | Configure Telegram / WeChat |
| `kopi gateway start` | Start messaging gateway |
| `kopi doctor` | Diagnose issues |
| `kopi logs` | View logs |
| `kopi status` | Check status |

## 🛠 Skills (107+)

| Category | Count | Examples |
|----------|-------|----------|
| Messaging | 5 | Telegram, WhatsApp, WeChat, Discord, Signal |
| Search | 4 | Web Search, YouTube, ArXiv, Polymarket |
| Dev | 6 | GitHub, Python, Node.js, Docker, Debugging |
| Data | 4 | Jupyter, Pandas, Visualization, Web Scraping |
| Creative | 8 | ASCII Art, Infographic, Diagram, Pixel Art |
| Productivity | 8 | Obsidian, Notion, Google Workspace, PDF |
| AI/ML | 4 | vLLM, LoRA Fine-tuning, HuggingFace, W&B |
| Smart Home | 2 | Philips Hue, Home Assistant |
| Media | 5 | Spotify, YouTube, GIF, Music Generation |
| DevOps | 5 | API Platform, Webhook, Subdomain Deploy |

## ⚙️ Configuration

Config file: `~/.kopi/config.yaml`

```yaml
model:
  default: kopi-siew-dai
  provider: custom
  base_url: https://kopi.readinghero.xyz/kp/v1
  api_key: kp-xxxxxxxx         # Auto-provisioned during install
  context_length: 256000

agent:
  max_turns: 90

terminal:
  timeout: 180

display:
  skin: default
  show_cost: true

memory:
  memory_enabled: true
  user_profile_enabled: true
```

## 🔧 Troubleshooting

**Installation failed**
- `dpkg` interrupted → `sudo dpkg --configure -a`
- Python too old → script auto-installs 3.11+
- Network issues → ensure you can reach kopi.readinghero.xyz

**401 Invalid API Key**
- Check `~/.kopi/config.yaml` → `api_key` field
- Verify `base_url` is `https://kopi.readinghero.xyz/kp/v1`
- Run `kopi doctor`

**Gateway not responding**
- `systemctl status kopi-gateway`
- `journalctl -u kopi-gateway -f`
- Verify bot token is correct

## 📄 License

MIT License — see [LICENSE](LICENSE)

## 🏢 About

Built by **Xing Bao Ku PTE LTD** · Singapore 🇸🇬

Like less sugar coffee — simple, pure, effective.
