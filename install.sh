#!/usr/bin/env bash
# Ubuntu/Debian user-local deployment. Sourceable for filesystem regression tests.
set -Eeuo pipefail

NVIM_VERSION="${NVIM_VERSION:-0.11.7}"
REPO_URL="${REPO_URL:-https://github.com/YuvbMowh/neovimsh.git}"
REPO_REF="${REPO_REF:-master}"
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/lazyvim-codespaces"
MANAGED_ROOT="$HOME/.local/opt/nvim-codespaces"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
FORCE_INSTALL="${FORCE_INSTALL:-false}"
SKIP_TOOLS=false
NVIM_BIN=""
BACKUP_DIR=""
STAGE_DIR=""
WORK_DIR=""
CONFIG_CHANGED=false
COMMITTED=false

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

confirm() {
    [[ "$FORCE_INSTALL" == true ]] && return 0
    [[ -t 0 ]] || die "$1：非交互运行请显式传入 --force。"
    local answer
    read -r -p "$1 [y/N] " answer
    [[ "$answer" == y || "$answer" == Y ]]
}

cleanup() {
    local status=$?
    trap - EXIT
    if [[ "$COMMITTED" != true && "$CONFIG_CHANGED" == true ]]; then
        rm -rf -- "$NVIM_CONFIG_DIR"
        if [[ -n "$BACKUP_DIR" && ( -e "$BACKUP_DIR" || -L "$BACKUP_DIR" ) ]]; then
            mv -- "$BACKUP_DIR" "$NVIM_CONFIG_DIR" || log_warn "还原失败，备份保留在 $BACKUP_DIR"
        fi
        log_warn "部署未完成，新配置已撤回；插件数据和已安装工具可能已有变化。"
    fi
    [[ -z "$STAGE_DIR" ]] || rm -rf -- "$STAGE_DIR"
    [[ -z "$WORK_DIR" ]] || rm -rf -- "$WORK_DIR"
    exit "$status"
}

check_os() {
    [[ "$(uname -s)" == Linux && -f /etc/os-release ]] || die "仅支持 Linux Ubuntu/Debian。"
    local ID ID_LIKE
    source /etc/os-release
    case " $ID ${ID_LIKE:-} " in
        *ubuntu*|*debian*) ;;
        *) die "仅支持 Ubuntu/Debian；当前系统为 $ID。" ;;
    esac
    [[ -z "${NVIM_APPNAME:-}" || "$NVIM_APPNAME" == nvim ]] || die "请先 unset NVIM_APPNAME。"
    [[ "$NVIM_CONFIG_DIR" == /* && "$NVIM_DATA_DIR" == /* ]] || die "XDG 目录必须为绝对路径。"
}

check_arch() {
    case "$(uname -m)" in
        x86_64) NVIM_ARCH=x86_64 ;;
        aarch64|arm64) NVIM_ARCH=arm64 ;;
        *) die "不支持的 CPU 架构。" ;;
    esac
}

apt_install() {
    command -v apt-get >/dev/null || die "未找到 apt-get，请自行安装依赖。"
    local elevate=()
    if [[ "$(id -u)" != 0 ]]; then
        command -v sudo >/dev/null || die "需要 sudo 安装依赖，或使用 --skip-tools。"
        elevate=(sudo)
    fi
    "${elevate[@]}" apt-get update -qq
    "${elevate[@]}" apt-get install -y --no-install-recommends "$@"
}

check_dependencies() {
    local missing=() tool
    for tool in curl tar git python3 sha256sum; do
        command -v "$tool" >/dev/null || missing+=("$tool")
    done
    if ((${#missing[@]})); then
        [[ "$SKIP_TOOLS" != true ]] || die "缺少基础依赖：${missing[*]}"
        # sha256sum is supplied by coreutils.
        apt_install curl tar git python3 coreutils ca-certificates
    fi
}

check_neovim() {
    NVIM_BIN=$(command -v nvim || true)
    [[ -n "$NVIM_BIN" ]] || return 1
    local version
    version=$("$NVIM_BIN" --version)
    # Keep a compatible existing stable version instead of downgrading it.
    if python3 - "$version" <<'PY'
import re, sys
m = re.match(r'NVIM v(\d+)\.(\d+)\.(\d+)([^\n]*)', sys.argv[1])
sys.exit(0 if m and tuple(map(int, m.group(1, 2, 3))) >= (0, 11, 2)
         and not m.group(4).strip() else 1)
PY
    then
        log_info "使用已有 Neovim：$NVIM_BIN"
        return 0
    fi
    log_warn "现有 Neovim 不满足稳定版 >= 0.11.2，将安装 $NVIM_VERSION。"
    return 1
}

install_neovim() {
    [[ "$NVIM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "NVIM_VERSION 必须为稳定版本号。"
    local asset="nvim-linux-${NVIM_ARCH}.tar.gz"
    local destination="$MANAGED_ROOT/$NVIM_VERSION-$NVIM_ARCH"
    local link="$HOME/.local/bin/nvim" digest
    if [[ -e "$link" || -L "$link" ]]; then
        [[ -L "$link" && "$(readlink -- "$link")" == "$MANAGED_ROOT/"*/bin/nvim ]] ||
            die "$link 已存在且不由此脚本管理，请自行处理后重试。"
    fi
    if [[ -f "$destination/.lazyvim-codespaces-managed" ]]; then
        "$destination/bin/nvim" --clean --headless '+lua assert(vim.fn.has("nvim-0.11.2") == 1)' +qa
        ln -sfn -- "$destination/bin/nvim" "$link"
        NVIM_BIN="$link"
        export PATH="$HOME/.local/bin:$PATH"
        return
    fi
    mkdir -p -- "$MANAGED_ROOT" "$HOME/.local/bin"
    WORK_DIR=$(mktemp -d "$MANAGED_ROOT/.download.XXXXXXXX")
    curl --fail --location --retry 3 --connect-timeout 20 \
        "https://api.github.com/repos/neovim/neovim/releases/tags/v$NVIM_VERSION" -o "$WORK_DIR/release.json"
    digest=$(python3 - "$WORK_DIR/release.json" "$asset" <<'PY'
import json, re, sys
release = json.load(open(sys.argv[1]))
digest = next((a.get('digest', '') for a in release['assets'] if a['name'] == sys.argv[2]), '')
if not re.fullmatch(r'sha256:[a-f0-9]{64}', digest or ''):
    sys.exit('GitHub 未提供此文件的 SHA-256 digest，停止安装。')
print(digest[7:])
PY
    )
    curl --fail --location --retry 3 --connect-timeout 20 \
        "https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/$asset" -o "$WORK_DIR/$asset"
    printf '%s  %s\n' "$digest" "$WORK_DIR/$asset" | sha256sum --check --status
    tar -xzf "$WORK_DIR/$asset" -C "$WORK_DIR"
    "$WORK_DIR/nvim-linux-$NVIM_ARCH/bin/nvim" --clean --headless '+lua assert(vim.fn.has("nvim-0.11.2") == 1)' +qa
    # Preserve the complete upstream directory layout, including runtime and libs.
    if [[ -e "$destination" ]]; then
        die "$destination 已存在；请检查已有安装后重试。"
    fi
    mv -- "$WORK_DIR/nvim-linux-$NVIM_ARCH" "$destination"
    touch "$destination/.lazyvim-codespaces-managed"
    ln -sfn -- "$destination/bin/nvim" "$link"
    NVIM_BIN="$link"
    export PATH="$HOME/.local/bin:$PATH"
    rm -rf -- "$WORK_DIR"
    WORK_DIR=""
}

