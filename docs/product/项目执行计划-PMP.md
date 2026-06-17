# TestPilot · 项目执行计划 (Project Management Plan)

> 版本：v1.0 | 日期：2026-06-17 | 作者：狼图腾OPC  
> 仓库：https://github.com/zftest/TestPilot.git  
> 本地：D:/TestPilot/

---

## 一、项目概述

### 1.1 项目定义

| 项 | 内容 |
|---|------|
| **产品名称** | TestPilot — AI-Native 全栈自动化测试平台 |
| **产品定位** | 面向中小团队的一站式测试平台，AI驱动，覆盖API/UI/性能/移动端测试全生命周期 |
| **核心差异化** | AI自然语言创建测试 + AI失败根因分析 + 用例自愈 |
| **技术栈** | React 18 + Ant Design 5 + FastAPI + MySQL 8.0 + PostgreSQL 14 |
| **部署方式** | 全Docker化，一键启动 |
| **开发周期** | 18周（Phase 0-4） |
| **MVP交付** | Week 6：API测试完整闭环 |

### 1.2 项目组织结构

| 角色 | 职责 | 当前状态 |
|------|------|---------|
| **产品负责人(PO)** | 狼图腾OPC — 产品方向决策、功能优先级排序 | ✅ |
| **技术负责人(TL)** | WorkBuddy AI — 架构设计、技术选型、代码实现 | ✅ |
| **项目经理(PM)** | WorkBuddy AI（兼任） — 计划管理、文档管理、进度跟踪 | ✅ |

> 注：当前为单人项目模式，三个角色由狼图腾 + WorkBuddy AI 兼任。后续可扩展为团队。

---

## 二、阶段划分与文档产物清单

### 📋 文档目录结构

```
D:/TestPilot/docs/
├── product/        ← 产品文档
├── tech/           ← 技术文档
├── design/         ← 设计文档
├── ops/            ← 运维文档
├── manual/         ← 用户手册
├── management/     ← 项目管理文档（新增）
└── test/           ← 测试文档（新增）
```

### 📑 全量文档清单（按PM标准分类）

| 编号 | 文档名称 | 所属阶段 | 分类 | 状态 | 位置 |
|------|---------|---------|------|------|------|
| **D-01** | 项目章程 (Project Charter) | 启动 | management | 🔶 待创建 | docs/management/ |
| **D-02** | 项目执行计划 (PMP) | 启动 | management | ✅ 本文档 | docs/product/ |
| **D-03** | 产品需求规格说明书 (PRD) | 规划 | product | ✅ v4 | docs/product/ |
| **D-04** | 项目准备度评估 | 规划 | product | ✅ | docs/product/ |
| **D-05** | PRD对齐确认清单 | 规划 | product | ✅ | docs/product/ |
| **D-06** | MVP开发计划（详细到周） | 规划 | product | ✅ | docs/product/ |
| **D-07** | 技术需求文档 (TRD) | 规划 | tech | ✅ v4 | docs/tech/ |
| **D-08** | 业务流与架构流详解 | 规划 | tech | ✅ | docs/tech/ |
| **D-09** | 数据库ER图与表结构设计 | 规划 | tech | ✅ | docs/tech/ |
| **D-10** | 建表SQL完整脚本 | 规划 | tech | ✅ | sql/mysql/ |
| **D-11** | RESTful API接口设计 | 规划 | tech | ✅ | docs/tech/ |
| **D-12** | 菜单层级架构设计 | 规划 | design | ✅ | docs/design/ |
| **D-13** | 权限管理模块设计 | 规划 | design | ✅ | docs/design/ |
| **D-14** | 报表模块详细设计 | 规划 | design | ✅ | docs/design/ |
| **D-15** | UI自动化完整技术方案 | 规划 | tech | ✅ | docs/tech/ |
| **D-16** | 性能压测监控技术实现方案 | 规划 | tech | ✅ | docs/tech/ |
| **D-17** | Locust集成方案 | 规划 | tech | ✅ | docs/tech/ |
| **D-18** | API Mock Server方案 | 规划 | tech | ✅ | docs/tech/ |
| **D-19** | CI/CD集成完整方案 | 规划 | tech | ✅ | docs/tech/ |
| **D-20** | 任务执行与报告查看方案 | 规划 | tech | ✅ | docs/tech/ |
| **D-21** | 服务器监控深度架构 | 规划 | ops | ✅ | docs/ops/ |
| **D-22** | 原型文档 | 规划 | design | ✅ v4 | docs/design/ |
| **D-23** | UI风格说明（WebSphere企业风） | 规划 | design | ✅ | docs/design/ |
| **D-24** | 配置管理计划 | 规划 | management | 🔶 待创建 | docs/management/ |
| **D-25** | 风险管理计划 | 规划 | management | 🔶 待创建 | docs/management/ |
| **D-26** | 测试策略与测试计划 | 规划 | test | 🔶 待创建 | docs/test/ |
| **D-27** | Phase 0 阶段评审报告 | Phase 0 | management | 📅 Week 2 | docs/management/ |
| **D-28** | Phase 1 阶段评审报告 | Phase 1 | management | 📅 Week 6 | docs/management/ |
| **D-29** | 用户操作手册 | Phase 1+ | manual | 📅 Week 6 | docs/manual/ |
| **D-30** | Phase 2 阶段评审报告 | Phase 2 | management | 📅 Week 10 | docs/management/ |
| **D-31** | Phase 3 阶段评审报告 | Phase 3 | management | 📅 Week 14 | docs/management/ |
| **D-32** | Phase 4 阶段评审报告 | Phase 4 | management | 📅 Week 18 | docs/management/ |
| **D-33** | 运维部署方案 | Phase 4 | ops | 📅 Week 18 | docs/ops/ |
| **D-34** | 发布说明 (Release Notes) | Phase 4 | management | 📅 Week 18 | docs/management/ |
| **D-35** | README / LICENSE / CONTRIBUTING | Phase 0 | management | 🔶 待创建 | 项目根目录 |

