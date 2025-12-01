#!/bin/bash

# Open Notebook 本地启动脚本（不使用 Docker）
# 使用方法: ./start-local.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 启动 Open Notebook (本地模式，不使用 Docker)${NC}"

# 检查是否在项目根目录
if [ ! -f "pyproject.toml" ]; then
    echo -e "${RED}❌ 错误: 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  警告: 未找到 .env 文件${NC}"
    echo "请先创建 .env 文件并配置必要的环境变量"
    echo "参考 LOCAL_SETUP.md 了解如何配置"
    exit 1
fi

# 检查 SurrealDB 是否已安装
if ! command -v surreal &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到 SurrealDB${NC}"
    echo "请先安装 SurrealDB:"
    echo "  macOS: brew install surrealdb/tap/surreal"
    echo "  Linux: curl -sSf https://install.surrealdb.com | sh"
    exit 1
fi

# 检查 uv 是否已安装
if ! command -v uv &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到 uv${NC}"
    echo "请先安装 uv:"
    echo "  macOS: brew install uv"
    echo "  Linux: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# 检查 Node.js 是否已安装
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到 Node.js${NC}"
    echo "请先安装 Node.js 18+"
    exit 1
fi

# 创建必要的目录
echo -e "${GREEN}📁 创建数据目录...${NC}"
mkdir -p data/sqlite-db
mkdir -p data/uploads
mkdir -p data/tiktoken-cache
mkdir -p surreal_data

# 从 .env 读取 SurrealDB 端口，默认为 8001
SURREAL_PORT="8001"
if [ -f ".env" ]; then
    # 如果 SURREAL_URL 中指定了端口，提取出来
    if grep -q "SURREAL_URL" .env; then
        SURREAL_URL_LINE=$(grep -E "^SURREAL_URL=" .env | head -1)
        if [[ $SURREAL_URL_LINE =~ :([0-9]+) ]]; then
            SURREAL_PORT="${BASH_REMATCH[1]}"
        fi
    # 或者使用 SURREAL_PORT 环境变量（旧格式）
    elif grep -q "SURREAL_PORT" .env; then
        SURREAL_PORT=$(grep -E "^SURREAL_PORT=" .env | cut -d'=' -f2 | tr -d '"' | head -1)
    fi
fi

# 检查 SurrealDB 是否已在运行
if lsof -Pi :${SURREAL_PORT} -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}⚠️  SurrealDB 已在运行 (端口 ${SURREAL_PORT})${NC}"
else
    echo -e "${GREEN}📊 启动 SurrealDB (端口 ${SURREAL_PORT})...${NC}"
    # 在后台启动 SurrealDB
    surreal start \
        --log info \
        --user root \
        --pass root \
        --bind 0.0.0.0:${SURREAL_PORT} \
        rocksdb:./surreal_data/mydatabase.db \
        > surreal_data/surreal.log 2>&1 &
    
    SURREAL_PID=$!
    echo $SURREAL_PID > surreal_data/surreal.pid
    echo -e "${GREEN}✅ SurrealDB 已启动 (PID: $SURREAL_PID)${NC}"
    
    # 等待 SurrealDB 启动
    echo "等待 SurrealDB 就绪..."
    sleep 3
fi

# 检查 API 是否已在运行
if lsof -Pi :5055 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}⚠️  API 后端已在运行 (端口 5055)${NC}"
else
    echo -e "${GREEN}🔧 启动 API 后端...${NC}"
    # 设置 NO_PROXY 以避免 WebSocket 连接问题
    export NO_PROXY="localhost,127.0.0.1,0.0.0.0,::1"
    # 在后台启动 API
    NO_PROXY="localhost,127.0.0.1,0.0.0.0,::1" uv run python run_api.py > api.log 2>&1 &
    API_PID=$!
    echo $API_PID > api.pid
    echo -e "${GREEN}✅ API 后端已启动 (PID: $API_PID)${NC}"
    
    # 等待 API 启动
    echo "等待 API 就绪..."
    sleep 5
    
    # 验证 API 是否成功启动
    if lsof -Pi :5055 -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${GREEN}✅ API 已成功启动并监听端口 5055${NC}"
    else
        echo -e "${RED}❌ API 启动失败，请查看 api.log${NC}"
        tail -20 api.log
    fi
fi

# 检查 Worker 是否已在运行
if pgrep -f "surreal-commands-worker" > /dev/null; then
    echo -e "${YELLOW}⚠️  后台工作进程已在运行${NC}"
else
    echo -e "${GREEN}⚙️  启动后台工作进程...${NC}"
    # 在后台启动 Worker
    uv run --env-file .env surreal-commands-worker --import-modules commands > worker.log 2>&1 &
    WORKER_PID=$!
    echo $WORKER_PID > worker.pid
    echo -e "${GREEN}✅ 后台工作进程已启动 (PID: $WORKER_PID)${NC}"
    
    sleep 2
fi

# 检查前端是否已在运行（检查端口 8502）
if lsof -Pi :8502 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}⚠️  前端已在运行 (端口 8502)${NC}"
    echo -e "${GREEN}✅ 所有服务已在运行！${NC}"
    echo ""
    echo -e "📱 前端界面: ${GREEN}http://localhost:8502${NC}"
    echo -e "🔗 API 文档: ${GREEN}http://localhost:5055/docs${NC}"
else
    echo -e "${GREEN}🌐 启动前端...${NC}"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ 所有服务已启动！${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "📱 前端界面: ${GREEN}http://localhost:8502${NC}"
    echo -e "🔗 API 文档: ${GREEN}http://localhost:5055/docs${NC}"
    echo -e "💚 API 健康检查: ${GREEN}http://localhost:5055/health${NC}"
    echo ""
    echo -e "${YELLOW}提示: 按 Ctrl+C 停止前端（其他服务会继续运行）${NC}"
    echo -e "${YELLOW}使用 ./stop-local.sh 停止所有服务${NC}"
    echo ""
    
    # 启动前端（前台运行，这样可以看到日志，使用 8502 端口）
    cd frontend && PORT=8502 npm run dev
fi

