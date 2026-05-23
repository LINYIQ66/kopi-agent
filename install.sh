#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# KOPI O Agent — 一键安装脚本
# By Xing Bao Ku PTE LTD
#
# Usage:
#   curl -fsSL https://kopi.readinghero.xyz/install.sh | bash
#   curl -fsSL https://kopi.readinghero.xyz/install.sh | KOPI_API_KEY=kp-xxx bash
#
# Non-interactive mode (curl | bash): installs everything, skips gateway config.
# Interactive mode (bash install.sh): full install + gateway setup at the end.
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
KOPI_HOME="${KOPI_HOME:-/usr/local/lib/kopi-agent}"
KOPI_CONFIG_DIR="${KOPI_CONFIG_DIR:-$HOME/.kopi}"
KOPI_CREDENTIALS_FILE="/etc/kopi-agent/credentials"
PROVISION_URL="https://kopi.readinghero.xyz/kp/v1/provision"
# PROVISION_TOKEN 由后端动态注入，不要硬编码
PROVISION_TOKEN="${KOPI_PROVISION_TOKEN:-}"
REPO_URL="https://github.com/LINYIQ66/kopi-agent.git"
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
    echo -e "${DIM}  KOPI O Agent — by Xing Bao Ku PTE LTD${NC}"
    echo -e "${DIM}  一键安装，一步到位${NC}"
    echo ""
}