> 状态说明：✅已完成 | 🔶 待创建 | 📅 计划产出

---

## 三、阶段执行计划

### Phase 0：启动 + 基础设施（Week 1-2）

```
目标：项目就绪，开发环境可用，用户可注册登录
输入：PRD v4、TRD v4、数据库设计、API设计
```

#### Phase 0 任务清单

| 编号 | 任务 | 优先级 | 预计耗时 | 状态 |
|------|------|--------|---------|------|
| P0-01 | 创建项目章程 | P0 | 0.5h | 🔶 |
| P0-02 | 创建配置管理计划 | P1 | 0.5h | 🔶 |
| P0-03 | 创建风险管理计划 | P1 | 0.5h | 🔶 |
| P0-04 | Git仓库初始化 + 远程连接 | P0 | 0.5h | 📅 |
| P0-05 | 创建 .gitignore / README / LICENSE | P0 | 0.5h | 🔶 |
| P0-06 | 搭建FastAPI项目骨架 | P0 | 1h | 📅 |
| P0-07 | 搭建React项目骨架 (Vite + AntD 5 + TypeScript) | P0 | 1h | 📅 |
| P0-08 | 编写 Docker Compose 全栈环境 | P0 | 0.5h | 📅 |
| P0-09 | 数据库迁移 (Alembic + 执行建表SQL) | P0 | 1h | 📅 |
| P0-10 | JWT认证 (注册/登录/刷新Token) | P0 | 2h | 📅 |
| P0-11 | 登录/注册页面 | P0 | 1h | 📅 |
| P0-12 | WebSphere风布局框架 (侧边栏+顶部栏+面包屑) | P0 | 1.5h | 📅 |
| P0-13 | 用户管理基础CRUD | P0 | 1.5h | 📅 |
| P0-14 | Phase 0 评审 + 提交 tag v0.1.0 | P0 | 0.5h | 📅 |

#### Phase 0 产出文档

| 文档 | 路径 |
|------|------|
| 项目章程 | docs/management/项目章程.md |
| 配置管理计划 | docs/management/配置管理计划.md |
| 风险管理计划 | docs/management/风险管理计划.md |
| README + LICENSE + .gitignore | 项目根目录 |
| Phase 0 阶段评审报告 | docs/management/phase-0-review.md |

