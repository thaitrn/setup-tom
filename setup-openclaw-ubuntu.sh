#!/bin/bash
set -euo pipefail

# ============================================
# OpenClaw AI - Ubuntu/Debian End-to-End Setup
# Cloud API mode with GLM 5 Turbo
# ============================================

echo "=========================================="
echo " OpenClaw AI - Ubuntu Setup"
echo "=========================================="

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${GREEN}[STEP $1]${NC} $2"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
bad()  { echo -e "  ${RED}✗${NC} $1"; PREFLIGHT_FAIL=1; }

# Progress spinner for long-running commands
# Usage: run_with_progress "Description" "est. time" command [args...]
run_with_progress() {
  local DESC="$1" EST="$2"
  shift 2
  local SPINNER='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local START_TIME=$SECONDS
  local LOG_FILE
  LOG_FILE=$(mktemp)

  # Run command in background, capture output
  "$@" > "$LOG_FILE" 2>&1 &
  local PID=$!

  # Animate spinner with elapsed/estimated time
  local i=0
  while kill -0 "$PID" 2>/dev/null; do
    local ELAPSED=$(( SECONDS - START_TIME ))
    printf "\r  ${YELLOW}%s${NC} %s [%ds / %s]  " "${SPINNER:i%${#SPINNER}:1}" "$DESC" "$ELAPSED" "$EST"
    i=$((i + 1))
    sleep 0.15
  done

  # Get exit code
  wait "$PID"
  local EXIT_CODE=$?
  local ELAPSED=$(( SECONDS - START_TIME ))

  # Clear spinner line and print result
  printf "\r%-80s\r" ""
  if [[ "$EXIT_CODE" -eq 0 ]]; then
    ok "$DESC (${ELAPSED}s)"
  else
    echo -e "  ${RED}✗${NC} $DESC (failed after ${ELAPSED}s)"
    echo -e "  ${RED}--- Error output ---${NC}"
    tail -20 "$LOG_FILE"
    rm -f "$LOG_FILE"
    return "$EXIT_CODE"
  fi
  rm -f "$LOG_FILE"
}

# ============================================
# STEP 0: PRE-FLIGHT CHECK
# ============================================
step 0 "Pre-flight system check..."
PREFLIGHT_FAIL=0

# --- Check Linux ---
if [[ "$(uname)" != "Linux" ]]; then
  bad "Not Linux. This script is for Ubuntu/Debian only."
else
  if command -v lsb_release &>/dev/null; then
    DISTRO="$(lsb_release -ds 2>/dev/null)"
  elif [[ -f /etc/os-release ]]; then
    DISTRO="$(. /etc/os-release && echo "$PRETTY_NAME")"
  else
    DISTRO="Linux (unknown distro)"
  fi
  ok "$DISTRO detected"
fi

# --- Check Architecture ---
ARCH="$(uname -m)"
if [[ "$ARCH" == "x86_64" || "$ARCH" == "aarch64" ]]; then
  ok "Architecture: $ARCH"
else
  bad "Unsupported architecture: $ARCH"
fi

# --- Check RAM ---
RAM_KB="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
RAM_GB=$((RAM_KB / 1048576))
if [[ "$RAM_GB" -ge 4 ]]; then
  ok "RAM: ${RAM_GB}GB (minimum 4GB)"
else
  bad "RAM: ${RAM_GB}GB — need at least 4GB"
fi

# --- Check Disk Space ---
DISK_AVAIL_KB="$(df -k / | tail -1 | awk '{print $4}')"
DISK_AVAIL_GB=$((DISK_AVAIL_KB / 1048576))
if [[ "$DISK_AVAIL_GB" -ge 10 ]]; then
  ok "Disk available: ${DISK_AVAIL_GB}GB (need 10GB+)"
else
  bad "Disk available: ${DISK_AVAIL_GB}GB — need at least 10GB free"
fi

# --- Check Internet ---
if curl -s --max-time 5 https://google.com >/dev/null 2>&1; then
  ok "Internet connection OK"
else
  bad "No internet connection. Cannot download packages."
fi

# --- Check apt ---
if command -v apt &>/dev/null; then
  ok "apt package manager available"
else
  bad "apt not found. This script requires Ubuntu/Debian."
fi

# --- Summary ---
echo ""
if [[ "$PREFLIGHT_FAIL" -eq 1 ]]; then
  fail "Pre-flight check FAILED. Fix issues above before continuing."
fi
echo -e "${GREEN}All pre-flight checks passed!${NC}"
echo ""
read -rp "Continue with installation? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# ============================================
# INSTALLATION
# ============================================

# --- Step 1: Update system & install dependencies ---
step 1 "Updating system and installing dependencies..."
run_with_progress "Updating package lists" "~30s" sudo apt update -y
run_with_progress "Installing dependencies" "~60s" sudo apt install -y curl wget git build-essential ca-certificates gnupg

