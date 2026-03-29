# Setup Tom - OpenClaw AI on Mac Mini

One-shot setup script for OpenClaw AI with GLM 5 Turbo on Mac Mini.

## Requirements

| Component | Minimum |
|-----------|---------|
| Hardware | Mac Mini M2/M4 (Apple Silicon) |
| RAM | 8 GB (16 GB recommended) |
| Disk | 10 GB free |
| OS | macOS latest |
| Network | Internet connection |
| Accessory | HDMI dummy plug (for 24/7 operation) |
| API Key | Zhipu AI or Haimaker account |

## Quick Start

```bash
git clone https://github.com/thaitrn/setup-tom.git
cd setup-tom
chmod +x setup-openclaw.sh
./setup-openclaw.sh
```

## What the Script Does

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

## Notifications

| Channel | What You Need |
|---------|---------------|
| **Telegram** | Bot Token (@BotFather) + Chat ID |
| **Discord** | Webhook URL (Server Settings > Integrations) |
| **Both** | All of the above |

Alerts sent when: setup complete, gateway down (if monitoring added), tasks finish.

## Post-Setup (Manual)

1. Install **Amphetamine** from App Store (prevent sleep)
2. Enable **FileVault** (System Settings > Privacy & Security)
3. Plug in **HDMI dummy plug**
4. Open dashboard: `openclaw dashboard`
5. Send test message to verify GLM 5 Turbo works

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

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `command not found: openclaw` | `source ~/.zshrc` or restart terminal |
| Gateway not starting | `openclaw doctor --fix` |
| Sleep kills gateway | Check HDMI dummy plug + pmset settings |
| `bad file descriptor` errors | `openclaw gateway restart` |
| Node version wrong | `brew install node@24 && brew link --overwrite node@24` |

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
