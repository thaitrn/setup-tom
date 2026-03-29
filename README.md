# Setup Tom - OpenClaw AI

One-shot setup script for OpenClaw AI with GLM 5 Turbo on Mac Mini or Ubuntu.

## Requirements

### macOS (Mac Mini)

| Component | Minimum |
|-----------|---------|
| Hardware | Mac Mini M2/M4 (Apple Silicon) |
| RAM | 8 GB (16 GB recommended) |
| Disk | 10 GB free |
| OS | macOS latest |
| Network | Internet connection |
| Accessory | HDMI dummy plug (for 24/7 operation) |
| API Key | Zhipu AI or Haimaker account |

### Ubuntu / Debian

| Component | Minimum |
|-----------|---------|
| Hardware | x86_64 or aarch64 |
| RAM | 4 GB (8 GB recommended) |
| Disk | 10 GB free |
| OS | Ubuntu 22.04+ / Debian 12+ |
| Network | Internet connection |
| API Key | Zhipu AI or Haimaker account |

## Quick Start

### macOS

```bash
git clone https://github.com/thaitrn/setup-tom.git
cd setup-tom
chmod +x setup-openclaw.sh
./setup-openclaw.sh
```

### Ubuntu / Debian

```bash
git clone https://github.com/thaitrn/setup-tom.git
cd setup-tom
chmod +x setup-openclaw-ubuntu.sh
./setup-openclaw-ubuntu.sh
```

## What the Script Does

### macOS

| Step | Action |
|------|--------|
| 0 | Pre-flight check (OS, chip, RAM, disk, internet) |
| 1 | Install Homebrew |
| 2 | Install Node.js 24 |
| 3 | Install OpenClaw AI |
| 4 | Configure cloud API key (GLM 5 Turbo) |
| 5 | Run onboarding + install daemon |
| 6 | Configure GLM 5 Turbo model |
| 7 | Setup notifications (Telegram / Discord / Both) |
| 8 | Disable sleep (pmset) |
| 9 | Enable firewall |
| 10 | Start gateway (port 18789) |
| 11 | Health check + auto-fix |
| 12 | Print summary + send completion notification |

### Ubuntu

| Step | Action |
|------|--------|
| 0 | Pre-flight check (distro, arch, RAM, disk, internet) |
| 1 | Update system & install dependencies (apt) |
| 2 | Install Node.js 24 (NodeSource) |
| 3 | Install OpenClaw AI |
| 4 | Configure cloud API key (GLM 5 Turbo) |
| 5 | Run onboarding + install daemon |
| 6 | Configure GLM 5 Turbo model |
| 7 | Setup notifications (Telegram / Discord / Both) |
| 8 | Disable sleep/suspend (systemd mask) |
| 9 | Enable firewall (ufw) |
| 10 | Start gateway (port 18789) |
| 11 | Health check + auto-fix |
| 12 | Print summary + send completion notification |

## Notifications

| Channel | What You Need |
|---------|---------------|
| **Telegram** | Bot Token (@BotFather) + Chat ID |
| **Discord** | Webhook URL (Server Settings > Integrations) |
| **Both** | All of the above |

Alerts sent when: setup complete, gateway down (if monitoring added), tasks finish.

## Post-Setup (Manual)

### macOS

1. Install **Amphetamine** from App Store (prevent sleep)
2. Enable **FileVault** (System Settings > Privacy & Security)
3. Plug in **HDMI dummy plug**
4. Open dashboard: `openclaw dashboard`
5. Send test message to verify GLM 5 Turbo works

### Ubuntu

1. Enable **LUKS full-disk encryption** if not already configured
2. Open dashboard: `openclaw dashboard`
3. Send test message to verify GLM 5 Turbo works

## Useful Commands

```bash
openclaw gateway status   # Check gateway
openclaw dashboard        # Open web UI
openclaw logs             # View logs
openclaw doctor --fix     # Auto-fix issues
openclaw gateway restart  # Restart gateway
```

## Best Practices

- Use **Zhipu AI** as provider (recommended)
- Always run `openclaw doctor --fix` after setup
- Setup notification channel to know when gateway goes down
- Use HDMI dummy plug + Amphetamine for reliable 24/7 operation
- Enable FileVault to encrypt disk (API key stored locally)
- Never expose port 18789 to the internet — keep firewall on
- Monitor API usage on Zhipu/Haimaker dashboard to control costs

