# LazyVim Codespaces

一个适配 GitHub Codespaces 的 LazyVim 配置，从生产环境迁移而来，开箱即用。

## ✨ 特性

- 🚀 **一键安装**：自动安装 Neovim 0.10.2 和所有插件
- 🔒 **隐私安全**：经过严格审计，排除所有敏感信息
- 🎨 **20+ 主题**：预装多个精美主题，支持热切换
- 💻 **全栈开发**：支持 Go, Rust, Python, SQL, Docker, Terraform, YAML 等
- 🔧 **生产级配置**：来自真实使用环境，经过实战检验
- 🌐 **远程剪贴板**：自动检测 SSH/tmux 环境，支持 OSC 52
- 📦 **66 个插件**：包含补全、LSP、语法高亮、文件树、搜索等

## 🚀 快速开始

### 在 GitHub Codespaces 中使用

**一键安装（推荐）：**

```bash
curl -fsSL https://raw.githubusercontent.com/YuvbMowh/neovimsh/master/install.sh | bash
```

**或者克隆后安装：**

```bash
git clone https://github.com/YuvbMowh/neovimsh.git
cd neovimsh
./install.sh
```

安装完成后启动：

```bash
nvim
```

### 选项

- `--force`: 强制安装，跳过所有确认提示
- `--help`: 显示帮助信息

```bash
./install.sh --force
```

## 📖 使用指南

### 基本快捷键

LazyVim 使用 `<Space>` 作为 Leader 键。

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `<Space>` | Which-Key | 显示所有可用快捷键 |
| `<Space>e` | 文件树 | 打开 neo-tree |
| `<Space>ff` | 查找文件 | 模糊搜索文件名 |
| `<Space>sg` | 全局搜索 | 在项目中搜索文本（ripgrep） |
| `<Space>bb` | 切换缓冲区 | 快速切换打开的文件 |
| `<Space>l` | Lazy | 打开插件管理器 |
| `gcc` | 注释/取消注释 | 单行注释 |
| `gc` | 注释/取消注释 | 可视模式下批量注释 |
| `<C-/>` | 终端 | 打开/关闭终端 |

更多快捷键请在 Neovim 中按 `<Space>` 查看。

### 更改主题

编辑 `~/.config/nvim/lua/plugins/theme.lua`：

```lua
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",  -- 更改为你喜欢的主题
    },
  },
}
```

**可用主题：**

- `tokyonight` (默认)
- `catppuccin`
- `gruvbox`
- `kanagawa`
- `rose-pine`
- `aether`
- `everforest`
- `nightfox`
- 以及更多...

查看所有主题：`:Telescope colorscheme`

### LSP 支持

配置已启用以下语言支持（LSP 服务器由 Mason 自动管理）：

- **Go**: gopls
- **Rust**: rust-analyzer
- **Python**: pyright
- **JSON**: jsonls + SchemaStore
- **YAML**: yamlls
- **Docker**: dockerls, docker-compose-language-service
- **Terraform**: terraformls
- **SQL**: sqlls
- **Git**: gitlint

首次打开相应语言文件时，Mason 会自动安装 LSP 服务器。

### 插件管理

查看和管理插件：

```vim
:Lazy
```

- `I` - 安装缺失的插件
- `U` - 更新插件
- `X` - 清理未使用的插件
- `S` - 同步（安装、更新、清理）

## 📦 包含的插件分类

### 核心

- **LazyVim**: 预配置的 Neovim 发行版
- **lazy.nvim**: 现代化插件管理器
- **which-key**: 快捷键提示

### 编辑增强

- **blink.cmp**: 快速补全引擎
- **mini.surround**: 快速添加/修改/删除包围符号
- **mini.pairs**: 自动配对括号
- **flash.nvim**: 快速跳转
- **yanky.nvim**: 增强的复制粘贴
- **harpoon**: 文件标记和快速切换
- **inc-rename**: LSP 重命名预览
- **dial.nvim**: 增强的增减操作

### 文件导航

- **neo-tree**: 文件树浏览器
- **aerial**: 代码大纲
- **grug-far**: 搜索和替换

### LSP & 补全

- **nvim-lspconfig**: LSP 配置
- **mason**: LSP/DAP/Linter 安装器
- **lazydev**: Lua 开发增强
- **blink.cmp**: 补全引擎
- **friendly-snippets**: 代码片段集合

### 语法高亮

- **nvim-treesitter**: 语法解析器
- **nvim-treesitter-textobjects**: 文本对象
- **nvim-treesitter-context**: 上下文显示
- **nvim-ts-autotag**: HTML/JSX 自动闭合标签
- **ts-comments**: 智能注释

### UI 增强

- **snacks.nvim**: UI 组件库
- **noice.nvim**: 增强的 UI 界面
- **bufferline**: 标签页
- **lualine**: 状态栏
- **mini.icons**: 图标支持
- **透明背景**: 终端透明度支持

### Git

- **gitsigns**: Git 集成
- **mini.diff**: Git diff 显示

### 数据库

- **vim-dadbod**: 数据库客户端
- **vim-dadbod-ui**: 数据库 UI
- **vim-dadbod-completion**: 数据库补全
- **SQL 关键字补全**: 自定义 SQL 补全

### 主题

