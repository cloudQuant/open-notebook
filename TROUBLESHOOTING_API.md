# API 连接问题排查指南

## 问题：Unable to Connect to API Server

如果看到 "Unable to Connect to API Server" 错误，请按以下步骤排查：

## 快速检查清单

### 1. 检查 API 是否在运行

```bash
# 检查 API 进程
ps aux | grep "run_api.py" | grep -v grep

# 检查 API 端口是否监听
lsof -i :5055 -sTCP:LISTEN

# 测试 API 连接
curl http://localhost:5055/health
```

### 2. 检查 SurrealDB 是否在运行

```bash
# 检查 SurrealDB 进程
ps aux | grep "surreal start" | grep -v grep

# 检查 SurrealDB 端口（默认 8001）
lsof -i :8001 -sTCP:LISTEN

# 测试 SurrealDB 连接
curl http://localhost:8001/health
```

### 3. 检查环境配置

```bash
# 检查 .env 文件
cat .env | grep -E "SURREAL_URL|API_URL|API_PORT"

# 应该看到：
# SURREAL_URL=ws://localhost:8001/rpc
# API_URL=http://localhost:5055
# API_PORT=5055
```

## 常见问题及解决方案

### 问题 1: API 启动失败 - 数据库迁移错误

**症状**：
- API 进程存在但端口未监听
- 日志显示 "Failed to run database migrations"
- 错误信息：`did not receive a valid HTTP response from proxy`

**解决方案**：

1. **确保 SurrealDB 正在运行**：
```bash
# 如果未运行，启动 SurrealDB
surreal start \
  --log info \
  --user root \
  --pass root \
  --bind 0.0.0.0:8001 \
  rocksdb:./surreal_data/mydatabase.db
```

2. **检查 .env 配置**：
```bash
# 确保 SURREAL_URL 格式正确
SURREAL_URL=ws://localhost:8001/rpc
```

3. **重启 API**：
```bash
# 停止旧的 API 进程
pkill -f "run_api.py"
pkill -f "uvicorn api.main:app"

# 重新启动 API
uv run python run_api.py
```

### 问题 2: 前端无法连接到 API

**症状**：
- 前端显示 "Unable to Connect to API Server"
- 浏览器控制台显示 CORS 错误或连接超时

**解决方案**：

1. **检查 API 是否运行**：
```bash
curl http://localhost:5055/health
# 应该返回: {"status":"healthy"}
```

2. **检查前端配置**：
```bash
# 在 .env 文件中设置 API_URL（如果需要）
API_URL=http://localhost:5055
```

3. **检查 Next.js 配置**：
```bash
# frontend/next.config.ts 应该包含：
# INTERNAL_API_URL=http://localhost:5055
```

### 问题 3: 端口冲突

**症状**：
- 启动服务时提示端口已被占用
- 服务无法启动

**解决方案**：

1. **查找占用端口的进程**：
```bash
# 查找占用 5055 端口的进程
lsof -i :5055

# 查找占用 8001 端口的进程
lsof -i :8001
```

2. **停止冲突的进程或修改端口**：
```bash
# 修改 API 端口（在 .env 中）
API_PORT=5056

# 修改 SurrealDB 端口（在 .env 中）
SURREAL_URL=ws://localhost:8002/rpc
```

## 完整重启流程

如果所有服务都无法正常工作，按以下步骤完全重启：

```bash
# 1. 停止所有服务
./stop-local.sh

# 2. 检查并启动 SurrealDB
surreal start \
  --log info \
  --user root \
  --pass root \
  --bind 0.0.0.0:8001 \
  rocksdb:./surreal_data/mydatabase.db

# 等待 3 秒
sleep 3

# 3. 启动 API
uv run python run_api.py &

# 等待 3 秒
sleep 3

# 4. 启动 Worker（可选）
uv run --env-file .env surreal-commands-worker --import-modules commands &

# 5. 启动前端
cd frontend && npm run dev
```

## 使用诊断脚本

项目包含一个诊断脚本，可以自动检查并修复常见问题：

```bash
./fix-api-connection.sh
```

这个脚本会：
1. 检查 SurrealDB 状态
2. 检查端口监听情况
3. 验证环境配置
4. 清理旧的 API 进程
5. 重新启动 API

## 查看日志

如果问题仍然存在，查看相关日志：

```bash
# API 日志（如果使用启动脚本）
tail -f api.log

# SurrealDB 日志
tail -f surreal_data/surreal.log

# 前端日志（在运行 npm run dev 的终端中查看）
```

## 仍然无法解决？

1. **检查 Python 版本**：确保使用 Python 3.11 或 3.12
2. **检查依赖**：运行 `uv sync` 确保所有依赖已安装
3. **检查数据库文件权限**：确保 `surreal_data` 目录可写
4. **查看详细错误**：在 API 启动终端查看完整错误堆栈

## 联系支持

如果问题仍然存在，请提供：
- 错误日志
- `.env` 文件内容（隐藏 API keys）
- `make status` 的输出
- 系统信息（OS、Python 版本等）

