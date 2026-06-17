# TestPilot · 真实Locust接入集成方案

> 版本：v1.0 | 日期：2026-06-17 | 模块：执行引擎 → 性能压测

---

## 一、为什么选择Locust

| 维度 | JMeter | Locust | Gatling | k6 |
|------|--------|--------|---------|-----|
| 语言 | Java/XML | Python | Scala | JS/Go |
| 分布式 | 原生支持 | 原生支持(Master/Worker) | 需要企业版 | 需要k6 Cloud |
| 实时监控 | 需插件 | Web UI实时 | 需Grafana | 需Grafana |
| 脚本灵活性 | 低(GUI驱动) | 高(Python代码) | 中 | 高(JS) |
| 学习成本 | 高 | 低(测试同学会Python) | 高 | 中 |
| 容器化 | 支持 | 完美支持 | 支持 | 支持 |
| 与平台Python技术栈一致 | ❌ | ✅ | ❌ | ❌ |

**核心优势：Python原生、分布式Master/Worker模式简单、Web UI实时监控、Python hooks可编程数据采集。**

---

## 二、集成架构

```
TestPilot 平台层
├── 前端 (React)
│   ├── 压测场景创建页面 → API接口定义 → 数据驱动配置
│   ├── 压测执行触发 (一键开始/参数调整/实时监控)
│   └── 监控大盘 (单接口/链路/服务器资源 3大面板)
│
├── 后端 (FastAPI)
│   ├── POST /api/perf/scenarios → 创建/更新压测场景
│   ├── POST /api/perf/execute    → 触发压测执行
│   ├── GET  /api/perf/metrics    → 实时拉取指标(WebSocket推送)
│   └── GET  /api/perf/reports    → 压测报告生成
│
└── Locust执行集群 (Docker Compose)
    ├── Locust Master (1个)
    │   ├── Web UI (:8089) → 内部调试用
    │   ├── API  (:5557/5558) → Worker通信
    │   └── Custom Hooks → 实时指标推送到Redis
    │
    └── Locust Worker (N个，可动态扩缩)
        ├── worker-1 → 执行任务HttpUser
        ├── worker-2 → Chrome模拟
        └── worker-N → ...
            │
            ▼ (负载生成)
        ┌──────────────────┐
        │  目标服务          │
        │  (被测系统)        │
        └──────────────────┘
```

---

## 三、Locust脚本自动生成

### 3.1 从平台API定义自动生成Locust脚本

用户在平台中定义了API接口后，平台自动生成Locust压测脚本：

```python
# 自动生成的 locustfile.py (基于平台API定义)
from locust import HttpUser, task, between, events
import json, time, random

class TestPilotUser(HttpUser):
    wait_time = between(1, 3)  # 可配置
    host = "{{ TARGET_HOST }}"  # 运行时注入

    def on_start(self):
        """登录获取Token"""
        resp = self.client.post("/api/auth/login", json={
            "username": "{{ TEST_USER }}",
            "password": "{{ TEST_PASS }}"
        })
        self.token = resp.json()["data"]["token"]

    @task(3)  # 权重3，高频
    def get_order_list(self):
        """GET /api/orders?page=1&size=20"""
        start = time.time()
        with self.client.get(
            "/api/orders",
            params={"page": 1, "size": 20},
            headers={"Authorization": f"Bearer {self.token}"},
            catch_response=True
        ) as resp:
            duration = (time.time() - start) * 1000
            if resp.status_code != 200:
                resp.failure(f"状态码异常: {resp.status_code}")
            # 推送到Redis实时指标
            events.request.fire(
                request_type="GET",
                name="/api/orders",
                response_time=duration,
                response_length=len(resp.content),
                exception=None if resp.ok else Exception(f"HTTP {resp.status_code}"),
                context={"scenario_id": "{{ SCENARIO_ID }}"}
            )

    @task(1)  # 权重1，低频
    def create_order(self):
        """POST /api/orders"""
        order_data = {
            "product_id": random.randint(1, 100),
            "quantity": random.randint(1, 5),
            "coupon_code": None
        }
        self.client.post(
            "/api/orders",
            json=order_data,
            headers={"Authorization": f"Bearer {self.token}"}
        )
```

### 3.2 数据驱动压测

```python
# 支持从测试数据文件读取参数
# 平台提供 CSV/JSON 数据集上传功能
class TestPilotUser(HttpUser):
    def on_start(self):
        # 加载数据集
        with open("/data/test_users.csv") as f:
            self.users = list(csv.DictReader(f))
        with open("/data/test_products.json") as f:
            self.products = json.load(f)
        self.user_index = 0

    @task
    def login_and_order(self):
        # 轮替使用不同用户数据
        user = self.users[self.user_index % len(self.users)]
        self.user_index += 1
        # ...使用user数据执行测试
```

---

## 四、实时数据采集

### 4.1 Locust → Redis → WebSocket 数据管道

