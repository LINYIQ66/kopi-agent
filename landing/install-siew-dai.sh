#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# KOPI Siew Dai — 一键安装脚本
# By Xing Bao Ku PTE LTD
#
# Usage:
#   curl -fsSL https://kopi.readinghero.xyz/install-siew-dai.sh | bash
#   curl -fsSL https://kopi.readinghero.xyz/install-siew-dai.sh | KOPI_API_KEY=kp-xxx bash
#
# Non-interactive mode (curl | bash): installs everything, skips gateway config.
# Interactive mode (bash install-siew-dai.sh): full install + gateway setup at the end.
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Config ─────────────────────────────────────────────────────────────
KOPI_HOME="${KOPI_HOME:-/usr/local/lib/kopi-siew-dai}"
KOPI_CONFIG_DIR="${KOPI_CONFIG_DIR:-$HOME/.kopi}"
KOPI_CREDENTIALS_FILE="/etc/kopi-agent/credentials"
PROVISION_URL="https://kopi.readinghero.xyz/kp/v1/provision"
PROVISION_TOKEN="kopi-provision-2026"
REPO_URL="https://github.com/LINYIQ66/kopi-siew-dai.git"
MIN_PYTHON_VERSION="3.11"
IS_TTY=false
[[ -t 0 ]] && IS_TTY=true

# ── Helpers ────────────────────────────────────────────────────────────
info()  { echo -e "${BLUE}ℹ${NC}  $*"; }
ok()    { echo -e "${GREEN}✓${NC}  $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
fail()  { echo -e "${RED}✗${NC}  $*"; exit 1; }
step()  { echo -e "\n${BOLD}${CYAN}═══ $* ═══${NC}"; }

banner() {
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
    ██╗  ██╗ ██████╗ ██████╗ ██╗        ██████╗
    ██║ ██╔╝██╔═══██╗██╔══██╗██║       ██╔═══██╗
    █████╔╝ ██║   ██║██████╔╝██║       ██║   ██║
    ██╔═██╗ ██║   ██║██╔═══╝ ██║       ██║   ██║
    ██║  ██╗╚██████╔╝██║     ██║██╗    ╚██████╔╝
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═════╝
EOF
    echo -e "${NC}"
    echo -e "${DIM}  KOPI Siew Dai — by Xing Bao Ku PTE LTD${NC}"
    echo -e "${DIM}  少糖版 — 一键安装，一步到位${NC}"
    echo ""
}

# ── OS Detection ───────────────────────────────────────────────────────
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"
    elif [[ -f /etc/redhat-release ]]; then
        OS_ID="centos"
        OS_VERSION=$(grep -oP '\d+' /etc/redhat-release | head -1)
    else
        OS_ID="unknown"
        OS_VERSION="unknown"
    fi

    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) fail "不支持的架构: $ARCH" ;;
    esac

    info "系统: ${OS_ID} ${OS_VERSION} (${ARCH})"
}

# ── Dependency Installation ────────────────────────────────────────────
install_deps_debian() {
    step "安装系统依赖"
    # Fix any interrupted dpkg first
    dpkg --configure -a 2>/dev/null || true
    apt-get update -qq
    apt-get install -y -qq \
        git curl wget python3 python3-pip python3-venv \
        build-essential libffi-dev libssl-dev \
        ripgrep ffmpeg > /dev/null 2>&1
    ok "Debian/Ubuntu 依赖安装完成"
}

install_deps_rhel() {
    step "安装系统依赖"
    if command -v dnf &>/dev/null; then
        dnf install -y -q git curl wget python3 python3-pip python3-devel \
            gcc libffi-devel openssl-devel ripgrep ffmpeg > /dev/null 2>&1
    else
        yum install -y -q git curl wget python3 python3-pip python3-devel \
            gcc libffi-devel openssl-devel > /dev/null 2>&1
    fi
    ok "RHEL/CentOS 依赖安装完成"
}