# ── OS Detection ───────────────────────────────────────────────────────
detect_os() {
    OS_TYPE=$(uname -s)
    
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        OS_ID="macos"
        OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
        IS_MACOS=true
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"
        IS_MACOS=false
    elif [[ -f /etc/redhat-release ]]; then
        OS_ID="centos"
        OS_VERSION=$(grep -oP '\d+' /etc/redhat-release | head -1)
        IS_MACOS=false
    else
        OS_ID="unknown"
        OS_VERSION="unknown"
        IS_MACOS=false
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
install_deps_macos() {
    step "安装系统依赖"
    
    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        info "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install dependencies via Homebrew
    brew install -q git curl wget python3 ripgrep ffmpeg 2>/dev/null || true
    
    ok "macOS 依赖安装完成"
}

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
            if [[ "$IS_CHINA" == "true" ]]; then
                # Use Tsinghua mirror for China
                info "使用清华镜像源加速..."
                sed -i 's|http://archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list 2>/dev/null || true
                sed -i 's|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list 2>/dev/null || true
                sed -i 's|http://ports.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/*.list 2>/dev/null || true
                # For ARM64 (aarch64) on Tencent Cloud, also fix ports.ubuntu.com
                if [[ "$(uname -m)" == "aarch64" ]]; then
                    sed -i 's|http://ports.ubuntu.com/ubuntu-ports|https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports|g' /etc/apt/sources.list.d/*.list 2>/dev/null || true
                fi
            fi
            apt-get update -qq
            # Try system python3 first (most Chinese VPS have it pre-installed)
            if command -v python3.11 &>/dev/null; then
                PYTHON_CMD="python3.11"
            elif command -v python3.12 &>/dev/null; then
                PYTHON_CMD="python3.12"
            elif python3 --version 2>/dev/null | grep -qE "3\.(1[1-9]|[2-9][0-9])"; then
                PYTHON_CMD="python3"
            elif [[ "$IS_CHINA" == "true" ]]; then
                # In China, PPA is unreliable — try deadsnakes but fallback to system python3
                apt-get install -y -qq software-properties-common > /dev/null 2>&1
                add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1 || true
                apt-get update -qq
                apt-get install -y -qq python3.11 python3.11-venv python3.11-dev > /dev/null 2>&1 || \
                apt-get install -y -qq python3 python3-venv python3-dev > /dev/null 2>&1 || \
                fail "无法安装 Python，请手动安装: apt install python3 python3-venv"
                PYTHON_CMD=$(command -v python3.11 || echo "python3")
            else
                apt-get install -y -qq software-properties-common > /dev/null 2>&1
                add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
                apt-get update -qq
                apt-get install -y -qq python3.11 python3.11-venv python3.11-dev > /dev/null 2>&1
                PYTHON_CMD="python3.11"
            fi
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
    step "安装 KOPI O Agent"

    if [[ -d "$KOPI_HOME/.git" ]]; then
        info "检测到已有安装，更新中..."
        cd "$KOPI_HOME"
        git pull origin main --quiet 2>/dev/null || warn "更新失败，使用现有版本"
    else
        info "克隆仓库到 ${KOPI_HOME}..."
        rm -rf "$KOPI_HOME"
        if [[ "$IS_CHINA" == "true" ]]; then
            info "使用 GitHub 镜像加速..."
            git clone --depth=1 "https://ghfast.top/${REPO_URL}" "$KOPI_HOME" --quiet 2>/dev/null || \
            git clone --depth=1 "https://ghproxy.net/${REPO_URL}" "$KOPI_HOME" --quiet 2>/dev/null || \
            git clone --depth=1 "$REPO_URL" "$KOPI_HOME" --quiet || \
            fail "克隆失败，请检查网络"
        else
            git clone --depth=1 "$REPO_URL" "$KOPI_HOME" --quiet
        fi
    fi

    cd "$KOPI_HOME"

    info "创建虚拟环境..."
    $PYTHON_CMD -m venv venv --clear
    source venv/bin/activate

    info "安装依赖（这可能需要几分钟）..."
    pip install --upgrade pip -q 2>/dev/null
    if [[ "$IS_CHINA" == "true" ]]; then
        info "使用清华 PyPI 镜像加速..."
        pip install -e ".[all]" -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn -q 2>/dev/null || \
        pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn -q 2>/dev/null || \
        pip install -e ".[all]" -q 2>/dev/null || pip install -e . -q 2>/dev/null
    else
        pip install -e ".[all]" -q 2>/dev/null || pip install -e . -q 2>/dev/null
    fi

    ok "KOPI O Agent 安装完成"
}

# ── Create CLI Wrapper ─────────────────────────────────────────────────
create_cli_wrapper() {
    step "创建 kopi 命令"

    cat > /usr/local/bin/kopi << WRAPPER
#!/usr/bin/env bash
# KOPI O Agent CLI wrapper
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
        
        # 如果没有 provision token，自动获取
        if [[ -z "$PROVISION_TOKEN" ]]; then
            echo -n "获取安装凭证..."
            AUTO_PROVISION_RESP=$(curl -s -X POST "https://kopi.readinghero.xyz/kp/v1/auto-provision" \
                -H "Content-Type: application/json" \
                --connect-timeout 10 \
                --max-time 30 2>/dev/null || echo "")
            
            PROVISION_TOKEN=$(echo "$AUTO_PROVISION_RESP" | $PYTHON_CMD -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('token', ''))
except:
    print('')
" 2>/dev/null || echo "")
            
            if [[ -z "$PROVISION_TOKEN" ]]; then
                echo -e "${RED}失败${NC}"
                echo ""
                echo "  无法自动获取安装凭证，请手动提供 API Key:"
                echo "    curl -fsSL https://kopi.readinghero.xyz/install.sh | KOPI_API_KEY=kp-xxx bash"
                fail "获取安装凭证失败"
            fi
            echo -e "${GREEN}✓${NC}"
            echo -n "  🔑 正在开通账号..."
        fi
        
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
            echo "    curl -fsSL https://kopi.readinghero.xyz/install.sh | KOPI_API_KEY=kp-xxx bash"
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
# KOPI O Agent 配置文件
# By Xing Bao Ku PTE LTD
# ═══════════════════════════════════════════════════════════════════════

# 大模型配置
model:
  default: kopi-flash
  provider: custom
  base_url: https://kopi.readinghero.xyz/kp/v1
  api_key: ${KOPI_API_KEY}
  context_length: 256000

# 备用节点（自动故障转移）
providers:
  node2:
    provider: custom
    base_url: http://159.223.32.193:5005/v1
    api_key: ${KOPI_API_KEY}
    context_length: 256000
fallback_providers:
  - node2

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

# 压缩配置（PraisonAI 风格：自动压缩长对话）
compression:
  enabled: true
  threshold: 0.50
  target_ratio: 0.20
  auto_compact: true  # 自动压缩，避免 token 超限

# Doom Loop Detection（借鉴 PraisonAI：卡住自动恢复）
safety:
  doom_loop_detection: true
  max_same_tool_calls: 3  # 同一工具连续调用 3 次视为卡住
  auto_recovery: true  # 自动重启 agent
  timeout_per_turn: 300  # 单轮最大 5 分钟

# Guardrails（借鉴 PraisonAI：智能验证）
guardrails:
  enabled: true
  input:
    max_length: 200000  # 输入最大 200K 字符（约 50K tokens）
  output:
    max_length: 200000  # 输出最大 200K 字符（代码生成需要）
    strip_sensitive: true  # 自动脱敏（API key、密码等）
  rate_limit:
    max_requests_per_minute: 30  # 防滥用
    max_tokens_per_hour: 500000  # 每小时 50 万 token 上限

# Model Router（借鉴 PraisonAI：智能路由，自动选最便宜可用模型）
model_router:
  enabled: true
  strategy: cost_optimized  # cost_optimized | latency_optimized | balanced
  routes:
    simple: kopi-flash      # 简单任务（问答、翻译）→ DeepSeek V4 Flash（免费）
    coding: kopi-grok       # 代码任务 → Grok 4.3（MCP）
    reasoning: kopi-grok    # 推理任务 → Grok 4.3（MCP）
    standard: kopi-o-pro    # 标准任务 → MiMo V2 Pro
  complexity_threshold: 0.7  # 复杂度阈值，超过则升级模型

# Memory 增强（借鉴 PraisonAI：图记忆 + 长短期记忆）
memory:
  memory_enabled: true
  user_profile_enabled: true
  graph_memory: true  # 图数据库记忆（实体关系追踪）
  short_term:
    max_items: 50  # 短期记忆 50 条
    ttl: 3600  # 1 小时过期
  long_term:
    max_items: 1000  # 长期记忆 1000 杇
    auto_consolidate: true  # 自动合并相似记忆

# Checkpoint（借鉴 PraisonAI：代码任务自动回滚）
checkpoint:
  enabled: true
  auto_checkpoint: true  # 代码修改前自动保存
  max_checkpoints: 10  # 保留最近 10 个检查点
  auto_rollback_on_error: true  # 出错自动回滚

# Session 管理（借鉴 PraisonAI：自动保存和恢复）
session:
  auto_save: true
  save_interval: 300  # 每 5 分钟自动保存
  max_history: 100  # 保留最近 100 轮对话
  resume_on_restart: true  # 重启后自动恢复

# MCP 服务器配置（Coding/推理/Grok 4.3）
mcp:
  servers:
    kopi:
      url: https://sub.readinghero.xyz/mcp/sse
      headers:
        Authorization: Bearer sk-mcp-eead7fc88a5efce316b5f3effcaba65f
  auto_discover: true  # 自动发现 MCP 工具
  timeout: 30  # MCP 调用超时 30 秒
CONFIG

    # .env file
    cat > "$KOPI_CONFIG_DIR/.env" << ENV
# KOPI O Agent Environment Variables
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
Description=KOPI O Agent Gateway
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
    echo -e "${BOLD}${GREEN}  ✓ KOPI O Agent 安装完成!${NC}"
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
    detect_china
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
