# 自动化测试平台 · RESTful API 设计规范与核心接口定义

> 版本：v2.0 | 日期：2026-06-17 | 基础路径：`/api/v1`

---

## 一、API设计规范

### 1.1 URL规范

```
https://{domain}/api/v1/{resource}/{resource_id}/{sub_resource}
```

| 规则 | 说明 | 示例 |
|------|------|------|
| 小写复数 | 资源名用小写复数 | `/api/v1/projects` |
| 嵌套关系 | 子资源用`/`嵌套 | `/api/v1/projects/123/cases` |
| 行为用动词 | 非CRUD用动作动词 | `/api/v1/runs/456/stop` |
| 过滤/排序 | URL Query参数 | `?status=failed&sort=-created_at` |

### 1.2 HTTP方法语义

| 方法 | 语义 | 幂等 |
|------|------|------|
| GET | 获取资源 | ✅ |
| POST | 创建资源 / 触发动作 | ❌ |
| PUT | 完整替换资源 | ✅ |
| PATCH | 部分更新资源 | ✅ |
| DELETE | 删除资源 | ✅ |

### 1.3 统一响应格式

**成功响应：**
```json
{
  "code": 0,
  "message": "success",
  "data": { ... },
  "request_id": "req_7f3a2b1c",
  "timestamp": "2026-06-17T10:30:00Z"
}
```

**错误响应：**
```json
{
  "code": 40001,
  "message": "参数错误：project_id 不能为空",
  "errors": [
    { "field": "project_id", "message": "此为必填项" }
  ],
  "request_id": "req_8e4c3d2a",
  "timestamp": "2026-06-17T10:30:00Z"
}
```

### 1.4 错误码规范

| 错误码段 | 含义 | 示例 |
|---------|------|------|
| 0 | 成功 | — |
| 400xx | 客户端错误（参数/校验） | 40001 参数错误 |
| 401xx | 认证错误 | 40101 未登录 |
| 403xx | 权限错误 | 40301 无权限操作 |
| 404xx | 资源不存在 | 40401 项目不存在 |
| 409xx | 冲突 | 40901 项目名称已存在 |
| 500xx | 服务端错误 | 50001 内部错误 |

### 1.5 认证方式

```
Authorization: Bearer <jwt_token>
```

Token载荷结构：
```json
{
  "sub": 123,           // user_id
  "team_id": 5,         // 当前团队
  "role": "tester",      // 角色
  "exp": 1750123456,    // 过期时间
  "jti": "token_uuid"    // 用于注销
}
```

---

## 二、核心模块API定义

### 2.1 认证模块 `/api/v1/auth`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/auth/login` | POST | 登录，返回JWT |
| `/auth/register` | POST | 注册新用户 |
| `/auth/refresh` | POST | 刷新Token |
| `/auth/logout` | POST | 注销（加入黑名单） |
| `/auth/password/reset` | POST | 发送重置密码邮件 |

**登录请求/响应示例：**
```json
// POST /api/v1/auth/login
{
  "email": "zhangsan@company.com",
  "password": "password123"
}

// 响应
{
  "code": 0,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
    "expires_in": 7200,
    "user": {
      "id": 123,
      "username": "zhangsan",
      "display_name": "张三",
      "role": "tester"
    }
  }
}
```

---

### 2.2 项目管理 `/api/v1/projects`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/projects` | GET | 获取项目列表（支持过滤/分页） |
| `/projects` | POST | 创建新项目 |
| `/projects/{id}` | GET | 获取项目详情 |
| `/projects/{id}` | PUT | 更新项目信息 |
| `/projects/{id}` | DELETE | 归档项目 |
| `/projects/{id}/stats` | GET | 获取项目统计概览 |
| `/projects/{id}/members` | GET | 获取项目成员列表 |
| `/projects/{id}/members` | POST | 添加项目成员 |

**项目列表请求示例：**
```
GET /api/v1/projects?status=active&sort=-updated_at&page=1&page_size=20
```

**创建项目请求示例：**
```json
POST /api/v1/projects
{
  "name": "交易链路自动化测试",
  "description": "覆盖订单创建、支付、退款全链路",
  "team_id": 5,
  "config": {
    "environments": ["dev", "test", "pre"],
    "variables": {
      "base_url": "https://api-test.company.com"
    }
  }
}
```

---