## Security Notes

- API key stored in `~/.openclaw/model-config.json` (plaintext) — enable FileVault
- Notification tokens in `~/.openclaw/notify-config.json` — keep private
- Firewall enabled by default — do not port-forward 18789
- Never commit `~/.openclaw/` config files to git

## Usage Scenarios

### Scenario: Gold Price Tracker via Telegram

After setup, you chat with Tôm (the bot) on Telegram just like texting a friend.

**You:**
> Tôm ơi, anh cần cập nhật giá vàng 1 tiếng 1 lần

**Tôm (auto-reply):**
> Dạ anh, em sẽ cập nhật giá vàng mỗi 1 tiếng cho anh. Bắt đầu ngay nhé!

**What happens behind the scenes:**

```
1. Telegram Bot receives message
2. OpenClaw Gateway (port 18789) processes the request
3. GLM 5 Turbo understands intent → creates a scheduled task
4. Every 1 hour:
   ├── Fetch gold price from API (SJC, DOJI, PNJ...)
   ├── Format: price, change %, trend
   └── Send result back via Telegram Bot
```

**Tôm sends every hour:**
> Giá vàng 10:00 29/03/2026
> - SJC: 92.5 / 94.0 triệu (mua/bán)
> - DOJI: 92.3 / 93.8 triệu
> - Thế giới: $2,235/oz
> - Xu hướng: tăng +0.3% so với 1h trước

**More examples you can ask:**

| You say | Tôm does |
|---------|----------|
| "Nhắc anh uống nước mỗi 2 tiếng" | Scheduled reminder every 2h |
| "Tóm tắt tin tức công nghệ mỗi sáng 7h" | Daily tech news digest at 7 AM |
| "Theo dõi giá Bitcoin, báo khi vượt 70k USD" | Price alert with threshold |
| "Dịch file này sang tiếng Anh" | One-time translation task |
| "Tổng hợp chi tiêu tháng này" | Summarize expenses from chat history |

### How It Works (Architecture)

```
┌──────────────┐    message     ┌──────────────────┐
│  Telegram /  │ ─────────────► │  OpenClaw Gateway │
│  Discord     │                │  (port 18789)     │
│  (you chat)  │ ◄───────────── │  Mac Mini 24/7    │
└──────────────┘    response    └────────┬─────────┘
                                         │
                                         ▼
                                ┌──────────────────┐
                                │  GLM 5 Turbo      │
                                │  (Cloud API)      │
                                │  - Understand VN  │
                                │  - Schedule tasks │
                                │  - Fetch data     │
                                └──────────────────┘
```

## Troubleshooting

### macOS

| Issue | Fix |
|-------|-----|
| `command not found: openclaw` | `source ~/.zshrc` or restart terminal |
| Gateway not starting | `openclaw doctor --fix` |
| Sleep kills gateway | Check HDMI dummy plug + pmset settings |
| `bad file descriptor` errors | `openclaw gateway restart` |
| Node version wrong | `brew install node@24 && brew link --overwrite node@24` |

### Ubuntu

| Issue | Fix |
|-------|-----|
| `command not found: openclaw` | `source ~/.bashrc` or restart terminal |
| Gateway not starting | `openclaw doctor --fix` |
| Suspend kills gateway | `sudo systemctl mask sleep.target suspend.target` |
| `bad file descriptor` errors | `openclaw gateway restart` |
| Node version wrong | Reinstall via NodeSource: see script step 2 |
| ufw blocking connections | `sudo ufw status` to check rules |

## Cost Estimate

| Item | Cost |
|------|------|
| Mac Mini M4 16GB | ~$599 (one-time) |
| HDMI dummy plug | ~$10 (one-time) |
| Electricity (annual) | ~$50-100 |
| API calls (annual) | ~$50+ (usage-based) |

## References

- [OpenClaw Getting Started](https://docs.openclaw.ai/start/getting-started)
- [GLM 5 Turbo Docs](https://docs.z.ai/guides/llm/glm-5-turbo)
