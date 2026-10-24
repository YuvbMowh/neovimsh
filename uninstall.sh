#!/usr/bin/env bash
# LazyVim Codespaces 卸载脚本

set -eo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
NVIM_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
NVIM_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
NVIM_BIN="$HOME/.local/bin/nvim"

echo "================================================================"
echo "LazyVim Codespaces 卸载脚本"
echo "================================================================"
echo

log_warn "此脚本将删除以下内容："
echo "  - Neovim 配置: $NVIM_CONFIG_DIR"
echo "  - Neovim 数据: $NVIM_DATA_DIR (插件、Mason 等)"
echo "  - Neovim 状态: $NVIM_STATE_DIR"
echo "  - Neovim 缓存: $NVIM_CACHE_DIR"
echo "  - Neovim 二进制: $NVIM_BIN"
echo

read -p "确认卸载？(y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "已取消"
    exit 0
fi

# 卸载配置
if [[ -d "$NVIM_CONFIG_DIR" ]] || [[ -L "$NVIM_CONFIG_DIR" ]]; then
    log_info "删除 Neovim 配置..."
    rm -rf "$NVIM_CONFIG_DIR"
    log_success "已删除配置"
else
    log_info "配置不存在，跳过"
fi

# 卸载数据
if [[ -d "$NVIM_DATA_DIR" ]]; then
    log_info "删除 Neovim 数据（插件、LSP 等）..."
    rm -rf "$NVIM_DATA_DIR"
    log_success "已删除数据"
else
    log_info "数据目录不存在，跳过"
fi

# 卸载状态
if [[ -d "$NVIM_STATE_DIR" ]]; then
    log_info "删除 Neovim 状态..."
    rm -rf "$NVIM_STATE_DIR"
    log_success "已删除状态"
else
    log_info "状态目录不存在，跳过"
fi

# 卸载缓存
if [[ -d "$NVIM_CACHE_DIR" ]]; then
    log_info "删除 Neovim 缓存..."
    rm -rf "$NVIM_CACHE_DIR"
    log_success "已删除缓存"
else
    log_info "缓存目录不存在，跳过"
fi

# 卸载 Neovim 二进制
if [[ -f "$NVIM_BIN" ]]; then
    log_info "删除 Neovim 二进制..."
    rm -f "$NVIM_BIN"
    log_success "已删除 Neovim"
else
    log_info "Neovim 二进制不存在，跳过"
fi

# 清理运行时文件
if [[ -d "$HOME/.local/share/nvim/runtime" ]]; then
    log_info "删除 Neovim 运行时文件..."
    rm -rf "$HOME/.local/share/nvim/runtime"
fi

echo
echo "================================================================"
log_success "卸载完成！"
echo "================================================================"
echo
echo "备份文件（如果有）保留在："
echo "  ~/.config/nvim.backup.*"
echo
echo "如果需要重新安装，运行："
echo "  curl -fsSL https://raw.githubusercontent.com/YuvbMowh/neovimsh/master/install.sh | bash"
echo