install_deps() {
    case "$OS_ID" in
        ubuntu|debian|linuxmint|pop|raspbian)
            install_deps_debian
            ;;
        centos|rhel|fedora|rocky|alma|amzn|ol)
            install_deps_rhel
            ;;
        arch|manjaro)
            step "安装系统依赖"
            pacman -Sy --noconfirm git curl wget python python-pip \
                base-devel ripgrep ffmpeg > /dev/null 2>&1
            ok "Arch 依赖安装完成"
            ;;
        *)
            warn "未知系统 ${OS_ID}，尝试通用安装..."
            install_deps_debian || install_deps_rhel || fail "依赖安装失败，请手动安装: git curl python3 pip"
            ;;
    esac
}

# ── Python Version Check ───────────────────────────────────────────────
check_python() {
    step "检查 Python 版本"

    PYTHON_CMD=""
    for cmd in python3.12 python3.11 python3; do
        if command -v "$cmd" &>/dev/null; then
            ver=$("$cmd" --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
            major=$(echo "$ver" | cut -d. -f1)
            minor=$(echo "$ver" | cut -d. -f2)
            if [[ "$major" -ge 3 ]] && [[ "$minor" -ge 11 ]]; then
                PYTHON_CMD="$cmd"
                break
            fi
        fi
    done

    if [[ -z "$PYTHON_CMD" ]]; then
        warn "Python ${MIN_PYTHON_VERSION}+ 未找到，尝试安装..."
        install_python
    fi

    PYTHON_VERSION=$("$PYTHON_CMD" --version 2>&1)
    ok "Python: ${PYTHON_VERSION} (${PYTHON_CMD})"
}

install_python() {
    case "$OS_ID" in
        ubuntu|debian)
            apt-get install -y -qq software-properties-common > /dev/null 2>&1
            add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
            apt-get update -qq
            apt-get install -y -qq python3.11 python3.11-venv python3.11-dev > /dev/null 2>&1
            PYTHON_CMD="python3.11"
            ;;
        centos|rhel|fedora|rocky|alma)
            dnf install -y -q python3.11 python3.11-devel 2>/dev/null || \
            yum install -y -q python3.11 python3.11-devel 2>/dev/null || \
            fail "无法安装 Python 3.11，请手动安装"
            PYTHON_CMD="python3.11"
            ;;
        *)
            fail "请手动安装 Python ${MIN_PYTHON_VERSION}+"
            ;;
    esac
}

# ── Clone & Install KOPI Agent ─────────────────────────────────────────
install_kopi() {
    step "安装 KOPI Siew Dai"

    if [[ -d "$KOPI_HOME/.git" ]]; then
        info "检测到已有安装，更新中..."
        cd "$KOPI_HOME"
        git pull origin main --quiet 2>/dev/null || warn "更新失败，使用现有版本"
    else
        info "克隆仓库到 ${KOPI_HOME}..."
        rm -rf "$KOPI_HOME"
        git clone --depth=1 "$REPO_URL" "$KOPI_HOME" --quiet
    fi

    cd "$KOPI_HOME"

    info "创建虚拟环境..."
    $PYTHON_CMD -m venv venv --clear
    source venv/bin/activate

    info "安装依赖（这可能需要几分钟）..."
    pip install --upgrade pip -q 2>/dev/null
    pip install -e ".[all]" -q 2>/dev/null || pip install -e . -q 2>/dev/null

    ok "KOPI Siew Dai 安装完成"
}

# ── Create CLI Wrapper ─────────────────────────────────────────────────
create_cli_wrapper() {
    step "创建 kopi 命令"

    cat > /usr/local/bin/kopi << WRAPPER
#!/usr/bin/env bash
# KOPI Siew Dai CLI wrapper
source ${KOPI_HOME}/venv/bin/activate 2>/dev/null || true
export PYTHONPATH="${KOPI_HOME}:\$PYTHONPATH"
cd ${KOPI_HOME}
exec ${KOPI_HOME}/venv/bin/python ${KOPI_HOME}/kopi "\$@"
WRAPPER
    chmod +x /usr/local/bin/kopi

    ok "kopi 命令已安装到 /usr/local/bin/kopi"
}

