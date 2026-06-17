# TestPilot · API Mock Server 完整方案

> 版本：v1.0 | 日期：2026-06-17 | 模块：执行引擎 → Mock服务

---

## 一、方案概览

API Mock在测试平台中的角色：

```
测试用例设计阶段                    测试执行阶段
      │                                │
      ├── 接口未开发完成               ├── 下游依赖不可用
      ├── 需要异常/边界场景             ├── 需要稳定可控的返回值
      ├── 前端并行开发需要接口          ├── 性能压测需要隔离外部依赖
      │                                │
      ▼                                ▼
   Mock场景创建  ◄───────────────    Mock服务运行
```

**设计原则：**
- 零代码Mock：通过UI配置即可生成Mock规则
- OpenAPI驱动：导入Swagger/OpenAPI JSON自动生成全套Mock
- 链路Mock：支持多接口调用链的场景化Mock
- 录制回放：抓取真实接口响应，脱敏后回放

---

## 二、技术选型

| 方案 | 适用场景 | 优势 | 劣势 |
|------|---------|------|------|
| **Mockoon** | 独立开发/调试 | 桌面UI，功能全 | 无法嵌入平台 |
| **Prism** | OpenAPI自动Mock | 零配置 | 动态场景弱 |
| **WireMock** | 集成测试 | 状态机/延迟 | Java依赖，重 |
| **自研Mock Server** | 嵌入平台 | 完全可控 | 开发成本 |

**选择：自研 Mock Server（FastAPI） + Prism 辅助（OpenAPI快速解析）**

```bash
# 自研Mock服务作为平台微服务之一，与执行引擎同部署
docker compose up -d mock-server
```

---

## 三、Mock Server 架构

```
                    TestPilot 前端
                         │
                ┌────────┴────────┐
                │  Mock管理API    │ ── 创建/编辑/启用/禁用Mock规则
                │  POST /api/mock/rules      │
                │  GET  /api/mock/rules/{id} │
                └────────┬────────┘
                         │
            ┌────────────▼────────────┐
            │    Mock规则引擎          │
            │  (已加载到内存)          │
            │                         │
            │  ┌─────────────────┐    │
            │  │ 路径匹配引擎     │    │
            │  │ URL+Method匹配   │    │
            │  └────────┬────────┘    │
            │           │             │
            │  ┌────────▼────────┐    │
            │  │ 场景状态机       │    │
            │  │ 同一接口多次调用  │    │
            │  │ 返回不同结果      │    │
            │  └────────┬────────┘    │
            │           │             │
            │  ┌────────▼────────┐    │
            │  │ 响应模板引擎     │    │
            │  │ Jinja2 + Faker  │    │
            │  │ 生成动态Mock数据 │    │
            │  └────────┬────────┘    │
            │           │             │
            │  ┌────────▼────────┐    │
            │  │ 故障注入引擎     │    │
            │  │ 延迟/错误码/超时 │    │
            │  └─────────────────┘    │
            └────────────┬────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   Mock服务端口     录制代理端口     管理API端口
   :8090 (默认)    :8091 (可选)    :8092 (内部)
```

---

## 四、核心功能

### 4.1 规则类型

| 类型 | 说明 | 示例 |
|------|------|------|
| **静态Mock** | 固定返回值 | GET /api/user → `{"name":"张三"}` |
| **动态Mock** | 模板变量+Faker生成 | `{"name":"{{ faker.name() }}"}` |
| **场景Mock** | 状态机，按调用次数返回不同 | 第1次200、第2次429、第3次200 |
| **条件Mock** | 根据请求参数/Header匹配 | Header `X-Role=admin` → 不同响应 |
| **延迟Mock** | 模拟网络延迟 | 固定200ms / 随机200-2000ms |
| **代理Mock** | 转发到真实服务，失败时用Mock | 先尝试验证码服务，挂了用Mock |
| **录制Mock** | 抓取真实响应存储为Mock | 调用真实服务1次，后续用录制结果 |

### 4.2 Mock规则数据结构

```json
{
  "id": "mock_001",
  "project_id": 1,
  "name": "用户登录Mock",
  "enabled": true,
  "method": "POST",
  "path": "/api/auth/login",
  "match_config": {
    "headers": {"Content-Type": "application/json"},
    "query_params": {}
  },
  "scenario_steps": [
    {
      "step": 1,
      "condition": null,
      "response": {
        "status_code": 200,
        "headers": {"Content-Type": "application/json"},
        "body": {
          "code": 0,
          "data": {
            "token": "{{ faker.uuid4() }}",
            "user": {
              "id": "{{ faker.random_int(1,1000) }}",
              "name": "{{ faker.name() }}"
            }
          }
        },
        "delay_ms": 0
      }
    },
    {
      "step": 2,
      "condition": {"body.password": "wrong"},
      "response": {
        "status_code": 401,
        "body": {"code": 401, "message": "密码错误"}
      }
    },
    {
      "step": 3,
      "condition": null,
      "response": {
        "status_code": 429,
        "body": {"code": 429, "message": "请求过于频繁"}
      }
    }
  ],
  "fault_injection": {
    "timeout_probability": 0.05,
    "timeout_ms": 5000,
    "error_probability": 0.02,
    "error_status_codes": [500, 502, 503]
  }
}
```

### 4.3 Faker 模板引擎

支持Python Faker库全部生成器，内置扩展：

