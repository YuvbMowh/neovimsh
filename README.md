# LazyVim Codespaces

适用于 Ubuntu/Debian 和 GitHub Codespaces 的个人 LazyVim 配置，支持 x86_64、ARM64。包含 Go、Rust、Python、SQL、Docker、Terraform、JSON、YAML 等语言 extras，以及 VS Code Neovim 映射、SSH/tmux 剪贴板和多个可选主题。

## 安装

推荐克隆后安装，以便检查脚本和更新配置：

```bash
git clone https://github.com/YuvbMowh/neovimsh.git
cd neovimsh
./install.sh
```

自动部署到 Codespaces：

```bash
./install.sh --force
```

已有开发依赖、不希望运行 apt 时：

```bash
./install.sh --force --skip-tools
```

也可以先下载脚本再执行。脚本会从 `master` 克隆配置：

```bash
curl -fSL https://raw.githubusercontent.com/YuvbMowh/neovimsh/master/install.sh -o /tmp/lazyvim-install.sh
bash /tmp/lazyvim-install.sh --force
```

请勿使用 `sudo ./install.sh`；安装目录属于当前用户，只有 apt 步骤需要 sudo。

### 安装行为

- 复用 PATH 中已有的稳定版 Neovim >= 0.11.2；否则默认下载 **0.11.7**。`NVIM_VERSION` 可指定其他符合要求的稳定版。
- 下载时通过 GitHub Release API 获取 SHA-256 digest，校验后保留官方完整目录布局，安装至 `~/.local/opt/nvim-codespaces/<版本>-<架构>`，链接至 `~/.local/bin/nvim`。未受管理的同名文件不会被覆盖。
- 安装基础工具和 `ripgrep`、`fd-find`、`build-essential`、`unzip`。支持 root 容器直接运行 apt，也支持普通用户通过 sudo 安装。
- 先准备完整配置，再备份、替换现有配置；备份位于配置目录旁的 `nvim.backup.*`。每次替换使用独立备份名。
- `--force` 自动确认配置替换，**仍然保留备份**。不带该选项的非交互替换会失败，避免部署卡在输入提示上。
- 插件按 `lazy-lock.json` 安装和恢复，不执行 `Lazy sync` 升级。插件任务错误或启动错误会使脚本以非零状态退出。
- 部署失败或收到 INT/TERM 时撤回新配置并恢复旧配置。已安装的软件包、Neovim 发行包、插件及 Mason 数据不会自动回滚；SIGKILL、断电也无法执行回滚。
- 不修改 `.bashrc` 或其他 shell 配置。终端找不到 `nvim` 时，在你使用的 shell 配置中添加：

```bash
export PATH="$HOME/.local/bin:$PATH"
# 可选快捷别名
alias n='nvim'
```

`--skip-tools` 跳过 apt；`curl`、`tar`、`git`、`python3`、`sha256sum` 仍须提前存在。下载需要访问 GitHub API 和 Releases；插件还需要访问各自的仓库。

支持 `XDG_CONFIG_HOME`、`XDG_DATA_HOME`、`XDG_STATE_HOME`、`XDG_CACHE_HOME`，这些变量必须是绝对路径。暂不支持自定义 `NVIM_APPNAME`。单独下载脚本时可通过 `REPO_URL`、`REPO_REF` 指定配置仓库及分支或 tag；本地存在 `nvim/` 时优先使用本地配置。

## 使用与依赖

```bash
nvim
```

| 快捷键 | 功能 |
| --- | --- |
| `<Space>e` | 文件树 |
| `<Space>ff` | 查找文件 |
| `<Space>sg` | 项目搜索 |
| `<Space>l` | Lazy 插件管理 |
| `gcc` | 注释当前行 |
| `<Space>cf` | 格式化 |

按 `<Space>` 后等待快捷键提示。VS Code Neovim 中的映射会调用 VS Code 对应功能。

**自动保存格式化默认关闭**，相对行号默认关闭，可在 `lua/config/options.lua` 中修改。关闭 LSP 进度提示不影响诊断；LSP 日志级别为 warn，超过 5 MiB 时轮转，保留一份历史日志。

语言 extras 不等于安装了全部工具链。请按项目提供 Node.js/npm、Python/pip/venv、Go、Rust/Cargo 等环境，并通过 `:Mason` 检查语言服务器安装结果。Rust 使用 rustaceanvim 集成。SQL 数据库连接信息应在环境或个人配置中提供，不要提交到仓库。