install_common_tools() {
    if [[ "$SKIP_TOOLS" == true ]]; then
        log_warn "已跳过开发依赖安装；请自行提供 rg、fd、C 编译器及语言工具链。"
        return
    fi
    apt_install ripgrep fd-find build-essential unzip ca-certificates
    if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -s -- "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
}

backup_existing_config() {
    if [[ -e "$NVIM_CONFIG_DIR" || -L "$NVIM_CONFIG_DIR" ]]; then
        confirm "备份并替换 $NVIM_CONFIG_DIR？" || die "已取消。"
        BACKUP_DIR=$(mktemp -d "${NVIM_CONFIG_DIR}.backup.XXXXXXXX")
        rmdir -- "$BACKUP_DIR"
        mv -- "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
        log_info "原配置备份：$BACKUP_DIR"
    fi
}

install_config() {
    local source_dir="$SCRIPT_DIR/nvim"
    mkdir -p -- "$(dirname -- "$NVIM_CONFIG_DIR")"
    STAGE_DIR=$(mktemp -d "${NVIM_CONFIG_DIR}.stage.XXXXXXXX")
    if [[ ! -d "$source_dir" ]]; then
        git clone --depth 1 --branch "$REPO_REF" -- "$REPO_URL" "$STAGE_DIR/repository"
        source_dir="$STAGE_DIR/repository/nvim"
    fi
    [[ -f "$source_dir/init.lua" && -f "$source_dir/lazy-lock.json" ]] || die "配置源不完整。"
    cp -a -- "$source_dir" "$STAGE_DIR/config"
    touch "$STAGE_DIR/config/.lazyvim-codespaces-managed"
    backup_existing_config
    CONFIG_CHANGED=true
    mv -- "$STAGE_DIR/config" "$NVIM_CONFIG_DIR"
    rm -rf -- "$STAGE_DIR"
    STAGE_DIR=""
}

install_plugins() {
    mkdir -p -- "$LOG_DIR"
    # The helper waits for lazy tasks and turns reported plugin errors into exit 1.
    LAZYVIM_INSTALL_HELPER="$NVIM_CONFIG_DIR/install-plugins.lua" \
        "$NVIM_BIN" --headless '+lua dofile(vim.env.LAZYVIM_INSTALL_HELPER)' \
        2>&1 | tee "$LOG_DIR/plugins.log"
}

health_check() {
    mkdir -p -- "$LOG_DIR"
    "$NVIM_BIN" --headless '+lua if vim.v.errmsg ~= "" then vim.api.nvim_err_writeln(vim.v.errmsg); vim.cmd("cquit 1") end' +qa \
        > "$LOG_DIR/startup.log" 2>&1
    log_info "启动检查通过；语言工具请在 Neovim 中运行 :checkhealth 检查。"
}

main() {
    while (($#)); do
        case "$1" in
            --force) FORCE_INSTALL=true ;;
            --skip-tools) SKIP_TOOLS=true ;;
            --help|-h)
                printf '用法：%s [--force] [--skip-tools]\n--force 自动备份并替换配置\n--skip-tools 不运行 apt（基础依赖仍须存在）\n' "$0"
                return ;;
            *) die "未知选项：$1" ;;
        esac
        shift
    done
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    check_os
    check_arch
    check_dependencies
    if ! check_neovim; then install_neovim; fi
    install_common_tools
    install_config
    install_plugins
    health_check
    COMMITTED=true
    log_info "安装完成：$NVIM_CONFIG_DIR"
    log_info "启动命令：$NVIM_BIN；日志：$LOG_DIR"
    log_info '若 nvim 不在 PATH，请在 shell 配置中添加：export PATH="$HOME/.local/bin:$PATH"'
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
    main "$@"
fi
