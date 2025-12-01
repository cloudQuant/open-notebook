# 端口配置说明

## 默认端口分配

Open Notebook 使用以下端口：

- **前端 (Next.js)**: 8502
- **API 后端 (FastAPI)**: 5055
- **SurrealDB 数据库**: 8001（已从 8000 改为 8001，避免与其他后端服务冲突）

## 端口冲突处理

### 如果 SurrealDB 端口 8001 也被占用

修改 `.env` 文件中的 `SURREAL_URL`：

```env
# 使用 8002 端口
SURREAL_URL=ws://localhost:8002/rpc

# 或者使用其他端口（如 8003, 8004 等）
SURREAL_URL=ws://localhost:8003/rpc
```

然后启动 SurrealDB 时指定对应端口：

```bash
surreal start \
  --log info \
  --user root \
  --pass root \
  --bind 0.0.0.0:8002 \
  rocksdb:./surreal_data/mydatabase.db
```

### 如果前端端口 8502 被占用

修改 `frontend/package.json` 中的端口配置，或运行时指定：

```bash
cd frontend
PORT=8503 npm run dev
```

同时更新 `.env` 文件（如果需要）：

```env
# 如果前端使用不同端口，可能需要更新 API_URL
API_URL=http://localhost:5055
```

### 如果 API 端口 5055 被占用

修改 `run_api.py` 或通过环境变量：

```bash
API_PORT=5056 uv run python run_api.py
```

## 为什么选择这些端口？

- **8502**: 前端端口，避免与常见的 3000、8080 等端口冲突
- **5055**: API 端口，避免与常见的 5000、8000 等端口冲突
- **8001**: 数据库端口，避免与常见的后端服务端口 8000 冲突

## 检查端口占用

```bash
# 检查端口是否被占用
lsof -i :8001  # SurrealDB
lsof -i :5055  # API
lsof -i :8502  # 前端

# 或者使用 netstat
netstat -an | grep LISTEN | grep -E "(8001|5055|8502)"
```

## 快速修改端口

如果所有默认端口都被占用，可以创建一个自定义配置：

```bash
# 1. 修改 .env 文件
cat >> .env << EOF
SURREAL_URL=ws://localhost:8002/rpc
API_PORT=5056
EOF

# 2. 修改前端端口
cd frontend
# 编辑 package.json，修改 dev 脚本为: "dev": "next dev -p 8503"

# 3. 启动服务时使用新端口
surreal start --bind 0.0.0.0:8002 --user root --pass root rocksdb:./surreal_data/mydatabase.db
API_PORT=5056 uv run python run_api.py
cd frontend && PORT=8503 npm run dev
```

