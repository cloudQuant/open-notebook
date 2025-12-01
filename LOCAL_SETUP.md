# Open Notebook 本地运行指南（不使用 Docker）

本指南将帮助你在本地环境运行 Open Notebook，无需使用 Docker。

## 📋 项目架构

Open Notebook 由以下服务组成：

1. **SurrealDB 数据库** - 端口 8001（默认，可自定义）
   - 存储 notebooks、sources、notes 等数据
   - 如果 8001 端口也被占用，可以在 `.env` 中配置 `SURREAL_PORT` 使用其他端口
   
2. **FastAPI 后端** - 端口 5055
   - REST API 服务
   - 处理所有业务逻辑
   
3. **后台工作进程** (Worker)
   - 处理异步任务（播客生成、内容转换等）
   
4. **Next.js 前端** - 端口 8502
   - Web 用户界面

## 🛠️ 系统要求

### 必需软件

- **Python 3.11 或 3.12** (不支持 3.13+)
- **Node.js 18+** 和 npm
- **uv** (Python 包管理器)
- **SurrealDB** (本地安装，不使用 Docker)

### 硬件要求

- **CPU**: 2+ 核心（推荐 4+）
- **内存**: 最低 4GB（推荐 8GB+）
- **存储**: 10GB+ 可用空间

## 📥 安装步骤

### 步骤 1: 安装 uv (Python 包管理器)

#### macOS
```bash
brew install uv
```

#### Linux
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc  # 或 ~/.zshrc
```

#### Windows
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### 步骤 2: 安装 SurrealDB (本地)

#### macOS
```bash
# 使用 Homebrew
brew install surrealdb/tap/surreal

# 或者使用安装脚本
curl -sSf https://install.surrealdb.com | sh
```

#### Linux
```bash
curl -sSf https://install.surrealdb.com | sh
```

#### Windows
```powershell
# 使用 Scoop
scoop install surrealdb

# 或从官网下载二进制文件
# https://github.com/surrealdb/surrealdb/releases
```

验证安装：
```bash
surreal version
```

### 步骤 3: 克隆项目并安装依赖

```bash
# 如果还没有克隆，先克隆项目
cd /Users/yunjinqi/Documents/source_code/open-notebook

# 安装 Python 依赖
uv sync

# 安装前端依赖
cd frontend
npm install
cd ..
```

### 步骤 4: 配置环境变量

在项目根目录创建 `.env` 文件：

```bash
# 创建 .env 文件
touch .env
```

编辑 `.env` 文件，添加以下配置：

```env
# ============================================
# 数据库配置（必需）
# ============================================
# 如果 8001 端口被占用，可以修改为其他端口（如 8002, 8003 等）
SURREAL_URL=ws://localhost:8001/rpc
SURREAL_USER=root
SURREAL_PASSWORD=root
SURREAL_NAMESPACE=open_notebook
SURREAL_DATABASE=production
# 或者使用旧格式（如果 SURREAL_URL 未设置，会使用这些变量）
# SURREAL_ADDRESS=localhost
# SURREAL_PORT=8001

# ============================================
# AI 提供商配置（至少需要一个）
# ============================================

# OpenAI (推荐，功能最全)
OPENAI_API_KEY=sk-your-openai-key-here

# Anthropic (Claude 模型)
# ANTHROPIC_API_KEY=sk-ant-your-anthropic-key-here

# Google Gemini
# GEMINI_API_KEY=your-gemini-key-here

# Ollama (本地 AI 模型)
# OLLAMA_API_BASE=http://localhost:11434

# 其他提供商（可选）
# GROQ_API_KEY=your-groq-key
# MISTRAL_API_KEY=your-mistral-key
# DEEPSEEK_API_KEY=your-deepseek-key

# ============================================
# 应用配置（可选）
# ============================================

# 密码保护（公开部署时使用）
# OPEN_NOTEBOOK_PASSWORD=your_secure_password

# API 配置
API_HOST=127.0.0.1
API_PORT=5055
API_RELOAD=true

# 日志级别
LOG_LEVEL=INFO
```

**重要提示**：
- 至少需要配置一个 AI 提供商的 API Key（推荐 OpenAI）
- 数据库配置使用默认值即可，除非你有特殊需求

### 步骤 5: 创建数据目录

```bash
# 创建必要的数据目录
mkdir -p data/sqlite-db
mkdir -p data/uploads
mkdir -p data/tiktoken-cache
mkdir -p surreal_data
```

### 步骤 6: 启动服务

#### 方式一：使用启动脚本（最简单，推荐）

```bash
# 使用提供的启动脚本（会自动检查依赖并启动所有服务）
./start-local.sh
```

这个脚本会：
1. 检查所有必需的依赖（SurrealDB、uv、Node.js）
2. 创建必要的数据目录
3. 启动 SurrealDB 数据库（如果未运行）
4. 启动 FastAPI 后端（端口 5055）
5. 启动后台工作进程
6. 启动 Next.js 前端（端口 8502）

**停止服务**：
```bash
./stop-local.sh
```

#### 方式二：手动启动各个服务（用于调试）

如果你需要分别启动服务以便调试，可以打开多个终端窗口：

**终端 1: 启动 SurrealDB**
```bash
# 启动 SurrealDB（使用本地文件存储，端口 8001）
surreal start \
  --log info \
  --user root \
  --pass root \
  --bind 0.0.0.0:8001 \
  rocksdb:./surreal_data/mydatabase.db
