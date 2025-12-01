# API 连接问题快速修复

## 问题症状

访问 http://localhost:8502/notebooks 时显示：
```
Unable to Connect to API Server
```

## 快速修复步骤

### 1. 确保 SurrealDB 正在运行

```bash
# 检查 SurrealDB
ps aux | grep "surreal start" | grep -v grep

# 如果未运行，启动它
surreal start \
  --log info \
  --user root \
  --pass root \
  --bind 0.0.0.0:8001 \
  rocksdb:./surreal_data/mydatabase.db &
```

### 2. 清理并重启 API

```bash
# 停止所有 API 进程
pkill -f "run_api.py"
pkill -f "uvicorn"

# 确保端口已释放
lsof -ti :5055 | xargs kill -9 2>/dev/null

# 设置 NO_PROXY 并启动 API
NO_PROXY="localhost,127.0.0.1,0.0.0.0,::1" uv run python run_api.py
```

### 3. 验证 API 运行

在另一个终端运行：

```bash
# 检查端口
lsof -i :5055 -sTCP:LISTEN

# 测试健康检查
curl http://localhost:5055/health
# 应该返回: {"status":"healthy"}
```

### 4. 刷新浏览器

刷新 http://localhost:8502/notebooks，应该可以正常连接了。

## 使用启动脚本（推荐）

```bash
# 使用修复后的启动脚本
./start-local.sh
```

## 常见问题

### API 启动失败：数据库迁移错误

**原因**：SurrealDB 未运行或连接配置错误

**解决**：
1. 确保 SurrealDB 正在运行（见步骤 1）
2. 检查 `.env` 文件中的 `SURREAL_URL=ws://localhost:8001/rpc`
3. 确保设置了 `NO_PROXY` 环境变量

### 端口已被占用

**解决**：
```bash
# 查找占用端口的进程
lsof -i :5055

# 停止进程
kill -9 <PID>
```

### WebSocket 连接被代理拦截

**解决**：代码已自动设置 `NO_PROXY`，如果仍有问题，手动设置：

```bash
export NO_PROXY="localhost,127.0.0.1,0.0.0.0,::1"
```

## 完整重启流程

```bash
# 1. 停止所有服务
./stop-local.sh

# 2. 启动 SurrealDB
surreal start \
  --log info \
  --user root \
  --pass root \
  --bind 0.0.0.0:8001 \
  rocksdb:./surreal_data/mydatabase.db &

sleep 3

# 3. 启动 API（设置 NO_PROXY）
NO_PROXY="localhost,127.0.0.1,0.0.0.0,::1" uv run python run_api.py &

sleep 5

# 4. 启动 Worker
uv run --env-file .env surreal-commands-worker --import-modules commands &

# 5. 启动前端
cd frontend && npm run dev
```

## 验证所有服务

```bash
# 检查所有端口
lsof -i :8001 -sTCP:LISTEN  # SurrealDB
lsof -i :5055 -sTCP:LISTEN  # API
lsof -i :8502 -sTCP:LISTEN  # 前端

# 测试连接
curl http://localhost:8001/health  # SurrealDB（可能不支持）
curl http://localhost:5055/health  # API（应该返回 {"status":"healthy"}）
```

