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

用了一段时间 macOS 的 iTerm2 + Zsh 之后，切回 Windows 总觉得终端差点意思。不是功能不够，是开箱体验太素了——纯黑背景白字，没有任何视觉反馈，Git 状态得手动敲命令才能看到。

最近重新把 Windows Terminal + PowerShell 7 捋了一遍，把效率插件和美化都配上了。记录一下过程，也给同样在 Windows 上做开发的同学一个参考。

## 选型没什么好纠结的

终端模拟器直接用 Windows Terminal，多标签、GPU 渲染、Unicode 支持都有，微软自己维护的，没什么可挑的。

Shell 选 PowerShell 7，不选系统自带的 5.1。原因很简单：5.1 太老，PSGallery 上不少新模块装不上。两者共存互不影响——PowerShell 7 的可执行文件叫 `pwsh.exe`，不会覆盖系统的 `powershell.exe`。

## 装基础软件

三样东西：

```powershell
winget install Microsoft.PowerShell
winget install JanDeDobbeleer.OhMyPosh -s winget
winget install JanDeDobbeleer.OhMyPosh.Fonts
```

第三行 Nerd Fonts 很容易被忽略，但它是整套美化的前提。Oh My Posh 主题里用了大量特殊图标字符（Git 分支、文件类型、状态符号），普通字体不支持，全显示成方块。

装完字体还有一步：**Windows Terminal → 设置 → PowerShell 配置文件 → 外观 → 字体 → 改成 `JetBrainsMono Nerd Font Mono`**。

不改这个，后面所有图标都是方块。别问我是怎么知道的。

## 配置 Oh My Posh 主题

Oh My Posh 默认从 GitHub 拉主题文件。国内网络你懂的，经常要么巨慢要么直接 `CONFIG NOT FOUND`。

我的做法是把主题文件存本地，彻底不依赖网络：

```powershell
notepad "$HOME\Documents\jandedobbeleer.omp.json"
```

把主题 JSON 粘进去保存，然后在 `$PROFILE` 里引用这个本地路径。启动秒开，再也不会因为网络问题卡住。

主题本身看个人审美，去 [Oh My Posh 官方仓库](https://github.com/JanDeDobbeleer/oh-my-posh) 找一个顺眼的下载到本地就行。

## 装效率插件

三个模块：

```powershell
Install-Module PSReadLine -Force
Install-Module Terminal-Icons -Repository PSGallery -Scope CurrentUser
Install-Module posh-git -Scope CurrentUser -Force
```

分别说一下干嘛的：

**PSReadLine**——命令行编辑增强。核心功能是历史预测：输入几个字符，它会根据历史命令灰显建议，右箭头直接采纳。用过 ZSH `autosuggestions` 的话应该很熟悉这个感觉。PowerShell 7 自带一个版本，但 PSGallery 上的更新更快，建议装最新的。

**Terminal-Icons**——`ls` 的时候给不同文件类型显示不同图标。文件夹、代码文件、图片、配置文件一眼就能区分。纯视觉增强，不影响功能，但文件多了确实好用。

**posh-git**——在提示符里显示 Git 分支名和工作区状态。不用 `git status` 就能知道有没有未提交的修改，跟 Oh My Posh 配合效果不错。

## $PROFILE 完整配置

打开 PowerShell 输入 `notepad $PROFILE`，把以下内容贴进去：

```powershell
# 屏蔽 Oh My Posh 的 AI 命令建议，避免干扰正常输入
$env:POSH_NO_AIPROMPT = $true

# Oh My Posh 加载本地主题，不依赖网络
oh-my-posh init pwsh --config "$HOME\Documents\jandedobbeleer.omp.json" | Invoke-Expression

# 历史预测：输入时灰显建议，右箭头采纳
Set-PSReadLineOption -PredictionSource History
# 列表视图，比默认内联显示更清晰
Set-PSReadLineOption -PredictionViewStyle ListView
# 预测文本浅灰色，不抢眼
Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]0x1b)[38;5;244m" }
# Tab 菜单式补全
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

Import-Module Terminal-Icons
Import-Module posh-git

# 用函数不用 Alias——Alias 不支持参数透传
function gs { git status $args }
function ga { git add . }
function gc { git commit -m $args }
function gp { git push $args }
function gl { git log --oneline --graph --all }
function gd { git diff $args }

function glog {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}
```

有两个点值得说一下：

**函数 vs Alias**：PowerShell 的 Alias 不支持参数传递。写 `set-alias gs git status` 看着没问题，但你想 `gs -s` 传个参数过去就直接报错。用 `function` 就没这个限制，`$args` 会把所有参数透传。

**ListView vs InlineView**：PSReadLine 默认用内联模式（在当前行后面灰显建议），我改成了列表模式——下方弹出一个小列表，类似 IDE 的代码补全。信息量更大，不会跟当前输入混淆。

## Git 状态图标

配完之后进 Git 项目目录，提示符会实时显示状态。刚开始可能看不懂那些符号：

| 符号 | 含义 | 操作 |
|------|------|------|
| `main` | 当前分支 | - |
| `↑` | 本地有提交未推送 | `gp` |
| `↓` | 远程有新提交未拉取 | `git pull` |
| `≡` | 本地和远程同步 | 不用管 |
| `+` | 有新文件已暂存 | 该提交就提交 |
| `!` | 有文件已修改未暂存 | `ga` 或 `git checkout` |

本地改乱了想重置到远程（⚠️ 会丢本地未推送的修改）：

```powershell
git fetch origin
git reset --hard origin/main
```

## 最后两个小设置

这两个不影响功能，但用了之后体验好很多。

**去掉启动 Banner**：每次打开 PowerShell 都会显示一行版权信息，没什么用还占位置。打开终端设置 → PowerShell 配置文件 → 命令行，在路径后面加个 `-nologo`：

```
"%ProgramFiles%\PowerShell\7\pwsh.exe" -nologo
```

**锁定英文输入法**：打命令的时候输入法突然跳成中文，这个体验懂的都懂。终端设置 → 启动 → 默认输入法模式改成 `英文`，改完重启终端生效。

---

## 踩过的坑

1. **字体方块问题**：前面说了，这是最常见的坑。看到方块第一反应别去查 Oh My Posh，先查字体设置。

2. **$PROFILE 路径搞混**：PowerShell 5.1 和 7 的配置文件路径不一样。5.1 在 `Documents\WindowsPowerShell\`，7 在 `Documents\PowerShell\`。如果两个都在用，记得分别配，或者干脆只用 7。

3. **PSReadLine 行为异常**：装完新版 PSReadLine 之后预测不生效，大概率是版本问题。`Get-Module PSReadLine` 看一下版本号，必要时卸了重装。

4. **主题 JSON 格式错误**：从 GitHub 下载的主题偶尔会带多余逗号导致解析失败。粘贴到本地文件后过一遍 JSON 校验，能省排查时间。

## 总结

配一次大概 15 分钟，之后就一直能用。主题和字体本地化之后没有网络加载延迟，PSReadLine 的历史预测减少了大量重复输入，posh-git 让 Git 状态一目了然。如果你日常在 Windows 上写代码，这套配置值得花点时间搞一下。

主要用 WSL 或 SSH 到远程开发的，美化效果对远程端不生效，但 PSReadLine 和快捷函数照样能用。