```
基础类型:
  {{ faker.name() }}          → 张三
  {{ faker.email() }}         → zhangsan@example.com
  {{ faker.phone_number() }}  → 13800138000
  {{ faker.uuid4() }}         → a1b2c3d4-...
  {{ faker.random_int(1,1000) }}
  {{ faker.date_time_between('-30d','now') }}

金融/业务:
  {{ faker.credit_card_number() }}
  {{ faker.amount() }}        → ¥1,234.56
  {{ faker.order_id() }}      → ORD-20260617-0001

自定义:
  {{ faker.timestamp() }}     → 当前时间戳
  {{ faker.env('BASE_URL') }} → 环境变量
```

### 4.4 OpenAPI智能导入

```python
# 导入Swagger文档后自动生成Mock规则
POST /api/mock/import-openapi
{
  "project_id": 1,
  "openapi_url": "https://api.example.com/v3/api-docs",
  "options": {
    "auto_enable": true,
    "default_delay_ms": 0,
    "generate_examples": true,
    "include_error_scenarios": true  # 自动生成400/401/404/500场景
  }
}

# 返回生成结果
{
  "imported_endpoints": 47,
  "generated_rules": 47,
  "generated_scenarios": 188,  # 每个接口×4种错误场景
  "errors": []
}
```

### 4.5 录制回放

```python
# 1. 开启录制模式
POST /api/mock/record/start
{
  "project_id": 1,
  "target_host": "https://real-api.example.com",
  "filter_paths": ["/api/user/*", "/api/order/*"],
  "strip_sensitive_fields": ["phone", "id_card", "bank_account"]
}

# 2. 执行测试用例（请求被代理到真实服务）
# 所有响应被自动录制

# 3. 停止录制，生成Mock规则
POST /api/mock/record/stop
# 返回: 录制的接口数、生成的规则数
```

---

## 五、Mock Server 核心代码骨架

```python
# mock_server/main.py
from fastapi import FastAPI, Request
from jinja2 import Template
from faker import Faker
import yaml, json, time, random

app = FastAPI(title="TestPilot Mock Server")
fake = Faker('zh_CN')

# 模拟规则存储（生产环境用Redis）
rules_cache: dict = {}  # key: "method:path"

def load_rules(project_id: int):
    """从MySQL加载Mock规则到内存"""
    # SELECT * FROM mock_rules WHERE project_id = ? AND enabled = 1
    pass

def match_rule(method: str, path: str, headers: dict, body: dict):
    """路径匹配：精确 → 通配符 → 正则"""
    key = f"{method}:{path}"
    # 1. 精确匹配
    if key in rules_cache:
        return rules_cache[key]
    # 2. 通配符匹配 /api/user/*
    for pattern, rule in rules_cache.items():
        if match_wildcard(pattern, key):
            return rule
    return None

@app.api_route("/{path:path}", methods=["GET","POST","PUT","DELETE","PATCH","OPTIONS"])
async def mock_handler(request: Request, path: str):
    rule = match_rule(request.method, f"/{path}", dict(request.headers), await request.body())
    if not rule:
        return {"error": "No mock rule matched", "path": f"/{path}"}

    # 获取当前场景步
    step_key = f"scenario:{rule['id']}"
    current_step = redis_client.incr(step_key)

    # 查找匹配的响应
    response_step = None
    for step in rule.get('scenario_steps', []):
        if step.get('step') == current_step:
            response_step = step
            break

    if not response_step:
        response_step = rule['scenario_steps'][0]

    # 故障注入
    fault = rule.get('fault_injection', {})
    if random.random() < fault.get('timeout_probability', 0):
        time.sleep(fault.get('timeout_ms', 5000) / 1000)
    if random.random() < fault.get('error_probability', 0):
        return {"error": "Injected fault"}, random.choice(fault.get('error_status_codes', [500]))

    # 渲染模板
    body_template = json.dumps(response_step['response']['body'])
    rendered_body = Template(body_template).render(faker=fake)

    # 延迟
    delay = response_step['response'].get('delay_ms', 0)
    if delay:
        time.sleep(delay / 1000)

    return JSONResponse(
        content=json.loads(rendered_body),
        status_code=response_step['response']['status_code'],
        headers=response_step['response'].get('headers', {})
    )
```

---

## 六、Docker 部署

```yaml
# docker-compose.yml 添加
services:
  mock-server:
    image: python:3.12-slim
    container_name: testpilot-mock
    ports:
      - "8090:8090"
      - "8091:8091"
    volumes:
      - ./mock_rules:/app/rules
    environment:
      - REDIS_URL=redis://redis:6379/2
      - MYSQL_URL=mysql://testops:pass@mysql/testops_core
    command: uvicorn mock_server.main:app --host 0.0.0.0 --port 8090
    depends_on:
      - redis
      - mysql
```

---

## 七、与平台集成

```
测试用例步骤配置
├── 执行环境
│   ├── 真实环境 (https://api.example.com)
│   └── Mock环境 (http://mock-server:8090)  ← 一键切换
│
└── Mock开关
    ├── 全部Mock (全链路Mock)
    ├── 部分Mock (勾选需要Mock的接口)
    └── 不Mock (走真实服务)
```

在测试执行配置中，用户只需切换环境变量 `API_BASE_URL` 即可从真实环境切换到Mock环境，无需修改任何用例代码。