#### Phase 0 里程碑

```
✅ docker compose up 一键启动全栈环境
✅ 浏览器打开 localhost:3000 看到登录页
✅ 注册/登录成功 → 进入WebSphere风工作台
✅ Git tag: v0.1.0
```

---

### Phase 1：MVP核心闭环（Week 3-6）

```
目标：API测试完整闭环可用
输入：Phase 0 产物
```

| 编号 | 任务 | 优先级 | 预计耗时 | 状态 |
|------|------|--------|---------|------|
| P1-01 | 团队CRUD (创建/编辑/删除/成员管理) | P0 | 1h | 📅 |
| P1-02 | 项目CRUD (创建/编辑/成员权限/归档) | P0 | 1h | 📅 |
| P1-03 | 项目仪表盘 (指标卡+趋势图+执行列表) | P0 | 1.5h | 📅 |
| P1-04 | API接口定义管理 (CRUD+目录树+环境变量) | P0 | 1.5h | 📅 |
| P1-05 | 测试用例CRUD (JSON步骤+断言+数据驱动) | P0 | 2h | 📅 |
| P1-06 | 测试计划管理 (用例选择+环境绑定) | P0 | 1h | 📅 |
| P1-07 | API执行引擎 (requests+断言+变量替换) | P0 | 2h | 📅 |
| P1-08 | 执行触发+执行记录列表 | P0 | 1h | 📅 |
| P1-09 | 执行结果详情 (请求/响应/日志) | P0 | 1h | 📅 |
| P1-10 | Allure报告生成+报告查看页 | P0 | 1.5h | 📅 |
| P1-11 | 测试策略与测试计划文档 | P1 | 1h | 📅 |
| P1-12 | 用户操作手册 (初稿) | P1 | 1h | 📅 |
| P1-13 | Phase 1 评审 + 提交 tag v0.2.0 | P0 | 0.5h | 📅 |

#### Phase 1 产出文档

| 文档 | 路径 |
|------|------|
| 测试策略与测试计划 | docs/test/测试策略与测试计划.md |
| 用户操作手册 (初稿) | docs/manual/用户操作手册.md |
| Phase 1 阶段评审报告 | docs/management/phase-1-review.md |

#### Phase 1 里程碑

```
✅ API测试完整闭环：项目→接口→用例→计划→执行→报告
✅ 演示环境可访问
✅ Git tag: v0.2.0
```

---

### Phase 2：AI集成（Week 7-10）

| 产出文档 | 路径 |
|---------|------|
| AI模块技术方案 | docs/tech/AI模块技术方案.md |
| Phase 2 阶段评审报告 | docs/management/phase-2-review.md |

**里程碑：Git tag v0.3.0**

---

### Phase 3：UI自动化+性能压测（Week 11-14）

| 产出文档 | 路径 |
|---------|------|
| Phase 3 阶段评审报告 | docs/management/phase-3-review.md |

**里程碑：Git tag v0.4.0**

---

### Phase 4：企业功能+发布（Week 15-18）

| 产出文档 | 路径 |
|---------|------|
| 运维部署方案 | docs/ops/运维部署方案.md |
| 用户操作手册 (终版) | docs/manual/用户操作手册.md |
| 发布说明 | docs/management/release-notes-v1.0.md |
| Phase 4 阶段评审报告 | docs/management/phase-4-review.md |
| 项目总结报告 | docs/management/项目总结报告.md |

**里程碑：Git tag v1.0.0 — 正式发布**

---

## 四、文档管理规范

### 4.1 文档命名规范

```
标准格式：{模块}-{文档类型}-v{版本号}.{扩展名}
示例：产品规格说明书-PRD-v4.md
     数据库ER图与表结构设计.md  （单版本不标版本号）
```

### 4.2 文档存放位置

| 分类 | 目录 | 包含文档 |
|------|------|---------|
| 产品文档 | `docs/product/` | PRD、准备度评估、PRD对齐清单、MVP计划 |
| 技术文档 | `docs/tech/` | TRD、架构流、数据库、API、各模块技术方案 |
| 设计文档 | `docs/design/` | 原型文档、菜单、权限、报表、UI风格 |
| 运维文档 | `docs/ops/` | 监控架构、部署方案 |
| 项目管理 | `docs/management/` | 章程、配置计划、风险计划、阶段评审报告 |
| 测试文档 | `docs/test/` | 测试策略、测试用例 |
| 用户手册 | `docs/manual/` | 用户操作手册 |