预装 20+ 精美主题，包括：
- tokyonight, catppuccin, gruvbox, kanagawa, rose-pine
- aether, everforest, nightfox, bamboo, monokai-pro
- 以及更多...

### 实用工具

- **trouble**: 诊断列表
- **todo-comments**: TODO 注释高亮
- **persistence**: 会话管理
- **conform**: 代码格式化
- **nvim-lint**: 代码检查

### 语言特定

- **rustaceanvim**: Rust 增强支持
- **venv-selector**: Python 虚拟环境选择器
- **crates.nvim**: Rust crates 管理

## 🔧 配置说明

### 目录结构

```
~/.config/nvim/
├── init.lua                    # 入口文件
├── lazy-lock.json              # 插件版本锁定
├── lazyvim.json                # LazyVim extras 配置
├── stylua.toml                 # Lua 格式化配置
├── .neoconf.json               # Neoconf 配置
├── lua/
│   ├── config/                 # 核心配置
│   │   ├── lazy.lua            # lazy.nvim 配置
│   │   ├── options.lua         # Vim 选项
│   │   ├── keymaps.lua         # 快捷键映射
│   │   ├── autocmds.lua        # 自动命令
│   │   ├── remote_clipboard.lua # 远程剪贴板（SSH/tmux）
│   │   └── lsp_log.lua         # LSP 日志管理
│   ├── plugins/                # 插件配置
│   │   ├── theme.lua           # 主题配置
│   │   ├── all-themes.lua      # 所有主题加载
│   │   ├── sql-completion.lua  # SQL 补全
│   │   ├── docker-compose-filetype.lua # Docker Compose 文件类型
│   │   └── ...
│   └── sql-keywords.lua        # SQL 关键字补全模块
└── plugin/
    └── after/
        └── transparency.lua    # 透明背景
```

### 自定义配置

所有自定义配置都在 `~/.config/nvim/lua/` 目录下：

- **修改选项**: 编辑 `lua/config/options.lua`
- **添加快捷键**: 编辑 `lua/config/keymaps.lua`
- **添加自动命令**: 编辑 `lua/config/autocmds.lua`
- **添加/修改插件**: 在 `lua/plugins/` 目录下创建新文件

### 更新配置

```bash
# 拉取最新配置
cd neovimsh
git pull

# 强制覆盖安装
./install.sh --force
```

### 卸载

**一键卸载：**

```bash
curl -fsSL https://raw.githubusercontent.com/YuvbMowh/neovimsh/master/uninstall.sh | bash
```

**或者手动卸载：**

```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
rm ~/.local/bin/nvim
```

备份文件保留在 `~/.config/nvim.backup.*`

## 🌍 环境特定功能

### 远程剪贴板 (SSH/tmux)

配置会自动检测以下环境并启用远程剪贴板支持：

- SSH 连接
- tmux 会话
- herdr 终端

通过 OSC 52 和 Wayland clipboard，让远程 Neovim 的复制粘贴与本地无缝集成。

### VSCode Neovim 集成

配置包含 VSCode 快捷键映射，在 VSCode Neovim 扩展中也能良好工作。

### 输入法支持

在 VSCode 中自动检测并支持 fcitx5 输入法的智能切换（插入模式恢复中文）。

## 📝 与本地配置的差异

此配置从 Omarchy Linux 迁移而来，进行了以下调整：

### 已排除

- ❌ **LeetCode 插件**: 包含账号认证信息
- ❌ **Omarchy 主题符号链接**: 替换为 tokyonight 默认主题

### 环境依赖

以下功能在 Codespaces 中可能不完全工作，但不会导致错误：

- **remote_clipboard.lua**: Omarchy/tmux 专用剪贴板功能
  - 会自动检测环境，在 Codespaces 中自动禁用
- **omarchy-theme-hotreload.lua**: Omarchy 系统主题热重载
  - 在非 Omarchy 环境下不会生效
- **fcitx5 输入法**: 中文输入法自动切换
  - 仅在安装了 fcitx5 的环境中启用

这些配置都包含环境检测逻辑，在不支持的环境中会自动禁用，不影响正常使用。

## 🔍 故障排查

### Neovim 启动缓慢

首次启动需要安装插件，请等待几分钟。后续启动会很快。

### LSP 服务器未启动

1. 检查 Mason 是否安装了对应的 LSP 服务器：`:Mason`
2. 手动安装：在 `:Mason` 界面中按 `i` 安装
3. 查看 LSP 日志：`:LspLog`

### 插件安装失败

```vim
:Lazy sync
```

如果还是失败，检查网络连接和 GitHub 访问。

### 主题不生效

1. 确认主题插件已安装：`:Lazy`
2. 尝试手动加载：`:colorscheme tokyonight`
3. 重启 Neovim

### 剪贴板不工作

在 Codespaces 中，使用浏览器的复制粘贴或终端右键菜单。

## 📚 更多资源

- [LazyVim 官方文档](https://www.lazyvim.org/)
- [Neovim 文档](https://neovim.io/doc/)
- [lazy.nvim 文档](https://github.com/folke/lazy.nvim)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## ⚠️ 免责声明

此配置已经过安全审计，但仍建议：

1. 审查代码后再使用
2. 不要在配置中添加敏感信息
3. 定期更新插件和 Neovim

---

**享受你的 LazyVim 之旅！** 🚀
