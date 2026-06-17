# TestPilot 🚀

> AI-Native 全栈自动化测试平台 — 让测试从手工重复劳动升级为 AI 驱动的智能质量保障。

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Status](https://img.shields.io/badge/status-Phase%200%20开发中-orange)]()

---

## 🎯 一句话介绍

一个对话框搞定从测试设计到执行分析的全流程，覆盖 API / Web UI / APP UI / 性能压测。

---

## ✨ 核心能力

| 模块 | 功能 | 状态 |
|------|------|------|
| 🔐 认证与权限 | JWT登录 + RBAC角色权限 | 🚧 Phase 0 |
| 📋 API测试 | 接口定义 → 用例 → 计划 → 执行 → 报告 | 🚧 Phase 1 |
| 🧠 AI增强 | 自然语言创建测试 + 失败根因分析 + 用例自愈 | 📅 Phase 2 |
| 🖥️ UI自动化 | Playwright (Web) + Appium (Mobile) | 📅 Phase 3 |
| ⚡ 性能压测 | Locust 分布式 + 三大监控大盘 | 📅 Phase 3 |
| 🔗 CI/CD | Jenkins / GitLab CI / GitHub Actions 集成 | 📅 Phase 4 |

---

## 🏗️ 技术栈

```
React 18 + TypeScript + Ant Design 5     ← 前端
FastAPI + Python 3.13                     ← 后端
MySQL 8.0 + PostgreSQL 14 + Redis 7       ← 数据存储
Docker Compose                            ← 部署
GitHub Actions                            ← CI/CD
```

---

## 🚀 快速启动

```bash
# 1. 克隆项目
git clone https://github.com/zftest/TestPilot.git
cd TestPilot

# 2. 一键启动全栈开发环境
cd deploy/docker
docker compose -f docker-compose.dev.yml up -d

# 3. 访问
# 前端: http://localhost:3000
# 后端API文档: http://localhost:8000/docs
```

---

## 📂 项目结构

```
TestPilot/
├── src/
│   ├── backend/          ← FastAPI 后端
│   └── frontend/         ← React 前端
├── sql/                  ← 数据库脚本
│   ├── mysql/            ← MySQL 建表
│   └── postgres/         ← PostgreSQL 建表
├── deploy/               ← 部署配置
│   └── docker/           ← Docker Compose
├── docs/                 ← 项目文档
│   ├── product/          ← 产品文档 (PRD等)
│   ├── tech/             ← 技术文档 (TRD/API/DB等)
│   ├── design/           ← 设计文档 (原型/菜单/权限)
│   ├── ops/              ← 运维文档 (监控/部署)
│   ├── management/       ← 项目管理 (章程/计划/评审)
│   ├── test/             ← 测试文档 (策略/计划)
│   └── manual/           ← 用户手册
└── prototypes/           ← UI原型文件
```

---

## 📋 开发路线图

| 阶段 | 时间 | 目标 | 标签 |
|------|------|------|------|
| **Phase 0** | Week 1-2 | 脚手架 + 认证 + 布局 | v0.1.0 |
| **Phase 1** | Week 3-6 | MVP: API测试完整闭环 | v0.2.0 |
| **Phase 2** | Week 7-10 | AI集成 (自然语言/失败分析) | v0.3.0 |
| **Phase 3** | Week 11-14 | UI自动化 + 性能压测 + 移动端 | v0.4.0 |
| **Phase 4** | Week 15-18 | 企业功能 + CI/CD + 正式发布 | v1.0.0 |

> 详见 [项目执行计划](docs/product/项目执行计划-PMP.md)

---

## 🤝 贡献指南

项目目前由 [狼图腾OPC](https://github.com/zftest) 单人开发。欢迎提 Issue 和 PR！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 提交 Pull Request

---

## 📄 开源协议

本项目采用 [MIT License](LICENSE)。

---

> **当前状态**: Phase 0 开发中 · 预计 MVP 交付: 2026-07-28
