#!/bin/bash
# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # 无色
# 函数：设置 Git 用户信息
set_git_user() {
    local email="jonny6015@icloud.com"
    local name="Astral Wave"
    
    if ! git config --global user.email > /dev/null; then
        git config --global user.email "$email"
        echo -e "${GREEN}已设置 Git 用户邮箱为 $email${NC}"
    else
        echo -e "${GREEN}Git 用户邮箱已设置${NC}"
    fi
    
    if ! git config --global user.name > /dev/null; then
        git config --global user.name "$name"
        echo -e "${GREEN}已设置 Git 用户名为 $name${NC}"
    else
        echo -e "${GREEN}Git 用户名已设置${NC}"
    fi
}
# 函数：提交更改
commit_changes() {
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${NC}没有更改需要提交${NC}"
    else
        git add .
        if git commit -m "在 $(date) 自动提交"; then
            echo -e "${GREEN}提交成功！${NC}"
        else
            echo -e "${RED}没有更改需要提交${NC}"
        fi
    fi
}
# 函数：处理合并冲突
handle_merge_conflicts() {
    echo -e "${RED}拉取远程更新失败，正在处理冲突...${NC}"
    if git status | grep -q "Unmerged paths"; then
        echo -e "${RED}检测到冲突，正在解决冲突...${NC}"
        git checkout --ours .
        git add .
        git commit -m "已解决合并冲突，保留本地更改"
    fi
}
# 主程序
set_git_user

# 提交未提交的更改
commit_changes

echo -e "${NC}正在拉取远程更新并检查冲突...${NC}"

# 拉取远程更新
if ! git pull origin main; then
    handle_merge_conflicts
    echo -e "${GREEN}已完成拉取远程更新${NC}"
fi

echo -e "${NC}正在准备推送到远程仓库...${NC}"
# 推送到远程
if git push origin main; then
    echo -e "${GREEN}推送成功！${NC}"
else
    echo -e "${RED}推送失败，请检查远程仓库设置${NC}"
fi