# Open Notebook 本地运行快速指南

## 🚀 快速开始（3 步）

### 1. 安装依赖

```bash
# 安装 uv (Python 包管理器)
brew install uv  # macOS
# 或: curl -LsSf https://astral.sh/uv/install.sh | sh  # Linux

# 安装 SurrealDB (数据库)
brew install surrealdb/tap/surreal  # macOS
# 或: curl -sSf https://install.surrealdb.com | sh  # Linux

# 安装 Node.js 依赖
cd frontend && npm install && cd ..
```

### 2. 配置环境变量

创建 `.env` 文件：

```env
# 数据库配置（如果 8001 被占用，可改为其他端口）
SURREAL_URL=ws://localhost:8001/rpc
SURREAL_USER=root
SURREAL_PASSWORD=root
SURREAL_NAMESPACE=open_notebook
SURREAL_DATABASE=production

# AI 提供商（至少需要一个）
OPENAI_API_KEY=sk-your-key-here
```

### 3. 启动服务

```bash
# 一键启动所有服务
./start-local.sh

# 或手动启动（4 个终端窗口）：
# 终端1: surreal start --user root --pass root rocksdb:./surreal_data/mydatabase.db
# 终端2: uv run python run_api.py
# 终端3: uv run --env-file .env surreal-commands-worker --import-modules commands
# 终端4: cd frontend && PORT=8502 npm run dev
```

## 📍 访问地址

- **前端**: http://localhost:8502
- **API 文档**: http://localhost:5055/docs

## 🛑 停止服务

```bash
./stop-local.sh
```

## 📚 详细文档

查看 `LOCAL_SETUP.md` 获取完整指南。

## ⚠️ 常见问题

1. **端口被占用**: 修改 `.env` 中的端口配置
2. **SurrealDB 未安装**: 使用 `brew install surrealdb/tap/surreal` (macOS)
3. **Python 版本**: 需要 Python 3.11 或 3.12
4. **API Key 错误**: 确保至少配置一个有效的 AI 提供商 API Key