### 2.3 测试用例管理 `/api/v1/cases`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/cases` | GET | 获取用例列表（支持过滤/目录树） |
| `/cases` | POST | 创建新用例 |
| `/cases/{id}` | GET | 获取用例详情 |
| `/cases/{id}` | PUT | 更新用例 |
| `/cases/{id}` | DELETE | 删除用例（软删除） |
| `/cases/batch` | POST | 批量创建用例 |
| `/cases/{id}/copy` | POST | 复制用例 |
| `/cases/import` | POST | 导入用例（Swagger/CSV） |
| `/cases/export` | GET | 导出用例 |
| `/cases/folders` | GET | 获取用例目录树 |
| `/cases/ai/generate` | POST | **AI生成测试用例** |

**AI生成用例请求示例：**
```json
// POST /api/v1/cases/ai/generate
{
  "project_id": 10,
  "input_type": "natural_language",
  "input_text": "测试订单创建接口，满1000打9折，非法商品ID返回404",
  "case_count": 6,
  "priority": "p1"
}

// 响应
{
  "code": 0,
  "data": {
    "generated_count": 6,
    "confidence_avg": 0.91,
    "cases": [
      {
        "title": "订单创建-正常场景-金额满1000享受9折",
        "steps": [...],
        "assertions": [...],
        "confidence": 0.97
      },
      // ... 共6条
    ],
    "preview_only": true  // 前端可让用户确认后再导入
  }
}
```

---

### 2.4 测试执行引擎 `/api/v1/runs`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/runs` | GET | 获取执行记录列表 |
| `/runs/{id}` | GET | 获取执行详情 |
| `/runs` | POST | 触发新执行（手动/CI） |
| `/runs/{id}/stop` | POST | 停止正在执行的任务 |
| `/runs/{id}/rerun` | POST | 重新执行（仅失败用例） |
| `/runs/{id}/results` | GET | 获取执行结果列表 |
| `/runs/{id}/results/{result_id}` | GET | 获取单条结果详情 |
| `/runs/{id}/report` | GET | 获取HTML报告URL |

**触发执行请求示例：**
```json
// POST /api/v1/runs
{
  "project_id": 10,
  "plan_id": 25,
  "run_name": "订单模块回归-20260617",
  "env": "test",
  "trigger_source": {
    "type": "manual",
    "triggered_by": 123
  },
  "parallel": 4,
  "timeout_seconds": 1800
}
```

**执行状态推送（WebSocket）：**
```
ws://domain/api/v1/ws/runs/{run_id}

// 服务端推送消息
{
  "type": "run_progress",
  "run_id": 789,
  "status": "running",
  "progress": {
    "total": 68,
    "passed": 62,
    "failed": 4,
    "running": 2
  }
}
```

---

### 2.5 性能压测 `/api/v1/perf`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/perf/scenarios` | GET | 获取性能场景列表 |
| `/perf/scenarios` | POST | 创建性能测试场景 |
| `/perf/scenarios/{id}` | GET | 获取场景详情 |
| `/perf/scenarios/{id}` | PUT | 更新场景配置 |
| `/perf/run` | POST | **触发性能压测** |
| `/perf/runs/{id}` | GET | 获取压测执行状态 |
| `/perf/runs/{id}/stop` | POST | 停止压测 |
| `/perf/runs/{id}/metrics` | GET | 获取实时性能指标 |
| `/perf/runs/{id}/report` | GET | 获取性能报告 |

**触发性能压测请求示例：**
```json
// POST /api/v1/perf/run
{
  "scenario_id": 8,
  "config": {
    "concurrent_users": 200,
    "ramp_up_seconds": 60,
    "duration_seconds": 600,
    "think_time_ms": [500, 2000],
    "location": "local"
  },
  "monitoring": {
    "enable_server_metrics": true,
    "server_endpoints": ["http://10.0.0.5:9100/metrics"]
  }
}
```

**实时性能指标推送（WebSocket）：**
```
ws://domain/api/v1/ws/perf/{perf_run_id}

// 每秒推送一次
{
  "type": "perf_metrics",
  "perf_run_id": 56,
  "timestamp": "2026-06-17T10:35:00Z",
  "current": {
    "qps": 1834,
    "avg_rt_ms": 89,
    "p95_rt_ms": 245,
    "p99_rt_ms": 512,
    "error_rate": 0.003,
    "active_users": 200
  },
  "cumulator": {
    "total_requests": 628340,
    "total_failures": 1885
  }
}
```

---

### 2.6 AI服务 `/api/v1/ai`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/ai/generate/cases` | POST | 自然语言生成测试用例 |
| `/ai/parse/requirement` | POST | 解析需求文档（PDF/Word） |
| `/ai/analyze/failure` | POST | 分析失败根因 |
| `/ai/suggest/repair` | POST | 推荐用例自愈方案 |
| `/ai/predict/risk` | POST | 预测质量风险 |
| `/ai/chat` | POST | AI对话（流式响应） |

