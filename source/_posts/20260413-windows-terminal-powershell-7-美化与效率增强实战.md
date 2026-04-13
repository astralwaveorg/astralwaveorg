---
topic: tools
title: Windows Terminal + PowerShell 7 美化与效率增强实战
date: 2026-04-13 19:39:43
categories:
  - 工具
tags:
  - CLI
  - PowerShell
  - Windows-Terminal
  - Oh-My-Posh
description: 从原生 PowerShell 到具备历史预测、自动补全、Git 实时监控的高颜值终端，完整配置过程与踩坑记录
---

# Windows Terminal + PowerShell 7 美化与效率增强实战

一直觉得 Windows 的终端体验差点意思。原生 PowerShell 功能不弱，但开箱即用的状态跟 macOS 上的 iTerm2 + Zsh 比起来，视觉上和效率上都差了一截。最近花了点时间把 Windows Terminal + PowerShell 7 重新捋了一遍，把常用的效率插件和美化方案都配上了，记录一下完整过程。

## 先说选型

终端模拟器没什么好纠结的，Windows Terminal 目前是 Windows 上最靠谱的选择——多标签、GPU 渲染、Unicode 支持都到位，微软自己维护的，没什么可挑的。

Shell 这块有两个选择：

| 方案 | 优势 | 劣势 |
|------|------|------|
| PowerShell 5.1（系统自带） | 零安装，开箱即用 | 版本老旧，很多新模块不兼容 |
| PowerShell 7（独立安装） | 跨平台，模块生态新，性能更好 | 需要额外安装，和系统自带的 5.1 共存 |

选 PowerShell 7 没什么犹豫，5.1 太老了，部分 PSGallery 上的模块直接装不上。两者共存互不影响，PowerShell 7 的可执行文件叫 `pwsh.exe`，不会覆盖系统的 `powershell.exe`。

## 第一步：装基础软件

三样东西，按顺序来：

```powershell
# PowerShell 7
winget install Microsoft.PowerShell

# Oh My Posh - 终端提示符美化引擎
winget install JanDeDobbeleer.OhMyPosh -s winget

# Nerd Fonts - 图标字体（这一步很关键，后面会解释为什么）
winget install JanDeDobbeleer.OhMyPosh.Fonts
```

Nerd Fonts 这一步容易被忽略。Oh My Posh 的主题里大量使用了特殊图标字符（Git 分支、文件类型、状态符号等），普通字体不支持这些字符，会显示成乱码方块。装完 Nerd Fonts 之后，还必须手动改 Windows Terminal 的字体设置：

**Windows Terminal → 左下角下拉箭头 → 设置 → PowerShell 配置文件 → 外观 → 字体 → 选 `JetBrainsMono Nerd Font Mono`**

不选这个字体，后面所有图标都会变成方块，别问我是怎么知道的。

## 第二步：配置 Oh My Posh 主题

Oh My Posh 默认从 GitHub 加载主题，国内网络环境下经常抽风，要么加载巨慢，要么直接报 `CONFIG NOT FOUND`。

我的做法是把主题文件存到本地，彻底绕开网络依赖。

```powershell
# 打开主题文件
notepad "$HOME\Documents\jandedobbeleer.omp.json"
```

把主题 JSON 内容粘贴进去保存。然后在 PowerShell 配置文件里引用这个本地路径，启动速度秒开，完全不依赖网络。

