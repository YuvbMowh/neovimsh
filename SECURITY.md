# 安全说明

## 隐私保护

此配置已经过严格的安全审计，确保不包含任何敏感信息。

### 已排除的内容

#### 1. LeetCode 插件 (高风险)

**原因**: 包含账号认证信息和 Cookie

- ❌ `lua/plugins/leetcode.lua` - 插件配置文件
- ❌ `lazy-lock.json` 中的 `leetcode.nvim` 条目
- ❌ LeetCode 解题记录（存储在 `~/test/leetcode/solutions`，不在配置范围内）

**影响**: 无法使用 LeetCode 插件，但不影响其他功能。

#### 2. 系统特定路径

**原因**: 包含用户名和系统绝对路径

- ❌ `theme.lua` 符号链接（原指向 `/home/reskdl/.local/state/omarchy/current/theme/neovim.lua`）
- ✅ 已替换为独立的主题配置文件，使用 `tokyonight` 作为默认主题

#### 3. 备份文件

**原因**: 可能包含临时测试数据

- ❌ 所有 `.bak` 文件
- ❌ 所有 `.bak.*` 文件

### 安全扫描结果

✅ **无硬编码的敏感信息**

- 未发现 API Keys
- 未发现 Access Tokens
- 未发现密码或凭据
- 未发现个人邮箱
- 未发现真实姓名

✅ **环境检测良好**

以下配置包含环境检测逻辑，在不支持的环境中自动禁用：

- `remote_clipboard.lua`: 仅在 SSH/tmux/herdr 环境中启用
- `autocmds.lua`: fcitx5 仅在 VSCode 且工具存在时启用
- 所有路径使用 `stdpath` 动态获取，无硬编码

## 公开发布指南

### 可以安全公开的内容

✅ **完全安全**

此配置可以：
- 推送到 GitHub 公开仓库
- 分享给他人使用
- 作为博客示例展示

所有文件都经过审计，不包含个人敏感信息。

### .gitignore 保护

`.gitignore` 已配置排除：

```gitignore
# 运行时文件
*.log
data/

# 备份文件
*.bak
*.bak.*
*.tmp
*.swp

# LeetCode（双重保险）
*leetcode*
*LeetCode*

# 系统文件
.DS_Store
*.local
```

### 推荐做法

即使配置已安全，仍建议：

1. **审查后再使用**: 浏览所有 Lua 文件，确保符合你的需求
2. **不添加敏感信息**: 
   - 不要在配置中硬编码密码、Token
   - 使用环境变量存储敏感数据
3. **定期更新**: 保持插件和 Neovim 版本更新
4. **备份重要数据**: 定期备份配置和插件锁定文件

## 功能需要重新配置

### 在 Codespaces 中首次使用

以下功能在新环境中需要重新设置（不在配置文件中）：

#### Git 配置

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

#### Mason LSP 安装

首次打开文件时，Mason 会自动安装 LSP 服务器，无需手动配置。

如需手动安装：

```vim
:Mason
```

然后按 `i` 安装需要的 LSP 服务器。

## 环境变量

此配置不依赖任何环境变量，但如果你需要自定义：

### 可选的环境变量

- `XDG_CONFIG_HOME`: Neovim 配置目录（默认：`~/.config`）
- `XDG_DATA_HOME`: Neovim 数据目录（默认：`~/.local/share`）
- `XDG_STATE_HOME`: Neovim 状态目录（默认：`~/.local/state`）
- `XDG_CACHE_HOME`: Neovim 缓存目录（默认：`~/.cache`）

### 自定义远程剪贴板行为

如果你需要禁用远程剪贴板功能：

在 `~/.config/nvim/lua/config/options.lua` 中添加：

```lua
vim.g.omarchy_remote_clipboard_osc52 = false
vim.g.omarchy_remote_clipboard_sync = false
```

## 数据存储位置

### 配置文件

- `~/.config/nvim/` - 用户配置（此仓库）

### 运行时数据

- `~/.local/share/nvim/` - 插件安装、Mason LSP 服务器
- `~/.local/state/nvim/` - 会话、shada、日志
- `~/.cache/nvim/` - 缓存文件

这些目录由 Neovim 自动管理，不包含在配置仓库中。

## 报告安全问题

如果你在配置中发现任何潜在的安全问题，请：

1. **不要**在公开 Issue 中披露
2. 通过私有渠道联系维护者

## 审计记录

- **审计日期**: 2026-10-24
- **审计范围**: 所有配置文件
- **审计结果**: 通过
- **风险等级**: 低风险

详细审计报告：[SECURITY_AUDIT.md](../SECURITY_AUDIT.md)

---

**最后更新**: 2026-10-24