# ── API Key Auto-Provision ─────────────────────────────────────────────
provision_api_key() {
    step "开通 API 账号"

    # Check if key already exists
    if [[ -f "$KOPI_CREDENTIALS_FILE" ]]; then
        existing_key=$(cat "$KOPI_CREDENTIALS_FILE" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$existing_key" ]] && [[ "$existing_key" == kp-* ]]; then
            ok "已有 API Key，跳过开通"
            KOPI_API_KEY="$existing_key"
            return
        fi
    fi

    # Use env var if provided
    if [[ -n "${KOPI_API_KEY:-}" ]]; then
        info "使用环境变量提供的 API Key"
    else
        echo -n "  🔑 正在开通账号..."
        PROVISION_RESP=$(curl -s -X POST "$PROVISION_URL" \
            -H "Content-Type: application/json" \
            -H "x-provision-token: $PROVISION_TOKEN" \
            --connect-timeout 10 \
            --max-time 30 2>/dev/null || echo "")

        KOPI_API_KEY=$(echo "$PROVISION_RESP" | $PYTHON_CMD -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('api_key', ''))
except:
    print('')
" 2>/dev/null || echo "")

        if [[ -z "$KOPI_API_KEY" ]]; then
            echo -e "${RED}失败${NC}"
            echo ""
            echo "  开通账号失败，请手动提供密钥:"
            echo "    curl -fsSL https://kopi.readinghero.xyz/install-siew-dai.sh | KOPI_API_KEY=kp-xxx bash"
            fail "API Key 获取失败"
        fi
        echo -e "${GREEN}✓${NC}"
    fi

    # Save credentials (root only)
    mkdir -p "$(dirname "$KOPI_CREDENTIALS_FILE")"
    echo "$KOPI_API_KEY" > "$KOPI_CREDENTIALS_FILE"
    chmod 600 "$KOPI_CREDENTIALS_FILE"
    ok "API Key 已安全存储"
}

# ── Config Generation ──────────────────────────────────────────────────
generate_config() {
    step "生成配置文件"

    mkdir -p "$KOPI_CONFIG_DIR"

    # config.yaml — api_key inline (custom provider requires it)
    cat > "$KOPI_CONFIG_DIR/config.yaml" << CONFIG
# ═══════════════════════════════════════════════════════════════════════
# KOPI Siew Dai 配置文件
# By Xing Bao Ku PTE LTD
# ═══════════════════════════════════════════════════════════════════════

# 大模型配置
model:
  default: kopi-siew-dai
  provider: custom
  base_url: https://kopi.readinghero.xyz/kp/v1
  api_key: ${KOPI_API_KEY}
  context_length: 256000

# 代理配置
agent:
  max_turns: 90

# 终端配置
terminal:
  timeout: 180

# 显示配置
display:
  skin: default
  show_cost: true

# 内存配置
memory:
  memory_enabled: true
  user_profile_enabled: true

# 安全配置
security:
  approvals:
    mode: smart

# 压缩配置
compression:
  enabled: true
  threshold: 0.50
  target_ratio: 0.20
CONFIG

    # .env file
    cat > "$KOPI_CONFIG_DIR/.env" << ENV
# KOPI Siew Dai Environment Variables
# 时区
TZ=Asia/Singapore
ENV

    ok "配置文件已生成: $KOPI_CONFIG_DIR/"
}

# ── Skills Installation ────────────────────────────────────────────────
install_skills() {
    step "预装实用技能"

    SKILLS_DIR="$KOPI_CONFIG_DIR/skills"
    mkdir -p "$SKILLS_DIR"

    # Copy curated skills bundle
    BUNDLE_DIR="$KOPI_HOME/skills-bundle"
    if [[ -d "$BUNDLE_DIR" ]]; then
        info "从精选技能包安装..."
        for category_dir in "$BUNDLE_DIR"/*/; do
            category=$(basename "$category_dir")
            for skill_dir in "$category_dir"*/; do
                skill_name=$(basename "$skill_dir")
                dst="$SKILLS_DIR/$category/$skill_name"
                mkdir -p "$(dirname "$dst")"
                cp -r "$skill_dir" "$dst" 2>/dev/null || true
            done
        done
    fi

    # Also copy all bundled skills as fallback
    if [[ -d "$KOPI_HOME/skills" ]]; then
        info "复制内置技能..."
        for skill_dir in "$KOPI_HOME/skills/"*/; do
            skill_name=$(basename "$skill_dir")
            if [[ ! -d "$SKILLS_DIR/$skill_name" ]]; then
                cp -r "$skill_dir" "$SKILLS_DIR/$skill_name" 2>/dev/null || true
            fi
        done
    fi

    SKILL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l)
    ok "已安装 ${SKILL_COUNT} 个技能"
}

