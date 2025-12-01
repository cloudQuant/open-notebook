#!/bin/bash

# 修复 API 连接问题的脚本

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 诊断 API 连接问题...${NC}"

# 1. 检查 SurrealDB 是否运行
echo -e "\n${YELLOW}1. 检查 SurrealDB...${NC}"
if ps aux | grep -E "surreal start" | grep -v grep > /dev/null; then
    echo -e "${GREEN}✅ SurrealDB 正在运行${NC}"
    SURREAL_PID=$(ps aux | grep -E "surreal start" | grep -v grep | awk '{print $2}' | head -1)
    echo "   PID: $SURREAL_PID"
else
    echo -e "${RED}❌ SurrealDB 未运行${NC}"
    echo "   正在启动 SurrealDB..."
    surreal start \
        --log info \
        --user root \
        --pass root \
        --bind 0.0.0.0:8001 \
        rocksdb:./surreal_data/mydatabase.db \
        > surreal_data/surreal.log 2>&1 &
    sleep 3
    echo -e "${GREEN}✅ SurrealDB 已启动${NC}"
fi

# 2. 检查端口
echo -e "\n${YELLOW}2. 检查端口...${NC}"
if lsof -Pi :8001 -sTCP:LISTEN -t >/dev/null; then
    echo -e "${GREEN}✅ SurrealDB 端口 8001 正在监听${NC}"
else
    echo -e "${RED}❌ SurrealDB 端口 8001 未监听${NC}"
    exit 1
fi

# 3. 检查 .env 配置
echo -e "\n${YELLOW}3. 检查环境配置...${NC}"
if [ -f .env ]; then
    if grep -q "SURREAL_URL" .env; then
        SURREAL_URL=$(grep "^SURREAL_URL=" .env | cut -d'=' -f2 | tr -d '"')
        echo -e "${GREEN}✅ SURREAL_URL: $SURREAL_URL${NC}"
    else
        echo -e "${RED}❌ .env 文件中未找到 SURREAL_URL${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ .env 文件不存在${NC}"
    exit 1
fi

# 4. 测试数据库连接
echo -e "\n${YELLOW}4. 测试数据库连接...${NC}"
if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SurrealDB HTTP 健康检查通过${NC}"
else
    echo -e "${YELLOW}⚠️  SurrealDB HTTP 健康检查失败（这可能是正常的，SurrealDB 主要使用 WebSocket）${NC}"
fi

# 5. 停止旧的 API 进程
echo -e "\n${YELLOW}5. 清理旧的 API 进程...${NC}"
if pgrep -f "run_api.py\|uvicorn api.main:app" > /dev/null; then
    echo "   停止旧的 API 进程..."
    pkill -f "run_api.py" || true
    pkill -f "uvicorn api.main:app" || true
    sleep 2
    echo -e "${GREEN}✅ 旧的 API 进程已停止${NC}"
else
    echo -e "${GREEN}✅ 没有运行中的 API 进程${NC}"
fi

# 6. 启动 API
echo -e "\n${YELLOW}6. 启动 API 后端...${NC}"
echo "   使用配置:"
echo "   - API_HOST: ${API_HOST:-127.0.0.1}"
echo "   - API_PORT: ${API_PORT:-5055}"
echo "   - SURREAL_URL: $SURREAL_URL"
echo ""
echo -e "${GREEN}正在启动 API...${NC}"

# 启动 API（前台运行以便查看错误）
cd /Users/yunjinqi/Documents/source_code/open-notebook
uv run python run_api.py

