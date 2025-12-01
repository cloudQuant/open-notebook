#!/bin/bash

# Open Notebook 本地停止脚本
# 使用方法: ./stop-local.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🛑 停止 Open Notebook 服务...${NC}"

# 停止前端
if pgrep -f "next dev" > /dev/null; then
    echo -e "${GREEN}停止前端...${NC}"
    pkill -f "next dev" || true
    echo -e "${GREEN}✅ 前端已停止${NC}"
else
    echo -e "${YELLOW}前端未运行${NC}"
fi

# 停止 Worker
if pgrep -f "surreal-commands-worker" > /dev/null; then
    echo -e "${GREEN}停止后台工作进程...${NC}"
    pkill -f "surreal-commands-worker" || true
    echo -e "${GREEN}✅ 后台工作进程已停止${NC}"
else
    echo -e "${YELLOW}后台工作进程未运行${NC}"
fi

# 停止 API
if pgrep -f "run_api.py\|uvicorn api.main:app" > /dev/null; then
    echo -e "${GREEN}停止 API 后端...${NC}"
    pkill -f "run_api.py" || true
    pkill -f "uvicorn api.main:app" || true
    echo -e "${GREEN}✅ API 后端已停止${NC}"
else
    echo -e "${YELLOW}API 后端未运行${NC}"
fi

# 停止 SurrealDB
if [ -f "surreal_data/surreal.pid" ]; then
    SURREAL_PID=$(cat surreal_data/surreal.pid)
    if ps -p $SURREAL_PID > /dev/null 2>&1; then
        echo -e "${GREEN}停止 SurrealDB (PID: $SURREAL_PID)...${NC}"
        kill $SURREAL_PID || true
        rm surreal_data/surreal.pid
        echo -e "${GREEN}✅ SurrealDB 已停止${NC}"
    else
        echo -e "${YELLOW}SurrealDB 未运行${NC}"
        rm surreal_data/surreal.pid
    fi
elif pgrep -f "surreal start" > /dev/null; then
    echo -e "${GREEN}停止 SurrealDB...${NC}"
    pkill -f "surreal start" || true
    echo -e "${GREEN}✅ SurrealDB 已停止${NC}"
else
    echo -e "${YELLOW}SurrealDB 未运行${NC}"
fi

# 清理 PID 文件
[ -f "api.pid" ] && rm api.pid
[ -f "worker.pid" ] && rm worker.pid

echo ""
echo -e "${GREEN}✅ 所有服务已停止！${NC}"