```

**注意**：如果 8001 端口也被占用，可以修改为其他端口，例如：
```bash
# 使用 8002 端口
surreal start \
  --log info \
  --user root \
  --pass root \
  --bind 0.0.0.0:8002 \
  rocksdb:./surreal_data/mydatabase.db

# 同时更新 .env 文件中的 SURREAL_URL
# SURREAL_URL=ws://localhost:8002/rpc
```

**终端 2: 启动 API 后端**
```bash
# 确保在项目根目录
cd /Users/yunjinqi/Documents/source_code/open-notebook

# 启动 API
uv run python run_api.py
```

**终端 3: 启动后台工作进程**
```bash
# 确保在项目根目录
cd /Users/yunjinqi/Documents/source_code/open-notebook

# 启动 worker
uv run --env-file .env surreal-commands-worker --import-modules commands
```

**终端 4: 启动前端**
```bash
# 进入前端目录
cd frontend

# 启动 Next.js 开发服务器（使用 8502 端口）
npm run dev
```

**注意**：前端已配置为使用 8502 端口（开发和生产模式都使用此端口）。

## 🚀 访问应用

启动所有服务后，访问：

- **前端界面**: http://localhost:8502
- **API 文档**: http://localhost:5055/docs
- **API 健康检查**: http://localhost:5055/health

## 🔍 验证安装

### 1. 检查服务状态

```bash
# 使用 Makefile 检查状态
make status

# 或手动检查
# 检查 SurrealDB
curl http://localhost:8000/health

# 检查 API
curl http://localhost:5055/health

# 检查前端
curl http://localhost:8502
```

### 2. 测试基本功能

1. 打开浏览器访问前端界面（http://localhost:8502）
2. 创建一个新的 Notebook
3. 添加一个文本源
4. 尝试与 AI 聊天

## 🛑 停止服务

### 使用停止脚本（推荐）
```bash
./stop-local.sh
```

### 手动停止

```bash
# 停止前端
pkill -f "next dev"

# 停止 Worker
pkill -f "surreal-commands-worker"

# 停止 API
pkill -f "run_api.py"
pkill -f "uvicorn api.main:app"

# 停止 SurrealDB
pkill -f "surreal start"
```

## ⚙️ 常见问题

### 1. 端口被占用

如果端口被占用，可以修改配置：

**修改 API 端口**：
```bash
# 在 .env 文件中
API_PORT=5056
```

**修改前端端口**：
```bash
# 在 frontend/package.json 中修改 dev 脚本，或运行时指定
cd frontend
PORT=8503 npm run dev
```

**修改 SurrealDB 端口**：
```bash
# 方法1: 在 .env 文件中修改 SURREAL_URL
# SURREAL_URL=ws://localhost:8002/rpc

# 方法2: 使用 SURREAL_PORT 环境变量（旧格式）
# SURREAL_PORT=8002

# 然后启动时指定端口
surreal start --bind 0.0.0.0:8002 --user root --pass root rocksdb:./surreal_data/mydatabase.db
```

### 2. Python 版本问题

确保使用 Python 3.11 或 3.12：

```bash
# 检查 Python 版本
python3 --version

# 使用 uv 安装并固定 Python 版本
uv python install 3.11
uv python pin 3.11
```

### 3. 数据库连接失败

检查 SurrealDB 是否正在运行：

```bash
# 检查进程
ps aux | grep surreal

# 检查端口（默认 8001，如果修改了端口请相应调整）
lsof -i :8001

# 查看 SurrealDB 日志
cat surreal_data/surreal.log

# 测试连接
curl http://localhost:8001/health
```

### 4. 依赖安装问题

**Python 依赖**：
```bash
# 清理并重新安装
rm -rf .venv
uv sync
```

**前端依赖**：
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### 5. API Key 配置问题

确保：
- API Key 格式正确（OpenAI 以 `sk-` 开头）
- API Key 有足够的余额/配额
- 环境变量文件 `.env` 在项目根目录
- 变量名拼写正确（区分大小写）

### 6. 数据库迁移问题

数据库迁移会在 API 启动时自动运行。如果遇到迁移错误：

```bash
# 手动运行迁移
uv run python -m open_notebook.database.async_migrate
```

## 📝 开发模式

### 启用热重载

API 后端默认启用热重载（`API_RELOAD=true`），修改代码后会自动重启。

前端 Next.js 默认支持热重载。

### 查看日志

**API 日志**：在运行 `run_api.py` 的终端查看

**前端日志**：在运行 `npm run dev` 的终端查看

**Worker 日志**：在运行 worker 的终端查看

**SurrealDB 日志**：在运行 SurrealDB 的终端查看

## 🔧 高级配置

### 使用不同的数据库名称

```env
SURREAL_NAMESPACE=my_namespace
SURREAL_DATABASE=my_database
```

### 配置多个 AI 提供商

在 `.env` 文件中添加多个提供商的 API Key，然后在 Web 界面的设置中选择要使用的模型。

### 启用密码保护

```env
OPEN_NOTEBOOK_PASSWORD=your_secure_password
```

启用后，访问前端和 API 都需要密码。

## 📚 下一步

- 阅读 [用户指南](docs/user-guide/index.md) 了解如何使用
- 查看 [API 文档](http://localhost:5055/docs) 了解 API 接口
- 阅读 [开发文档](docs/development/index.md) 了解如何贡献代码

## 🆘 获取帮助

- **Discord**: https://discord.gg/37XJPXfz2w
- **GitHub Issues**: https://github.com/lfnovo/open-notebook/issues
- **文档**: https://www.open-notebook.ai

---

**提示**: 如果遇到问题，请检查所有服务是否都在运行，并查看相应的日志输出。

