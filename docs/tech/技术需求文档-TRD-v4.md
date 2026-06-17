# TestPilot 自动化测试平台 · 技术需求文档 (TRD) v4.0

> 更新日期：2026-06-17 13:09 | 版本：v4.0
> 本轮新增：CI/CD技术实现/服务器监控部署/Prometheus配置/告警规则/报表数据流

---

## 一、技术架构总览

```
前端: React 18 + TypeScript + Ant Design 5 + Chart.js 4
         ↓ HTTPS + WebSocket
网关: Nginx (反向代理 + 静态资源)
         ↓
后端: FastAPI (Python 3.12) + WebSocket (Socket.IO)
         ↓
┌────────┬────────┬────────┬────────┬────────┬────────┬────────┐
│项目服务 │执行服务 │AI服务  │报告服务 │Mock服务│通知服务 │监控服务 │
│FastAPI │Celery  │LangChain│Pandas │FastAPI │Celery  │Prometheus│
│:8001   │Worker  │:8003   │:8004   │:8005   │Beat    │:9090    │
└────────┴────────┴────────┴────────┴────────┴────────┴────────┘
         ↓                 ↓                    ↓
┌─────────────────┐  ┌──────────────┐  ┌──────────────────┐
│MySQL 8.0 (业务) │  │PostgreSQL 14 │  │Redis 7 (缓存/队列)│
│用户/项目/用例   │  │结果/趋势分析  │  │Celery Broker     │
└─────────────────┘  └──────────────┘  └──────────────────┘

对象存储: MinIO (截图/录屏/报告文件)
监控栈: Prometheus + Grafana + AlertManager + Node Exporter
```

---

## 二、技术栈选型

### 2.1 后端

| 组件 | 选型 | 版本 | 理由 |
|------|------|------|------|
| Web框架 | FastAPI | 0.110+ | 异步原生、自动OpenAPI、Pydantic验证 |
| 异步任务 | Celery | 5.3+ | Python标准异步框架，Redis Broker |
| 定时调度 | Celery Beat | — | Cron定时任务（定时报告/数据清理） |
| ORM | SQLAlchemy 2.0 | 2.0+ | Python最成熟ORM，异步支持 |
| 数据验证 | Pydantic v2 | 2.5+ | FastAPI原生集成 |
| AI框架 | LangChain | 0.2+ | GPT-4o调用、Chain编排 |
| HTTP客户端 | httpx | — | 异步HTTP请求(CI/CD回调/第三方API) |

### 2.2 前端

| 组件 | 选型 | 版本 | 理由 |
|------|------|------|------|
| 框架 | React | 18.x | 生态最大、AntD完美支持 |
| 语言 | TypeScript | 5.x | 类型安全 |
| UI库 | Ant Design | 5.x | 企业级中后台首选，a-table/a-form/a-tree |
| 状态管理 | Zustand | 4.x | 轻量，比Redux简洁 |
| 图表 | Chart.js | 4.4 | 轻量高性能，支持doughnut/line/bar/area |
| WebSocket | Socket.IO Client | 4.x | 实时推送（执行进度/性能指标/AI流式） |
| 国际化 | react-intl | — | 中英文切换 |

### 2.3 数据库

| 库 | 用途 | 版本 | 说明 |
|----|------|------|------|
| MySQL | 业务数据 | 8.0 | 用户/项目/用例/权限/计划 — 14张表 |
| PostgreSQL | 分析数据 | 14+ | 测试结果/趋势指标 — 3张表 + TimescaleDB超表 |
| Redis | 缓存+队列 | 7.x | Celery Broker + 执行状态缓存 + WebSocket Pub/Sub |
| MinIO | 对象存储 | latest | 截图/录屏/报告文件/导出PDF |

### 2.4 监控栈

| 组件 | 端口 | 用途 |
|------|------|------|
| Prometheus | 9090 | 指标采集 + 存储 |
| Grafana | 3000 | 可视化仪表盘 |
| AlertManager | 9093 | 告警路由 |
| Node Exporter | 9100 | 系统指标(CPU/内存/磁盘/网络) |
| MySQL Exporter | 9104 | MySQL慢查询/QPS/连接数 |
| PG Exporter | 9187 | PG连接数/缓存命中率 |
| Redis Exporter | 9121 | Redis内存/命中率 |
| cAdvisor | 8080 | Docker容器监控 |
| Blackbox Exporter | 9115 | HTTP探测/可用性 |

---

## 三、数据库设计概要

### 3.1 MySQL业务库（14张表）

```
users / roles / permissions / role_permissions / user_roles
projects / project_members / environments
test_cases / test_steps / test_plans / test_plan_cases
execution_records / execution_case_results
defects
api_tokens / audit_logs
page_objects / elements / keywords / performance_scenarios
```

