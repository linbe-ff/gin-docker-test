#!/bin/bash

# 设置Git仓库配置
REPO_URL="https://github.com/linbe-ff/gin-docker-test.git"
BRANCH="master"
LOCAL_REPO="/app/repo"
CHECK_INTERVAL=10 # 检查间隔(秒)
APP_NAME="main" # 编译后的程序名称

# 克隆或更新仓库
if [ -d "$LOCAL_REPO" ]; then
    echo "仓库已存在，准备更新..."
    cd "$LOCAL_REPO"
    git remote update
else
    echo "首次运行，正在克隆仓库..."
    git clone "$REPO_URL" "$LOCAL_REPO"
    cd "$LOCAL_REPO"
fi

# 初始化变量存储当前运行的PID
CURRENT_PID=""
IS_FIRST="true"

while true; do
    # 获取本地和远程最新提交
    git remote update
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "origin/$BRANCH")
    echo "本地提交: $LOCAL"
    echo "远程提交: $REMOTE"
#
    if [ "$LOCAL" != "$REMOTE" ] || [ "$IS_FIRST" == "true" ]; then
        echo "检测到新提交，开始更新..."

        # 拉取最新代码
        git pull origin "$BRANCH"

        # 停止当前运行的程序（如果存在）
        echo "进程ID: $CURRENT_PID"
        if [ ! -z "$CURRENT_PID" ]; then
            echo "停止当前运行的程序 (PID: $CURRENT_PID)..."
            kill $CURRENT_PID
            CURRENT_PID=""
        fi

        # 构建Go程序
        echo "开始构建..."

        go mod tidy

        go build -o "$APP_NAME"

        # 检查构建是否成功
        if [ $? -ne 0 ]; then
            echo "构建失败，请检查代码。"
#            exit 1
        fi

        # 运行程序
        echo "启动程序..."
        ./"$APP_NAME" &

        # 获取进程ID
        CURRENT_PID=$!
        echo "程序已启动，PID: $CURRENT_PID"

        # 记录当前版本
        git rev-parse HEAD > .current_version
        IS_FIRST="false"
    else
        echo "没有检测到新提交，当前版本: $(cat .current_version 2>/dev/null || echo '未知')"
    fi

    # 等待下次检查
    sleep $CHECK_INTERVAL
done