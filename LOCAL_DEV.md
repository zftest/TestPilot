# TestPilot 本地开发调试指南

## 你需要有的工具

| 工具 | 用途 | 检查命令 |
|------|------|---------|
| Python 3.11+ | 后端运行 | `python --version` |
| Node.js 18+ | 前端运行 | `node --version` |
| MySQL 8.0 | 数据库 | `mysql -u root -p` |
| PyCharm | IDE（只用后端项目） | 你已有 |

---

## 第一步：建库建表（2分钟）

```bash
# 打开 MySQL
mysql -u root -p

# 执行初始化脚本
source D:/TestPilot/sql/mysql/init-testpilot.sql

# 验证
USE testpilot;
SELECT * FROM users;
-- 应该看到一条 admin 记录
```

---

## 第二步：启动后端（PyCharm）

```bash
cd D:\TestPilot\src\backend

# 创建虚拟环境
python -m venv venv

# 激活
venv\Scripts\activate

# 装依赖
pip install -r requirements.txt

# 检查 .env 文件中的数据库密码是否正确
# 如果 MySQL 用户名密码不是 root/root，改 .env

# 启动
uvicorn main:app --reload --port 8000
```

### PyCharm 调试配置（可选）

1. `Run → Edit Configurations → + → Python`
2. Module name: `uvicorn`
3. Parameters: `main:app --reload --port 8000`
4. Working directory: `D:\TestPilot\src\backend`
5. 打断点 → Debug

---

## 第三步：启动前端

```bash
cd D:\TestPilot\src\frontend

# 安装依赖
npm install

# 启动
npm run dev
```

浏览器打开 http://localhost:5173

---

## 第四步：验证

1. 打开 http://localhost:5173 → 看到登录页
2. 点击"立即注册" → 注册一个新账号（第一个注册的用户自动是 admin）
3. 注册成功自动登录 → 进入仪表盘
4. 左侧菜单可点击切换（Phase 1 会逐步激活各模块）

### 缺省管理员账号

| 字段 | 值 |
|------|-----|
| 用户名 | admin |
| 密码 | admin123 |
| 角色 | admin |

---

## 接口测试（用 PyCharm 或 Postman）

```
POST http://localhost:8000/api/v1/auth/login
Body: {"username": "admin", "password": "admin123"}

GET  http://localhost:8000/api/v1/auth/me
Header: Authorization: Bearer <token>

GET  http://localhost:8000/api/v1/users
Header: Authorization: Bearer <token>
```

---

## 如果跑不通

| 症状 | 检查 |
|------|------|
| 连不上 MySQL | `.env` 里 `DB_PASSWORD` 是否正确 |
| 数据库报错 | 是否执行了 `init-testpilot.sql` |
| 前端白屏 | `npm install` 是否成功 |
| 前端 401 | 后端是否在运行（`uvicorn`） |
| CORS 报错 | 前端端口是不是 5173 |