### 3.2 PostgreSQL分析库（3张表）

```
test_results_detail (宽表，每条用例执行结果)
test_metrics_ts (TimescaleDB超表，按时间聚合)
ai_analysis_logs (AI分析记录)
```

### 3.3 数据同步

MySQL → PostgreSQL：Debezium CDC 实时同步（生产阶段），MVP阶段应用层双写。

---

## 四、RESTful API设计

### 4.1 8大模块

| 模块 | 路径前缀 | 接口数 |
|------|---------|--------|
| 认证 | /api/v1/auth | 5 |
| 项目管理 | /api/v1/projects | 8 |
| 用例管理 | /api/v1/cases | 12 |
| 执行引擎 | /api/v1/executions | 10 |
| 报告分析 | /api/v1/reports | 8 |
| AI服务 | /api/v1/ai | 6 |
| 系统管理 | /api/v1/system | 10 |
| CI/CD | /api/v1/cicd | 5 |

### 4.2 统一响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": {},
  "request_id": "req_xxx"
}
```

### 4.3 认证方式

JWT Bearer Token，Token过期时间24小时，Refresh Token 7天。CI/CD调用使用专用API Token。

---

## 五、CI/CD集成技术实现

### 5.1 触发流程

```
外部CI Pipeline → POST /api/v1/executions (Bearer Token)
                 → TestPilot 创建执行记录
                 → 返回 execution_id
                 → CI轮询 GET /api/v1/executions/{id}
                 → 执行完成
                 → CI调用 GET /api/v1/gates/check/{id}
                 → 返回门禁结果 {passed: bool, failures: []}
```

### 5.2 关键接口

| 接口 | 方法 | 说明 |
|------|------|------|
| /api/v1/executions | POST | 触发执行，返回execution_id |
| /api/v1/executions/{id} | GET | 查询执行状态 |
| /api/v1/gates/check/{id} | GET | 质量门禁检查 |
| /api/v1/cicd/tokens | POST | 创建CI Token |

---

## 六、服务器监控部署

### 6.1 Docker Compose 监控栈

```yaml
services:
  prometheus:    # :9090  指标采集存储
  alertmanager:  # :9093  告警路由
  grafana:       # :3000  可视化仪表盘
```

### 6.2 被监控端安装（每台服务器）

```bash
# Node Exporter（必装）
wget node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter /usr/local/bin/
sudo systemctl enable node_exporter

# 可选 Exporter
# MySQL: mysqld_exporter :9104
# PostgreSQL: postgres_exporter :9187
# Redis: redis_exporter :9121
# Docker: cadvisor :8080
```

### 6.3 告警规则（10条）

- CPU > 90% 持续5分钟 → warning
- 内存 < 10% → critical
- 磁盘 < 20% → warning / < 5% → critical
- MySQL连接数 > 80% → warning
- Redis内存 > 80% → warning
- 服务器宕机 2分钟 → critical

### 6.4 Grafana集成

Grafana开启匿名访问，TestPilot前端通过iframe嵌入Dashboard。压测时自动关联时间范围展示资源消耗。

---

## 七、报告数据流

```
Worker采集结果 → Redis Stream → Celery聚合任务
                                    ↓
                    ┌── 写PostgreSQL (结果明细+指标)
                    ├── 写MinIO (截图/录屏)
                    ├── 触发AI失败分析
                    ├── 计算质量门禁
                    ├── 生成报告HTML/PDF
                    └── 发送通知 (WebSocket + 飞书/企微)
```

---

## 八、部署方案

### 8.1 开发环境

```bash
docker compose -f docker-compose.dev.yml up -d
# 含：MySQL + PostgreSQL + Redis + MinIO + 后端服务
```

### 8.2 生产环境

```bash
docker compose -f docker-compose.prod.yml up -d
# 含：12个容器 — Nginx + React + 4个FastAPI + Celery + MySQL + PG + Redis + MinIO + Selenium Grid + Appium Grid
```

### 8.3 监控环境

```bash
docker compose -f docker-compose.monitoring.yml up -d
# 含：Prometheus + AlertManager + Grafana
```

---

## 九、技术约束与规范

- **Python版本**：3.12+
- **Node版本**：22.x
- **代码规范**：Black (Python) + ESLint (TypeScript)
- **API文档**：FastAPI自动生成 OpenAPI 3.0 (Swagger UI)
- **日志**：structlog → JSON格式 → ELK采集
- **CI**：GitHub Actions（lint/test/build）
- **安全**：JWT + RBAC + API Token + HTTPS + SQL注入防护(Pydantic/SQLAlchemy)