**AI对话流式响应（Server-Sent Events）：**
```
GET /api/v1/ai/chat?stream=true

data: {"delta": "根据你的需求文档，我分析了3个核心"}
data: {"delta": "流程节点，建议覆盖以下测试场景："}
data: {"delta": "\n1. 订单创建-正常\n2. 订单创建-库存不足"}
data: {"event": "done", "full_text": "..."}
```

---

### 2.7 报告与分析 `/api/v1/reports`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/reports` | GET | 获取报告列表 |
| `/reports/{id}` | GET | 获取报告详情 |
| `/reports/{id}/export` | GET | 导出报告（PDF/HTML/JSON） |
| `/reports/trend` | GET | 获取质量趋势数据 |
| `/reports/quality-gate` | GET | 获取质量门禁检查结果 |

**质量趋势请求示例：**
```
GET /api/v1/reports/trend?project_id=10&days=30&group_by=day
```

**响应：**
```json
{
  "code": 0,
  "data": {
    "trend": [
      {
        "date": "2026-05-18",
        "total_runs": 3,
        "pass_rate": 0.923,
        "avg_duration_seconds": 312,
        "new_defects": 2
      },
      // ... 30天
    ],
    "summary": {
      "overall_pass_rate": 0.894,
      "trend_direction": "improving",  // improving/stable/declining
      "quality_gate_status": "warning"
    }
  }
}
```

---

### 2.8 系统集成 `/api/v1/integrations`

| 接口 | 方法 | 说明 |
|------|------|------|
| `/integrations` | GET | 获取已集成列表 |
| `/integrations/ci-cd/webhook` | POST | CI/CD触发执行（GitHub/GitLab/Jenkins） |
| `/integrations/jira/sync` | POST | 同步缺陷到Jira |
| `/integrations/feishu/notify` | POST | 发送飞书通知 |
| `/integrations/wecom/notify` | POST | 发送企业微信通知 |

**CI/CD Webhook示例（GitLab Push触发）：**
```
POST /api/v1/integrations/ci-cd/webhook
Header: X-Webhook-Token: <配置的密钥>

{
  "object_kind": "push",
  "project": { "id": 123, "name": "order-service" },
  "commits": [...],
  "ref": "refs/heads/main"
}

// 响应：立即返回，执行异步触发
{
  "code": 0,
  "data": {
    "triggered": true,
    "run_id": 892,
    "run_url": "https://testops.company.com/runs/892"
  }
}
```

---

## 三、分页、过滤、排序规范

### 3.1 分页参数

```
?page=1&page_size=20
```

响应包含分页元数据：
```json
{
  "code": 0,
  "data": { "items": [...], "total": 156 },
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_pages": 8,
    "has_next": true,
    "has_prev": false
  }
}
```

### 3.2 过滤参数

```
?status=running&case_type=api&created_by=123
?tags=smoke&tags=regression   # 多值用重复参数
```

### 3.3 排序参数

```
?sort=created_at      # 升序
?sort=-created_at     # 降序（前缀`-`）
?sort=-created_at,id  # 多字段排序
```

---

## 四、限流与幂等性

### 4.1 限流规则

| 接口类型 | 限制 |
|---------|------|
| 普通查询 | 1000次/分钟/IP |
| 执行触发 | 10次/分钟/用户 |
| AI生成 | 50次/分钟/用户 |
| WebSocket连接 | 5个/用户 |

超出限制响应：`429 Too Many Requests`

### 4.2 幂等性保证

写操作支持`Idempotency-Key`请求头：
```
POST /api/v1/runs
Idempotency-Key: abc-123-def
```

服务端缓存相同Key的响应30分钟，重复请求直接返回缓存结果。

---

## 五、OpenAPI 3.0 规范片段

```yaml
openapi: 3.0.3
info:
  title: TestOps Automation Platform API
  version: v1.0.0
  description: 企业级自动化测试平台RESTful API
servers:
  - url: https://api.testops.company.com/api/v1
    description: 生产环境
  - url: http://localhost:8000/api/v1
    description: 本地开发
security:
  - BearerAuth: []
paths:
  /projects/{project_id}/cases:
    get:
      summary: 获取项目用例列表
      parameters:
        - name: project_id
          in: path
          required: true
          schema: { type: integer }
        - name: case_type
          in: query
          schema: { type: string, enum: [api, ui_web, ui_mobile, performance] }
        - name: status
          in: query
          schema: { type: string }
        - name: page
          in: query
          schema: { type: integer, default: 1 }
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CaseListResponse'
```