# --- Step 2: Install Node.js 24 ---
step 2 "Installing Node.js 24..."
if ! command -v node &>/dev/null || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt 22 ]]; then
  # NodeSource setup for Node.js 24
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  run_with_progress "Updating package lists" "~15s" sudo apt update -y
  run_with_progress "Installing Node.js" "~30s" sudo apt install -y nodejs
else
  echo "Node.js $(node -v) already installed."
fi
node -v

# --- Step 3: Install OpenClaw ---
step 3 "Installing OpenClaw AI..."
if command -v openclaw &>/dev/null; then
  echo "OpenClaw $(openclaw --version 2>/dev/null || echo '?') already installed."
else
  run_with_progress "Installing openclaw via npm" "~30s" npm install -g openclaw
fi

# Ensure openclaw is in PATH (npm global bin may not be in PATH)
if ! command -v openclaw &>/dev/null; then
  NPM_BIN="$(npm config get prefix 2>/dev/null)/bin"
  if [[ -x "$NPM_BIN/openclaw" ]]; then
    export PATH="$NPM_BIN:$PATH"
    SHELL_RC="$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"
    echo "export PATH=\"$NPM_BIN:\$PATH\"" >> "$SHELL_RC"
  fi
fi

if ! command -v openclaw &>/dev/null; then
  fail "openclaw not found after installation. Check installer output above and add its location to PATH manually."
fi
openclaw --version

# --- Step 4: API Key Input (Cloud mode - GLM 5 Turbo only) ---
step 4 "Configuring cloud API key..."
echo ""
echo "OpenClaw uses GLM 5 Turbo (cloud API) by default."
echo "You need an API key from one of these providers:"
echo ""
echo "  1) Zhipu AI (recommended) — https://open.bigmodel.cn"
echo "  2) Haimaker — https://haimaker.ai"
echo ""
read -rp "Select provider [1/2]: " PROVIDER_CHOICE

case "$PROVIDER_CHOICE" in
  1) PROVIDER="zhipu" ;;
  2) PROVIDER="haimaker" ;;
  *) fail "Invalid choice. Only 1 or 2." ;;
esac

echo ""
echo "Paste your $( [[ "$PROVIDER" == "zhipu" ]] && echo "Zhipu AI" || echo "Haimaker" ) API key below."
echo "(Get one at $( [[ "$PROVIDER" == "zhipu" ]] && echo "https://open.bigmodel.cn" || echo "https://haimaker.ai" ))"
echo ""
read -rsp "API Key: " API_KEY
echo ""

if [[ -z "$API_KEY" ]]; then
  fail "API key is required. Cannot proceed without it."
fi