主题的选择看个人审美，我用的基于 `jandedobbeleer` 原版改了一下颜色。具体主题 JSON 内容这里不贴了，去 [Oh My Posh 官方仓库](https://github.com/JanDeDobbeleer/oh-my-posh) 找一个顺眼的，下载到本地就行。

## 第三步：装效率插件

三个模块，各有分工：

```powershell
# PSReadLine - PowerShell 的命令行编辑增强
# 提供：历史预测、语法高亮、多行编辑
Install-Module PSReadLine -Force

# Terminal-Icons - 文件和目录的彩色图标显示
# ls 命令直接能看到文件类型对应的图标
Install-Module Terminal-Icons -Repository PSGallery -Scope CurrentUser

# posh-git - Git 状态集成
# 命令行里实时显示当前分支、暂存状态、推送/拉取进度
Install-Module posh-git -Scope CurrentUser -Force
```

简单说一下每个模块解决什么问题：

- **PSReadLine**：PowerShell 7 自带一个版本，但 PSGallery 上的更新更频繁。主要功能是历史命令预测——输入几个字符，它会根据历史记录灰显补全建议，按右箭头直接采纳。这个体验用过 ZSH 的 `autosuggestions` 的人应该很熟悉。
- **Terminal-Icons**：纯视觉增强，`ls` 的时候不同文件类型显示不同图标。文件夹、代码文件、图片、配置文件一目了然，对于文件多的项目目录很实用。
- **posh-git**：跟 Oh My Posh 配合使用，在提示符里显示 Git 分支名和状态。不用 `git status` 就能知道有没有未提交的修改。

## 第四步：完整 $PROFILE 配置

这是整套系统的核心。打开 PowerShell，输入 `notepad $PROFILE`，把以下内容贴进去：

```powershell
# --- 1. 屏蔽 Oh My Posh 的 AI 提示功能 ---
# Oh My Posh 新版会注入 AI 命令建议，我不用这个功能，关掉避免干扰
$env:POSH_NO_AIPROMPT = $true

# --- 2. Oh My Posh 终端美化（本地加载） ---
# 指向本地主题文件，不依赖 GitHub
oh-my-posh init pwsh --config "$HOME\Documents\jandedobbeleer.omp.json" | Invoke-Expression

# --- 3. PSReadLine 效率配置 ---
# 开启历史预测：输入时会根据历史命令灰显建议
Set-PSReadLineOption -PredictionSource History
# 列表视图显示预测结果（比默认的内联显示更直观）
Set-PSReadLineOption -PredictionViewStyle ListView
# 预测文本颜色设为浅灰色，不要太抢眼
Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]0x1b)[38;5;244m" }
# Tab 键触发菜单式补全（而不是简单的单次补全）
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# --- 4. 加载模块 ---
Import-Module Terminal-Icons   # ls 彩色图标
Import-Module posh-git         # Git 状态增强

# --- 5. 快捷函数 ---
# 用函数而不是 Alias，因为 Alias 不支持参数透传

# Git 常用操作
function gs { git status $args }
function ga { git add . }
function gc { git commit -m $args }
function gp { git push $args }
function gl { git log --oneline --graph --all }
function gd { git diff $args }

# 彩色 Git 提交历史，比默认的 git log 好看很多
function glog {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}
```

几个关键点解释一下：

**为什么用函数不用 Alias？** PowerShell 的 Alias 不支持参数传递。`alias gs = git status` 这种写法看起来没问题，但一旦你想传额外参数（比如 `gs -s`）就会报错。用 `function gs { git status $args }` 就没有这个问题，`$args` 会把所有参数透传给 `git status`。

**PSReadLine 的 ListView 模式**：默认的 `InlineView` 是在当前行后面灰显建议，`ListView` 会在下方弹出一个小列表，类似 IDE 的代码补全。个人偏好 ListView，信息量更大，不容易跟当前输入混淆。

## Git 状态图标说明

配完之后，进入 Git 项目目录，提示符会实时显示状态。一开始可能看不太懂那些符号，这里列一下：

| 符号 | 含义 | 操作 |
|------|------|------|
| `main` | 当前分支名 | - |
| `↑` (向上箭头) | 本地有提交未推送到远程 | `gp` |
| `↓` (向下箭头) | 远程有新提交未拉取 | `git pull` |
| `≡` (等号) | 本地与远程完全同步 | 不需要操作 |
| `+` | 有新文件已暂存 | 检查是否需要提交 |
| `!` | 有文件已修改但未暂存 | `git add` 或 `git checkout` |

如果本地改乱了想重置到远程状态（慎用，会丢失本地所有未推送的修改）：

```powershell
git fetch origin
git reset --hard origin/main
```

## 实际用下来怎么样

配完这套之后，Windows 终端的使用体验提升是明显的：

1. **启动速度**：主题和字体全部本地化，打开即用，没有网络加载延迟。之前从 GitHub 拉主题，偶尔能卡 3-5 秒，现在基本是秒开。

2. **输入效率**：PSReadLine 的历史预测省了很多重复输入。常用的长命令（比如 `docker compose up -d --build`）输入前几个字符就能直接右箭头采纳。Tab 菜单补全也比单次 Tab 更高效，不用反复按 Tab 切换候选项。

3. **Git 感知**：posh-git + Oh My Posh 配合，在提示符里直接显示分支和状态。不用频繁 `git status` 就能知道当前工作区的状态，对于频繁切换分支的开发节奏来说很实用。

4. **视觉体验**：JetBrains Mono 本身就是很适合编程的字体，加上 Nerd Fonts 的图标补丁，终端看起来不再是纯文字的"黑框框"。Terminal-Icons 让文件列表有了辨识度，虽然不直接影响效率，但用起来舒服不少。

## 几个踩过的坑

1. **字体没改就怪 Oh My Posh**：装完 Oh My Posh 看到一堆方块，第一反应是主题坏了。其实是 Windows Terminal 的字体没换成 Nerd Font。这个坑太常见了，检查字体设置是第一步。

2. **$PROFILE 路径搞混**：PowerShell 5.1 和 PowerShell 7 的 `$PROFILE` 路径不一样。5.1 在 `Documents\WindowsPowerShell\`，7 在 `Documents\PowerShell\`。如果你两个都用，记得分别配置，或者直接只用 7。

3. **PSReadLine 版本冲突**：PowerShell 7 自带 PSReadLine，但版本可能不是最新的。用 `Install-Module PSReadLine -Force` 会装最新版并覆盖，一般没问题。但如果装完之后行为异常（比如预测不生效），检查一下版本：`Get-Module PSReadLine`。

4. **Oh My Posh 主题 JSON 格式**：从 GitHub 下载的主题文件有时候会有多余的逗号或格式问题，导致 JSON 解析失败。粘贴到本地文件后用 JSON 校验工具检查一下，能省不少排查时间。

## 适合谁

这套配置适合日常在 Windows 上做开发的人，尤其是：

- 经常用 Git 管理代码，需要频繁查看分支和状态
- 命令行操作多，希望减少重复输入
- 对终端颜值有要求，受不了纯黑白的默认界面

如果你主要用 WSL 或者直接 SSH 到远程服务器开发，这套配置对远程端没帮助（美化的是本地终端），但 PSReadLine 的历史预测和快捷函数在 SSH 场景下同样生效。

配置一次大概 15-20 分钟，之后就能一直用。值得折腾。