### 4.3 版本管理规则

| 规则 | 说明 |
|------|------|
| 版本号 | 重大改动升主版本(v3→v4)，小修改在原文件编辑 |
| 历史保留 | 旧版本保留在 docs/ 下，标注 -v3/-v4 后缀 |
| Git管理 | 所有文档纳入Git版本控制，变更记录在commit message |

### 4.4 文档评审节点

| 节点 | 时机 | 评审什么 |
|------|------|---------|
| **启动评审** | Phase 0 开始前 | 项目章程、PRD+TRD确认 |
| **Phase 0 评审** | Week 2 末 | 脚手架+认证+布局可用性 |
| **Phase 1 评审** | Week 6 末（MVP发布） | 功能完整性、性能表现 |
| **Phase 2 评审** | Week 10 末 | AI准确率、用户体验 |
| **Phase 3 评审** | Week 14 末 | 执行引擎稳定性、监控数据准确度 |
| **发布评审** | Week 18 末 | 整体准备度、安全审计、文档完整性 |

---

## 五、Git分支策略

```
main           ← 生产分支，只接受 PR 合并
  └── develop  ← 开发主分支
        ├── feature/p0-auth       ← Phase 0 认证
        ├── feature/p0-layout     ← Phase 0 布局
        ├── feature/p1-team       ← Phase 1 团队
        ├── feature/p1-project    ← Phase 1 项目
        ├── feature/p1-api-test   ← Phase 1 API测试
        ├── feature/p1-executor   ← Phase 1 执行引擎
        └── feature/p1-report     ← Phase 1 报告
```

- **分支命名**：`feature/phase-{功能}` 或 `fix/{问题描述}`
- **Commit 规范**：`{type}: {简短描述}`，type = feat / fix / docs / refactor / test / chore
- **Tag 规范**：`v{主版本}.{次版本}.{修订号}`，Phase 结束打tag

---

## 六、当前进度快照

```
🟢 规划阶段   ████████████████████ 100%  ← PRD/TRD/设计/架构全部完成
⚪ Phase 0    ░░░░░░░░░░░░░░░░░░░░   0%  ← 即将启动
⚪ Phase 1    ░░░░░░░░░░░░░░░░░░░░   0%
⚪ Phase 2    ░░░░░░░░░░░░░░░░░░░░   0%
⚪ Phase 3    ░░░░░░░░░░░░░░░░░░░░   0%
⚪ Phase 4    ░░░░░░░░░░░░░░░░░░░░   0%
```

---

## 七、立即执行清单

**本轮（今天）需要产出：**

| # | 产出 | 类型 | 目标位置 |
|---|------|------|---------|
| 1 | 项目章程 | 新建文档 | `docs/management/项目章程.md` |
| 2 | 配置管理计划 | 新建文档 | `docs/management/配置管理计划.md` |
| 3 | 风险管理计划 | 新建文档 | `docs/management/风险管理计划.md` |
| 4 | README.md | 新建文件 | `D:/TestPilot/README.md` |
| 5 | LICENSE (MIT) | 新建文件 | `D:/TestPilot/LICENSE` |
| 6 | .gitignore (Python+Node+Docker) | 新建文件 | `D:/TestPilot/.gitignore` |
| 7 | Git init + 远程连接 + 首次commit | 操作 | `D:/TestPilot/` |
| 8 | FastAPI项目骨架 | 代码 | `src/backend/` |
| 9 | React项目骨架 (Vite+AntD 5) | 代码 | `src/frontend/` |
| 10 | Docker Compose开发环境 | 配置 | `deploy/docker/docker-compose.dev.yml` |
| 11 | 创建缺失的docs子目录 | 操作 | `docs/management/` `docs/test/` `docs/manual/` |

---

> **本文档版本**：v1.0 | 最后更新：2026-06-17 13:50  
> **下次更新时机**：Phase 0 启动后每周一同步进度