# Validate API key format (basic check)
if [[ ${#API_KEY} -lt 10 ]]; then
  fail "API key looks too short. Please check and re-run."
fi

# --- Step 5: Run Onboarding with Daemon ---
step 5 "Running OpenClaw onboarding..."
openclaw onboard --install-daemon

# --- Step 6: Configure GLM 5 Turbo ---
step 6 "Configuring GLM 5 Turbo model..."

OPENCLAW_CONFIG_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_CONFIG_DIR"

if [[ "$PROVIDER" == "haimaker" ]]; then
  cat > "$OPENCLAW_CONFIG_DIR/model-config.json" <<EOF
{
  "provider": "haimaker",
  "baseUrl": "https://api.haimaker.ai/v1",
  "apiType": "openai-completions",
  "apiKey": "$API_KEY",
  "model": "glm-5-turbo",
  "contextWindow": 200000,
  "maxOutput": 128000
}
EOF
else
  cat > "$OPENCLAW_CONFIG_DIR/model-config.json" <<EOF
{
  "provider": "zhipu",
  "apiKey": "$API_KEY",
  "model": "glm-5-turbo",
  "contextWindow": 200000,
  "maxOutput": 128000
}
EOF
fi

echo "Model config saved to $OPENCLAW_CONFIG_DIR/model-config.json"

# --- Step 7: Notification Setup ---
step 7 "Configuring notifications..."
echo ""
echo "Receive alerts when:"
echo "  - Setup completes"
echo "  - Gateway goes down"
echo "  - Agent tasks finish"
echo ""
echo "Choose notification channel:"
echo "  1) Telegram"
echo "  2) Discord"
echo "  3) Both (Telegram + Discord)"
echo "  4) Skip (no notifications)"
read -rp "Select [1/2/3/4]: " NOTIFY_CHOICE

NOTIFY_TELEGRAM=0
NOTIFY_DISCORD=0
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
DISCORD_WEBHOOK_URL=""

# Telegram setup
if [[ "$NOTIFY_CHOICE" == "1" || "$NOTIFY_CHOICE" == "3" ]]; then
  NOTIFY_TELEGRAM=1
  echo ""
  echo "--- Telegram Setup ---"
  echo "1. Message @BotFather on Telegram → /newbot → get token"
  echo "2. Message your bot, then visit:"
  echo "   https://api.telegram.org/bot<TOKEN>/getUpdates"
  echo "   to find your chat_id"
  echo ""
  read -rp "Bot Token: " TELEGRAM_BOT_TOKEN
  read -rp "Chat ID: " TELEGRAM_CHAT_ID
  if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
    warn "Telegram config incomplete. Skipping Telegram."
    NOTIFY_TELEGRAM=0
  fi
fi

# Discord setup
if [[ "$NOTIFY_CHOICE" == "2" || "$NOTIFY_CHOICE" == "3" ]]; then
  NOTIFY_DISCORD=1
  echo ""
  echo "--- Discord Setup ---"
  echo "1. Server Settings → Integrations → Webhooks → New Webhook"
  echo "2. Copy Webhook URL"
  echo ""
  read -rp "Webhook URL: " DISCORD_WEBHOOK_URL
  if [[ -z "$DISCORD_WEBHOOK_URL" ]]; then
    warn "Discord webhook empty. Skipping Discord."
    NOTIFY_DISCORD=0
  fi
fi

# Save notification config
cat > "$OPENCLAW_CONFIG_DIR/notify-config.json" <<EOF
{
  "telegram": {
    "enabled": $( [[ "$NOTIFY_TELEGRAM" -eq 1 ]] && echo "true" || echo "false" ),
    "botToken": "$TELEGRAM_BOT_TOKEN",
    "chatId": "$TELEGRAM_CHAT_ID"
  },
  "discord": {
    "enabled": $( [[ "$NOTIFY_DISCORD" -eq 1 ]] && echo "true" || echo "false" ),
    "webhookUrl": "$DISCORD_WEBHOOK_URL"
  }
}
EOF
echo "Notification config saved."

# Notification helper function
send_notify() {
  local MSG="$1"
  if [[ "$NOTIFY_TELEGRAM" -eq 1 ]]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=${MSG}" \
      -d "parse_mode=Markdown" >/dev/null 2>&1 || warn "Telegram send failed"
  fi
  if [[ "$NOTIFY_DISCORD" -eq 1 ]]; then
    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"content\": \"${MSG}\"}" >/dev/null 2>&1 || warn "Discord send failed"
  fi
}

# Test notification
if [[ "$NOTIFY_TELEGRAM" -eq 1 || "$NOTIFY_DISCORD" -eq 1 ]]; then
  echo "Sending test notification..."
  send_notify "🔔 OpenClaw Setup: Notification test from Ubuntu - $(hostname)"
  echo "Check your Telegram/Discord for test message."
fi

# --- Step 8: Disable Sleep / Power Saving ---
step 8 "Configuring power settings (prevent sleep)..."
# Disable suspend/hibernate via systemd
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true
# Disable screen blanking
if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
fi
echo "Sleep/suspend disabled for 24/7 operation."

# --- Step 9: Enable Firewall ---
step 9 "Enabling firewall (ufw)..."
if ! command -v ufw &>/dev/null; then
  run_with_progress "Installing ufw" "~15s" sudo apt install -y ufw
fi
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable
echo "Firewall enabled. Only SSH allowed inbound."

# --- Step 10: Start Gateway ---
step 10 "Starting OpenClaw gateway..."
openclaw gateway start
sleep 3

# Verify gateway
if openclaw gateway status | grep -q "listening"; then
  echo -e "${GREEN}Gateway is running on port 18789${NC}"
else
  warn "Gateway may not be running. Check: openclaw gateway status"
fi

# --- Step 11: Health Check ---
step 11 "Running health check..."
openclaw doctor --fix || warn "Some health checks failed. Review output above."

# --- Step 12: Final ---
step 12 "Final setup..."
echo ""
echo "=========================================="
echo -e "${GREEN} SETUP COMPLETE!${NC}"
echo "=========================================="
echo ""
echo "Next steps (manual):"
echo "  1. Enable full-disk encryption (LUKS) if not already done"
echo "  2. Open dashboard: openclaw dashboard"
echo "  3. Send a test message to verify GLM 5 Turbo works"
echo ""
echo "Useful commands:"
echo "  openclaw gateway status  - Check gateway"
echo "  openclaw dashboard       - Open web UI"
echo "  openclaw logs            - View logs"
echo "  openclaw doctor --fix    - Auto-fix issues"
echo ""
echo "Provider: $PROVIDER"
echo "Model: GLM 5 Turbo (200K context, 128K output)"
echo "Gateway: http://localhost:18789"
echo "=========================================="

# Send completion notification
send_notify "✅ OpenClaw Setup COMPLETE on $(hostname)!
Provider: $PROVIDER
Model: GLM 5 Turbo
Gateway: http://localhost:18789
Dashboard: openclaw dashboard"
