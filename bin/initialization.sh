#!/bin/bash

# 定义颜色输出函数
print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_red() {
    echo -e "\033[0;31m$1\033[0m"
}

print_blue() {
    echo -e "\033[0;34m$1\033[0m"
}

print_yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

echo "当前脚本目录： $(pwd)"
cd /Users/athena/GitHubRepos/astralwaveio
echo "打开后目录： $(pwd)"

set -e # 遇到错误立即退出

# 1. 创建一个脱离历史的新分支
git checkout --orphan temp_main

# 2. 暂存所有当前目录下的文件（包括新建、修改、删除）
git add -A

# 3. 提交更改（可自定义提交信息）
git commit -am "Rebuild main branch"

# 4. 删除原 main 分支（本地）
git branch -D main

# 5. 将当前分支重命名为 main
git branch -m main

# 6. 强制推送到远程 main 分支，覆盖远程历史
git push -f origin main

echo "main 分支已重建并强制推送到远程。"