```python
# locustfile.py 中注册事件钩子
from locust import events
import redis, json, time

r = redis.Redis(host='redis', port=6379, db=1)

@events.request.add_listener
def on_request(request_type, name, response_time, response_length,
               exception, context, **kwargs):
    """每次请求完成时触发"""
    metric = {
        "timestamp": int(time.time() * 1000),
        "perf_run_id": context.get("scenario_id"),
        "endpoint": name,
        "response_time_ms": response_time,
        "status": "success" if exception is None else "failed",
        "error_msg": str(exception) if exception else None
    }
    # 写入Redis Stream（支持多消费者）
    r.xadd(f"perf:metrics:{context['scenario_id']}", metric)

@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """压测开始时注册"""
    r.hset(f"perf:run:{environment.parsed_options.scenario_id}",
           "status", "running")

@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """压测结束时触发"""
    r.hset(f"perf:run:{environment.parsed_options.scenario_id}",
           "status", "stopped")
```

### 4.2 后端 WebSocket 推送

```python
# backend/perf_ws.py
import asyncio, redis.asyncio as aioredis, json
from fastapi import WebSocket

r = aioredis.from_url("redis://redis:6379/1")

async def perf_metrics_pusher(websocket: WebSocket, perf_run_id: int):
    """从Redis流读取指标，推送到前端WebSocket"""
    last_id = "0"
    while True:
        # 读取Redis Stream
        entries = await r.xread(
            {f"perf:metrics:{perf_run_id}": last_id},
            count=100, block=1000
        )
        for stream, messages in entries:
            for msg_id, data in messages:
                last_id = msg_id
                await websocket.send_json(data)

        # 检查压测是否结束
        status = await r.hget(f"perf:run:{perf_run_id}", "status")
        if status == b"stopped":
            await websocket.send_json({"type": "run_complete"})
            break
```

---

## 五、Docker Compose 部署

```yaml
# docker-compose.perf.yml
services:
  locust-master:
    image: locustio/locust:2.31
    ports:
      - "8089:8089"  # Web UI (仅调试)
      - "5557:5557"  # Master通信端口
      - "5558:5558"
    volumes:
      - ./perf_scripts:/mnt/locust
      - ./perf_data:/mnt/data
    environment:
      - LOCUST_MODE=master
      - TARGET_HOST=${TARGET_HOST:-https://api.example.com}
      - REDIS_URL=redis://redis:6379/1
      - SCENARIO_ID=${SCENARIO_ID:-0}
    command: >
      locust -f /mnt/locust/locustfile.py
      --master
      --expect-workers=${WORKERS:-2}
      --run-time ${DURATION:-10m}
      --users ${USERS:-100}
      --spawn-rate ${SPAWN_RATE:-10}
      --headless
    depends_on:
      - redis

  locust-worker:
    image: locustio/locust:2.31
    volumes:
      - ./perf_scripts:/mnt/locust
      - ./perf_data:/mnt/data
    environment:
      - LOCUST_MODE=worker
      - LOCUST_MASTER_HOST=locust-master
      - REDIS_URL=redis://redis:6379/1
    command: locust -f /mnt/locust/locustfile.py --worker
    deploy:
      replicas: 3  # 默认3个Worker
    depends_on:
      - locust-master
```

---

## 六、与平台交互流程

```
用户操作                        平台后端                     Locust集群
────────                      ────────                    ──────────
│ 1.创建压测场景               POST /api/perf/scenarios
│   (选接口/设并发/设时长)         ↓
│                            生成locustfile.py
│                            存储到MinIO
│
│ 2.点击"开始压测"             POST /api/perf/execute
│                               ↓
│                            设置环境变量(并发/时长)  ──→  docker compose up
│                            启动Locust集群               Locust Master + Workers
│                                                          ↓
│                            订阅Redis Stream     ←────  实时指标推送
│                               ↓
│ 3.实时监控大盘    ←──WebSocket── 推送指标数据
│   QPS/RT/成功率
│   百分位/错误分布
│
│ 4.压测结束                   检测到test_stop事件
│                               ↓
│                            生成Allure报告
│                            存储到MinIO
│
│ 5.查看报告                  GET /api/perf/reports/{id}
│   历史对比
```

---

## 七、监控大盘数据流

```
Locust Worker 1 ─┐
Locust Worker 2 ─┼─→ Redis Stream ─→ FastAPI WebSocket ─→ React前端实时渲染
Locust Worker N ─┘    (perf:metrics:*)     (/ws/perf/{run_id})
                              │
                              ▼
                     Celery异步任务
                     每15秒聚合一次
                              │
                              ▼
                    PostgreSQL perf_metrics
                    (TimescaleDB时序表)
                              │
                              ▼
                    历史数据用于趋势分析
                    和报告生成
```

---

## 八、链路压测方案

```python
# 链路压测：一个用户任务按顺序调用多个接口
# 模拟真实用户操作路径
class LinkTraceUser(HttpUser):
    wait_time = between(2, 5)

    @task
    def user_journey(self):
        # 1. 浏览商品
        self.client.get("/api/products?category=electronics")

        # 2. 查看详情
        self.client.get("/api/products/12345")

        # 3. 加入购物车
        self.client.post("/api/cart", json={"product_id": 12345, "qty": 1})

        # 4. 结算
        self.client.post("/api/orders/checkout", json={"cart_id": "xxx"})

        # 5. 支付
        self.client.post("/api/payment/pay", json={"order_id": "yyy"})

# OpenTelemetry自动注入TraceID
# 每个接口的span信息通过Jaeger可视化调用链
```