# ── Gateway Configuration ──────────────────────────────────────────────
configure_gateway() {
    # Skip in non-interactive mode
    if [[ "$IS_TTY" != "true" ]]; then
        info "非交互模式，跳过 Gateway 配置"
        info "安装完成后运行以下命令配置消息平台:"
        echo ""
        echo -e "  ${BOLD}kopi gateway setup${NC}       # 交互式配置 Telegram / WeChat"
        echo ""
        return
    fi

    step "配置消息平台"

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  请选择消息平台:                          ║${NC}"
    echo -e "${BOLD}║                                          ║${NC}"
    echo -e "${BOLD}║  ${CYAN}1${NC}${BOLD}) Telegram (推荐)                       ║${NC}"
    echo -e "${BOLD}║  ${CYAN}2${NC}${BOLD}) WeChat (微信)                         ║${NC}"
    echo -e "${BOLD}║  ${CYAN}3${NC}${BOLD}) 两者都要                               ║${NC}"
    echo -e "${BOLD}║  ${CYAN}4${NC}${BOLD}) 稍后配置                               ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""

    read -rp "  请选择 [1-4]: " choice

    case "$choice" in
        1)
            configure_telegram
            ;;
        2)
            configure_wechat
            ;;
        3)
            configure_telegram
            configure_wechat
            ;;
        4)
            info "稍后运行 kopi gateway setup 配置"
            return
            ;;
        *)
            warn "无效选择，跳过配置"
            return
            ;;
    esac

    # Install and start gateway service
    install_gateway_service
}

configure_telegram() {
    echo ""
    echo -e "${BOLD}── Telegram Bot 配置 ──${NC}"
    echo ""
    echo "  获取 Bot Token:"
    echo "  1. 在 Telegram 搜索 @BotFather"
    echo "  2. 发送 /newbot"
    echo "  3. 按提示设置名称"
    echo "  4. 复制获得的 Token"
    echo ""

    read -rp "  请输入 Telegram Bot Token: " TG_TOKEN

    if [[ -z "$TG_TOKEN" ]]; then
        warn "Token 为空，跳过 Telegram 配置"
        return
    fi

    # Append gateway config to config.yaml
    cat >> "$KOPI_CONFIG_DIR/config.yaml" << TGCONFIG

# Telegram 配置
gateway:
  telegram:
    bot_token: "${TG_TOKEN}"
TGCONFIG

    # Also add to .env
    echo "TELEGRAM_BOT_TOKEN=${TG_TOKEN}" >> "$KOPI_CONFIG_DIR/.env"

    ok "Telegram 配置完成"
}

