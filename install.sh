#!/usr/bin/env bash
# LazyVim Codespaces 一键安装脚本
# 支持 GitHub Codespaces (Ubuntu/Debian)

set -eo pipefail

# 配置
NVIM_VERSION="0.11.7"  # Neovim 版本
REPO_URL="https://github.com/YuvbMowh/neovimsh.git"  # 配置仓库
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE_INSTALL="${FORCE_INSTALL:-false}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查操作系统
check_os() {
    log_info "检查操作系统..."
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法识别操作系统"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" && "$ID_LIKE" != *"ubuntu"* && "$ID_LIKE" != *"debian"* ]]; then
        log_warn "此脚本主要为 Ubuntu/Debian 设计，当前系统：$ID"
        read -p "是否继续？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "操作系统：$ID $VERSION_ID"
}

# 检查 CPU 架构
check_arch() {
    log_info "检查 CPU 架构..."
    
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64)
            NVIM_ARCH="linux64"
            ;;
        aarch64|arm64)
            NVIM_ARCH="linux-arm64"
            log_warn "ARM64 架构，部分插件可能不支持预编译二进制"
            ;;
        *)
            log_error "不支持的架构：$ARCH"
            exit 1
            ;;
    esac
    
    log_success "架构：$ARCH"
}

# 检查必要工具
check_dependencies() {
    log_info "检查必要工具..."
    
    local missing_tools=()
    local tools=("curl" "tar" "git")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warn "缺少工具：${missing_tools[*]}"
        log_info "尝试自动安装..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq "${missing_tools[@]}"
        else
            log_error "无法自动安装缺失工具，请手动安装：${missing_tools[*]}"
            exit 1
        fi
    fi
    
    log_success "必要工具已就绪"
}

# 检查 Neovim 是否已安装
check_neovim() {
    log_info "检查 Neovim..."
    
    if command -v nvim &> /dev/null; then
        local current_version
        current_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9.]+')
        log_info "已安装 Neovim $current_version"
        
        if [[ "$current_version" == "$NVIM_VERSION" ]]; then
            log_success "Neovim 版本匹配"
            return 0
        elif [[ "$FORCE_INSTALL" == "false" ]]; then
            log_warn "版本不匹配（期望：$NVIM_VERSION）"
            read -p "是否重新安装 Neovim $NVIM_VERSION？(y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "跳过 Neovim 安装"
                return 0
            fi
        fi
    fi
    
    return 1
}

# 安装 Neovim
install_neovim() {
    log_info "开始安装 Neovim $NVIM_VERSION..."
    
    # 根据版本确定文件名格式
    # v0.11+ 使用 nvim-linux-x86_64.tar.gz
    # v0.10 及更早使用 nvim-linux64.tar.gz
    local download_filename
    if [[ "$NVIM_ARCH" == "linux64" ]]; then
        # 检查版本号是否 >= 0.11
        local major minor
        IFS='.' read -r major minor _ <<< "$NVIM_VERSION"
        if [[ $major -eq 0 && $minor -ge 11 ]] || [[ $major -gt 0 ]]; then
            download_filename="nvim-linux-x86_64.tar.gz"
        else
            download_filename="nvim-${NVIM_ARCH}.tar.gz"
        fi
    else
        # ARM64
        if [[ "$NVIM_ARCH" == "linux-arm64" ]]; then
            download_filename="nvim-linux-arm64.tar.gz"
        else
            download_filename="nvim-${NVIM_ARCH}.tar.gz"
        fi
    fi
    
    local download_url="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/${download_filename}"
    local temp_dir
    temp_dir=$(mktemp -d)
    
    log_info "下载 Neovim..."
    if ! curl -fsSL "$download_url" -o "$temp_dir/nvim.tar.gz"; then
        log_error "下载失败：$download_url"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    log_info "解压 Neovim..."
    tar -xzf "$temp_dir/nvim.tar.gz" -C "$temp_dir"
    
    log_info "安装 Neovim 到 ~/.local/..."
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/nvim"
    
    # 查找解压后的目录（可能是 nvim-linux64 或 nvim-linux-x86_64）
    local nvim_dir
    nvim_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "nvim-*" | head -1)
    
    if [[ -z "$nvim_dir" ]]; then
        log_error "无法找到解压后的 Neovim 目录"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 复制二进制文件
    cp -f "$nvim_dir/bin/nvim" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/nvim"
    
    # 复制运行时文件
    if [[ -d "$nvim_dir/share/nvim" ]]; then
        cp -rf "$nvim_dir/share/nvim/runtime" "$HOME/.local/share/nvim/"
    fi
    
    # 复制库文件（如果有）
    if [[ -d "$nvim_dir/lib" ]]; then
        mkdir -p "$HOME/.local/lib"
        cp -rf "$nvim_dir/lib/"* "$HOME/.local/lib/"
    fi
    
    rm -rf "$temp_dir"
    
    # 检查 PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_warn "$HOME/.local/bin 不在 PATH 中"
        log_info "添加到 ~/.bashrc..."
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # 验证安装
    if "$HOME/.local/bin/nvim" --version &> /dev/null; then
        log_success "Neovim 安装成功"
    else
        log_error "Neovim 安装失败"
        exit 1
    fi
}

# 安装常用依赖工具
install_common_tools() {
    log_info "安装常用开发工具..."
    
    local tools=(
        "ripgrep"      # 搜索工具（推荐）
        "fd-find"      # 文件查找（推荐）
        "build-essential"  # 编译工具
        "unzip"        # 解压工具
    )
    
    if command -v apt-get &> /dev/null; then
        log_info "通过 apt-get 安装工具..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${tools[@]}" 2>/dev/null || log_warn "部分工具安装失败（可能已安装）"
        
        # Debian/Ubuntu 的 fd-find 需要创建链接
        if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
        fi
    fi
    
    log_success "开发工具安装完成"
}