Treesitter 还需要兼容的 `tree-sitter` CLI 和 C 编译器；本脚本安装 C 编译工具，但不自动选择 CLI、Node.js 或其他语言工具链的版本。终端图标建议使用 Nerd Font；Codespaces 中字体由本地终端决定。

### 主题

默认使用 `tokyonight`。编辑配置目录的 `lua/plugins/theme.lua` 中 `colorscheme`，例如改为 `catppuccin`、`gruvbox`、`kanagawa` 或 `rose-pine`，然后重启 Neovim。

主题插件在 `lua/plugins/all-themes.lua` 中延迟加载，可删除不使用的主题条目来减少下载。透明背景在 `after/plugin/transparency.lua` 中设置，切换配色后会重新应用；删除该文件即可恢复主题背景。不再依赖 Omarchy 的主题热重载。

### 剪贴板和 VS Code

SSH/tmux/herdr 环境会启用远程剪贴板 provider，复制可通过 OSC 52 传到支持它的终端。粘贴优先使用可用的 tmux/Wayland 数据，否则只能返回本次 Neovim 已复制的内容，不能保证直接读取浏览器或本地系统剪贴板。Codespaces 浏览器终端可使用浏览器提供的粘贴操作。

如需禁用远程剪贴板，在 `lua/config/options.lua` 的 `setup()` 调用**之前**设置：

```lua
vim.g.omarchy_remote_clipboard_osc52 = false
vim.g.omarchy_remote_clipboard_sync = false
```

VS Code Neovim 环境包含编辑器功能映射；仅在检测到 `fcitx5-remote` 时切换输入法。

## 更新和恢复

更新仓库配置并重新部署：

```bash
cd neovimsh
git pull --ff-only
./install.sh --force
```

重新部署会替换配置目录中的个人修改，先将需要的修改保存到自己的仓库或其他位置。插件锁文件用于恢复已有版本；主动升级插件请运行 `:Lazy update`，验证后再将新的锁文件纳入版本管理。

手动恢复配置：

```bash
# 替换为安装日志显示的实际路径；先移走当前配置
mv ~/.config/nvim ~/.config/nvim.before-restore
mv ~/.config/nvim.backup.实际后缀 ~/.config/nvim
```

使用 XDG 自定义目录时相应替换路径。若插件数据已经改变，恢复配置后还需运行 `:Lazy restore` 恢复插件版本。

## 卸载与清理

```bash
./uninstall.sh
# 自动确认
./uninstall.sh --force
# 同时删除全部 Neovim 插件、Mason、状态和缓存
./uninstall.sh --force --purge
```

默认仅删除带本安装器管理标记的配置，以及当前 `~/.local/bin/nvim` 链接指向且有管理标记的 Neovim 发行目录。已有系统 Neovim、非本安装器管理的二进制、备份和部署日志均保留。

`--purge` 清理当前 XDG 路径下的**全部** Neovim 数据，可能包含你以前安装的内容；仅在确定不再需要时使用。旧脚本安装的配置没有管理标记，卸载器会拒绝自动删除；请检查后手动处理，或先用新安装器部署。旧脚本遗留的 runtime、库及 shell 修改也不会自动清理。

## 检查与故障排查

部署日志保留在 `${XDG_STATE_HOME:-$HOME/.local/state}/lazyvim-codespaces/`：

- `plugins.log`：插件安装和恢复输出。
- `startup.log`：启动检查输出。

启动检查只验证配置能否正常加载，不能代替完整健康检查。安装后运行 `:checkhealth`，使用 `:Mason` 检查语言工具、`:LspLog` 查看 LSP 日志。GitHub API 无法访问、下载校验失败或插件任务失败时，应先解决日志中的错误再重新部署。

运行离线回归测试（不会执行 apt、联网或改动真实用户配置）：

```bash
python3 -m unittest discover -s tests -v
bash -n install.sh
bash -n uninstall.sh
```

测试覆盖首次安装、XDG 备份、PATH 中已有 Neovim、失败退出及配置回滚、非交互覆盖、卸载保护和显式数据清理。测试不代替在目标架构上的完整联网安装验证。

## 安全说明

仓库不应包含密码、Cookie 或数据库凭据。插件、语言服务器及构建脚本均会在当前用户权限下运行；版本锁定和发行文件校验不能代替对代码来源的信任。安全边界和数据删除范围见 [SECURITY.md](SECURITY.md)。