configure_wechat() {
    echo ""
    echo -e "${BOLD}── WeChat 配置 ──${NC}"
    echo ""
    echo "  WeChat 使用 iLink Bot API"
    echo "  请准备 iLink Bot Token 和 Bot ID"
    echo ""

    read -rp "  请输入 iLink Bot Token: " WX_TOKEN
    read -rp "  请输入 iLink Bot ID: " WX_BOT_ID

    if [[ -z "$WX_TOKEN" ]] || [[ -z "$WX_BOT_ID" ]]; then
        warn "Token 或 ID 为空，跳过 WeChat 配置"
        return
    fi

    # Append gateway config to config.yaml
    cat >> "$KOPI_CONFIG_DIR/config.yaml" << WXCONFIG

# WeChat 配置
gateway:
  weixin:
    bot_token: "${WX_TOKEN}"
    ilink_bot_id: "${WX_BOT_ID}"
    status: confirmed
WXCONFIG

    # Also add to .env
    echo "WEIXIN_BOT_TOKEN=${WX_TOKEN}" >> "$KOPI_CONFIG_DIR/.env"
    echo "WEIXIN_BOT_ID=${WX_BOT_ID}" >> "$KOPI_CONFIG_DIR/.env"

    ok "WeChat 配置完成"
}

install_gateway_service() {
    info "安装 Gateway 服务..."

    # Create systemd service
    cat > /etc/systemd/system/kopi-gateway.service << SERVICE
[Unit]
Description=KOPI Siew Dai Gateway
After=network.target
StartLimitIntervalSec=600
StartLimitBurst=5

[Service]
Type=simple
ExecStart=${KOPI_HOME}/venv/bin/python ${KOPI_HOME}/scripts/kopi-gateway run
WorkingDirectory=${KOPI_HOME}
Restart=on-failure
RestartSec=30
EnvironmentFile=${KOPI_CONFIG_DIR}/.env

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable kopi-gateway 2>/dev/null || true

    echo ""
    read -rp "  是否现在启动 Gateway? [Y/n]: " start_gw

    if [[ "${start_gw:-Y}" =~ ^[Yy]$ ]]; then
        systemctl start kopi-gateway
        ok "Gateway 已启动"
        info "查看状态: systemctl status kopi-gateway"
        info "查看日志: journalctl -u kopi-gateway -f"
    else
        info "稍后启动: systemctl start kopi-gateway"
    fi
}

# ── Completion ─────────────────────────────────────────────────────────
show_completion() {
    echo ""
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  ✓ KOPI Siew Dai 安装完成!${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}快速开始:${NC}"
    echo -e "    kopi              # 交互式聊天"
    echo -e "    kopi setup        # 完整设置向导"
    echo -e "    kopi gateway      # 启动消息网关"
    echo -e "    kopi doctor       # 诊断问题"
    echo ""
    echo -e "  ${BOLD}Gateway 管理:${NC}"
    echo -e "    systemctl start kopi-gateway    # 启动"
    echo -e "    systemctl stop kopi-gateway     # 停止"
    echo -e "    systemctl status kopi-gateway   # 状态"
    echo -e "    journalctl -u kopi-gateway -f   # 日志"
    echo ""
    echo -e "  ${BOLD}配置文件:${NC}"
    echo -e "    ${KOPI_CONFIG_DIR}/config.yaml"
    echo -e "    ${KOPI_CONFIG_DIR}/.env"
    echo -e "    ${KOPI_CREDENTIALS_FILE}"
    echo ""
    echo -e "  ${DIM}文档: https://kopi.readinghero.xyz/docs/${NC}"
    echo -e "  ${DIM}支持: https://github.com/LINYIQ66/kopi-agent/issues${NC}"
    echo ""
    echo -e "${BOLD}  Built with ❤️ by Xing Bao Ku PTE LTD${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════

main() {
    banner

    # Check if root
    if [[ $EUID -ne 0 ]]; then
        fail "请使用 root 运行: sudo bash 或 sudo -E bash"
    fi

    detect_os
    install_deps
    check_python
    install_kopi
    create_cli_wrapper
    provision_api_key
    generate_config
    install_skills
    configure_gateway          # Last step — skipped in non-interactive mode
    show_completion
}

main "$@"
