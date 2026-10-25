#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
MANAGED_ROOT="$HOME/.local/opt/nvim-codespaces"
FORCE=false
PURGE=false

die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --purge) PURGE=true ;;
        --help|-h)
            printf '用法：%s [--force] [--purge]\n默认删除本脚本管理的配置和二进制，保留数据。\n--purge 额外删除全部 Neovim 插件、Mason、状态和缓存。\n' "$0"
            exit 0 ;;
        *) die "未知选项：$arg" ;;
    esac
done
[[ -z "${NVIM_APPNAME:-}" || "$NVIM_APPNAME" == nvim ]] || die "请先 unset NVIM_APPNAME。"
for path in "$CONFIG_DIR" "$DATA_DIR" "$STATE_DIR" "$CACHE_DIR"; do
    [[ "$path" == /* ]] || die "XDG 目录必须为绝对路径。"
done
[[ ! -L "$CONFIG_DIR" && -f "$CONFIG_DIR/.lazyvim-codespaces-managed" ]] ||
    die "配置没有本安装器的管理标记，拒绝自动删除：$CONFIG_DIR"
printf '将删除配置：%s\n' "$CONFIG_DIR"
if [[ "$PURGE" == true ]]; then
    printf '还将删除全部 Neovim 数据：\n%s\n%s\n%s\n' "$DATA_DIR" "$STATE_DIR" "$CACHE_DIR"
fi
if [[ "$FORCE" != true ]]; then
    [[ -t 0 ]] || die "非交互运行请显式传入 --force。"
    read -r -p '确认卸载？[y/N] ' answer
    [[ "$answer" == y || "$answer" == Y ]] || exit 0
fi
rm -rf -- "$CONFIG_DIR"
if [[ "$PURGE" == true ]]; then
    rm -rf -- "$DATA_DIR" "$STATE_DIR" "$CACHE_DIR"
fi
# Only remove a symlink and distribution owned by this installer.
link="$HOME/.local/bin/nvim"
if [[ -L "$link" ]]; then
    target=$(readlink -- "$link")
    if [[ "$target" == "$MANAGED_ROOT/"*/bin/nvim ]]; then
        distribution=${target%/bin/nvim}
        if [[ -f "$distribution/.lazyvim-codespaces-managed" ]]; then
            rm -- "$link"
            rm -rf -- "$distribution"
        fi
    fi
fi
printf '卸载完成；原配置备份、部署日志和系统 Neovim 均保留。\n'