# 备份现有配置
backup_existing_config() {
    if [[ -d "$NVIM_CONFIG_DIR" ]] || [[ -L "$NVIM_CONFIG_DIR" ]]; then
        log_warn "检测到现有 Neovim 配置"
        
        if [[ "$FORCE_INSTALL" == "false" ]]; then
            read -p "是否备份现有配置？(Y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                log_info "跳过备份"
                return 0
            fi
        fi
        
        log_info "备份现有配置到 $BACKUP_DIR..."
        mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
        log_success "配置已备份"
    fi
}

# 安装 LazyVim 配置
install_config() {
    log_info "安装 LazyVim 配置..."
    
    # 确保配置目录不存在
    if [[ -e "$NVIM_CONFIG_DIR" ]]; then
        log_error "配置目录仍然存在：$NVIM_CONFIG_DIR"
        exit 1
    fi
    
    # 检查配置源目录
    if [[ -d "$SCRIPT_DIR/nvim" ]]; then
        log_info "从本地复制配置..."
        cp -r "$SCRIPT_DIR/nvim" "$NVIM_CONFIG_DIR"
    else
        log_info "本地配置不存在，从 GitHub 克隆..."
        
        # 创建临时目录
        local temp_dir
        temp_dir=$(mktemp -d)
        
        log_info "克隆配置仓库..."
        if git clone --depth 1 "$REPO_URL" "$temp_dir" 2>&1; then
            if [[ -d "$temp_dir/nvim" ]]; then
                cp -r "$temp_dir/nvim" "$NVIM_CONFIG_DIR"
                rm -rf "$temp_dir"
                log_success "配置已从仓库克隆"
            else
                log_error "仓库中找不到 nvim 配置目录"
                rm -rf "$temp_dir"
                exit 1
            fi
        else
            log_error "克隆仓库失败"
            log_info "请检查网络连接或手动克隆："
            log_info "  git clone $REPO_URL"
            log_info "  cd neovimsh"
            log_info "  ./install.sh"
            rm -rf "$temp_dir"
            exit 1
        fi
    fi
    
    log_success "LazyVim 配置已安装"
}

# 安装 lazy.nvim 和插件
install_plugins() {
    log_info "初始化 lazy.nvim 和插件..."
    
    local lazy_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
    
    if [[ ! -d "$lazy_path" ]]; then
        log_info "克隆 lazy.nvim..."
        git clone --filter=blob:none --branch=stable \
            https://github.com/folke/lazy.nvim.git "$lazy_path"
    fi
    
    log_info "安装插件（这可能需要几分钟）..."
    
    # 使用 headless 模式安装插件
    if "$HOME/.local/bin/nvim" --headless "+Lazy! sync" +qa 2>&1 | tee /tmp/nvim-lazy-install.log; then
        log_success "插件安装完成"
    else
        log_warn "插件安装可能有警告，请查看日志：/tmp/nvim-lazy-install.log"
    fi
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    # 基本启动测试
    if "$HOME/.local/bin/nvim" --headless "+checkhealth" +qa &> /tmp/nvim-health.log; then
        log_success "Neovim 可以正常启动"
    else
        log_warn "健康检查有警告，详见：/tmp/nvim-health.log"
    fi
}

# 打印安装总结
print_summary() {
    echo
    echo "================================================================"
    echo -e "${GREEN}LazyVim 安装完成！${NC}"
    echo "================================================================"
    echo
    echo "接下来："
    echo "  1. 启动 Neovim："
    echo "     $ nvim"
    echo
    echo "  2. LazyVim 快捷键："
    echo "     <Space>      - 打开 which-key（查看所有快捷键）"
    echo "     <Space>e     - 打开文件树（neo-tree）"
    echo "     <Space>ff    - 查找文件"
    echo "     <Space>sg    - 全局搜索"
    echo "     <Space>l     - 打开 Lazy 插件管理器"
    echo
    echo "  3. 查看安装的插件："
    echo "     进入 nvim 后输入 :Lazy"
    echo
    echo "  4. 更改主题："
    echo "     编辑 ~/.config/nvim/lua/plugins/theme.lua"
    echo "     可选主题：tokyonight, catppuccin, gruvbox, kanagawa, rose-pine 等"
    echo
    
    if [[ -d "$BACKUP_DIR" ]]; then
        echo "原配置备份在："
        echo "  $BACKUP_DIR"
        echo
    fi
    
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo -e "${YELLOW}注意：${NC}请重启终端或执行以下命令使 PATH 生效："
        echo "  source ~/.bashrc"
        echo
    fi
    
    echo "================================================================"
}

# 主函数
main() {
    echo "================================================================"
    echo "LazyVim Codespaces 安装脚本"
    echo "================================================================"
    echo
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_INSTALL="true"
                shift
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo
                echo "选项:"
                echo "  --force    强制安装，跳过所有确认提示"
                echo "  --help     显示此帮助信息"
                exit 0
                ;;
            *)
                log_error "未知选项：$1"
                echo "使用 --help 查看帮助"
                exit 1
                ;;
        esac
    done
    
    # 执行安装步骤
    check_os
    check_arch
    check_dependencies
    
    if ! check_neovim; then
        install_neovim
    fi
    
    install_common_tools
    backup_existing_config
    install_config
    install_plugins
    health_check
    print_summary
    
    log_success "安装完成！"
}

# 运行主函数
main "$@"
