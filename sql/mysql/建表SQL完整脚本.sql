-- ============================================================
-- TestPilot 自动化测试平台 · 完整建表SQL脚本
-- 版本：v3.0 | 日期：2026-06-17
-- 数据库：MySQL 8.0（业务库）+ PostgreSQL 14（分析库）
-- ============================================================

-- ============================================================
-- 第一部分：MySQL 8.0 业务库 (testops_core)
-- ============================================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS testops_core
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE testops_core;

-- -----------------------------------------------------------
-- 1. 用户与权限模块（5张表）
-- -----------------------------------------------------------

-- 1.1 用户表
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(64) NOT NULL COMMENT '登录用户名，唯一',
  `email` VARCHAR(255) NOT NULL COMMENT '邮箱，唯一',
  `password_hash` VARCHAR(255) NOT NULL COMMENT 'bcrypt加密',
  `display_name` VARCHAR(64) NOT NULL COMMENT '显示名称',
  `avatar_url` VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
  `department` VARCHAR(128) DEFAULT NULL COMMENT '部门',
  `status` ENUM('active','disabled','pending') NOT NULL DEFAULT 'active' COMMENT '账户状态',
  `login_fail_count` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '连续登录失败次数',
  `locked_until` DATETIME DEFAULT NULL COMMENT '锁定截止时间',
  `last_login_at` DATETIME DEFAULT NULL,
  `last_login_ip` VARCHAR(45) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_email` (`email`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 1.2 角色表（RBAC）
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL COMMENT '角色名称',
  `code` VARCHAR(64) NOT NULL COMMENT '角色编码(super_admin/admin/pm/tester/viewer)',
  `description` VARCHAR(255) DEFAULT NULL,
  `is_system` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否系统内置角色',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

-- 1.3 权限表
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(128) NOT NULL COMMENT '权限名称',
  `code` VARCHAR(128) NOT NULL COMMENT '权限编码(resource:action)',
  `resource` VARCHAR(64) NOT NULL COMMENT '资源模块',
  `action` VARCHAR(64) NOT NULL COMMENT '操作类型(create/read/update/delete/execute)',
  `description` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_resource` (`resource`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限表';

-- 1.4 角色-权限关联表
DROP TABLE IF EXISTS `role_permissions`;
CREATE TABLE `role_permissions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id` BIGINT UNSIGNED NOT NULL,
  `permission_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_perm` (`role_id`,`permission_id`),
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rp_perm` FOREIGN KEY (`permission_id`) REFERENCES `permissions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色-权限关联表';

-- 1.5 用户-角色关联表
DROP TABLE IF EXISTS `user_roles`;
CREATE TABLE `user_roles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `role_id` BIGINT UNSIGNED NOT NULL,
  `granted_by` BIGINT UNSIGNED DEFAULT NULL COMMENT '授权人',
  `granted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_role` (`user_id`,`role_id`),
  CONSTRAINT `fk_ur_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ur_role` FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户-角色关联表';

-- -----------------------------------------------------------
-- 2. 团队与项目管理（4张表）
-- -----------------------------------------------------------

-- 2.1 团队表
DROP TABLE IF EXISTS `teams`;
CREATE TABLE `teams` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(128) NOT NULL COMMENT '团队名称',
  `slug` VARCHAR(128) NOT NULL COMMENT 'URL友好标识',
  `description` VARCHAR(500) DEFAULT NULL,
  `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '团队所有者',
  `avatar_url` VARCHAR(500) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_slug` (`slug`),
  KEY `idx_owner` (`owner_id`),
  CONSTRAINT `fk_teams_owner` FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='团队表';

-- 2.2 团队成员表
DROP TABLE IF EXISTS `team_members`;
CREATE TABLE `team_members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `team_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('owner','admin','member','guest') NOT NULL DEFAULT 'member' COMMENT '团队内角色',
  `joined_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_team_user` (`team_id`,`user_id`),
  CONSTRAINT `fk_tm_team` FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tm_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='团队成员关系表';

-- 2.3 项目表
DROP TABLE IF EXISTS `projects`;
CREATE TABLE `projects` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `team_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL COMMENT '项目名称',
  `key` VARCHAR(16) NOT NULL COMMENT '项目标识(如 TP-AUTH)',
  `description` TEXT DEFAULT NULL,
  `status` ENUM('planning','active','paused','archived') NOT NULL DEFAULT 'active',
  `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '项目负责人',
  `visibility` ENUM('private','team','public') NOT NULL DEFAULT 'team' COMMENT '可见性',
  `config_json` JSON DEFAULT NULL COMMENT '项目配置(环境/变量/集成设置)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_team_key` (`team_id`,`key`),
  KEY `idx_team` (`team_id`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目表';

-- 2.4 项目成员表
DROP TABLE IF EXISTS `project_members`;
CREATE TABLE `project_members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('owner','admin','editor','viewer') NOT NULL DEFAULT 'editor' COMMENT '项目内角色',
  `joined_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_user` (`project_id`,`user_id`),
  CONSTRAINT `fk_pm_project` FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pm_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目成员表';

-- -----------------------------------------------------------
-- 3. 需求与测试用例管理（5张表）
-- -----------------------------------------------------------

-- 3.1 需求表
DROP TABLE IF EXISTS `requirements`;
CREATE TABLE `requirements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `title` VARCHAR(255) NOT NULL COMMENT '需求标题',
  `description` TEXT DEFAULT NULL COMMENT '需求描述',
  `source_type` ENUM('manual','ai_parsed','jira','tapd','pdf') DEFAULT 'manual' COMMENT '来源类型',
  `source_id` VARCHAR(128) DEFAULT NULL COMMENT '外部系统ID',
  `status` ENUM('draft','reviewing','approved','covered','done') DEFAULT 'draft',
  `priority` ENUM('low','medium','high','critical') DEFAULT 'medium',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`status`),
  KEY `idx_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='需求表';

-- 3.2 需求-用例追溯表
DROP TABLE IF EXISTS `requirement_case_traces`;
CREATE TABLE `requirement_case_traces` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `requirement_id` BIGINT UNSIGNED NOT NULL,
  `case_id` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_req_case` (`requirement_id`,`case_id`),
  CONSTRAINT `fk_rct_req` FOREIGN KEY (`requirement_id`) REFERENCES `requirements`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='需求-用例追溯表';

-- 3.3 用例目录表
DROP TABLE IF EXISTS `case_folders`;
CREATE TABLE `case_folders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '父目录ID，NULL为根目录',
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_parent` (`parent_id`),
  CONSTRAINT `fk_cf_parent` FOREIGN KEY (`parent_id`) REFERENCES `case_folders`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用例目录表';

-- 3.4 测试用例表（核心表）
DROP TABLE IF EXISTS `test_cases`;
CREATE TABLE `test_cases` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `title` VARCHAR(255) NOT NULL COMMENT '用例标题',
  `case_type` ENUM('api','ui_web','ui_mobile','performance','integration') NOT NULL COMMENT '用例类型',
  `priority` ENUM('p0','p1','p2','p3') NOT NULL DEFAULT 'p1',
  `status` ENUM('draft','ready','deprecated') NOT NULL DEFAULT 'draft',
  `description` TEXT DEFAULT NULL COMMENT '用例描述/前置条件',
  `precondition` TEXT DEFAULT NULL COMMENT '前置条件',
  `steps_json` JSON NOT NULL COMMENT '测试步骤(结构化JSON)',
  `assertions_json` JSON NOT NULL COMMENT '断言列表',
  `tags_json` JSON DEFAULT NULL COMMENT '标签数组',
  `data_json` JSON DEFAULT NULL COMMENT '测试数据/参数化',
  `folder_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '所属目录',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `ai_generated` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否AI生成',
  `ai_confidence` DECIMAL(3,2) DEFAULT NULL COMMENT 'AI置信度 0.00-1.00',
  `version` INT NOT NULL DEFAULT 1 COMMENT '用例版本号',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project_type` (`project_id`,`case_type`),
  KEY `idx_status` (`status`),
  KEY `idx_folder` (`folder_id`),
  KEY `idx_created_by` (`created_by`),
  CONSTRAINT `fk_tc_folder` FOREIGN KEY (`folder_id`) REFERENCES `case_folders`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测试用例表';

-- 3.5 API接口定义表
DROP TABLE IF EXISTS `api_endpoints`;
CREATE TABLE `api_endpoints` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL COMMENT '接口名称',
  `method` ENUM('GET','POST','PUT','DELETE','PATCH','HEAD','OPTIONS') NOT NULL,
  `path` VARCHAR(2000) NOT NULL COMMENT '接口路径(支持变量)',
  `headers_json` JSON DEFAULT NULL COMMENT '请求头',
  `query_params_json` JSON DEFAULT NULL COMMENT 'Query参数',
  `body_json` JSON DEFAULT NULL COMMENT '请求体示例',
  `auth_config_json` JSON DEFAULT NULL COMMENT '认证配置',
  `tags_json` JSON DEFAULT NULL COMMENT '标签',
  `folder_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '所属目录',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_folder` (`folder_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='API接口定义表';

-- -----------------------------------------------------------
-- 4. UI自动化专用表（3张表）
-- -----------------------------------------------------------

-- 4.1 PO页面对象表
DROP TABLE IF EXISTS `page_objects`;
CREATE TABLE `page_objects` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL COMMENT '页面对象名称',
  `platform` ENUM('web','android','ios','miniprogram') NOT NULL DEFAULT 'web' COMMENT '平台',
  `base_url` VARCHAR(500) DEFAULT NULL COMMENT '页面基础URL',
  `url_pattern` VARCHAR(500) DEFAULT NULL COMMENT 'URL匹配模式',
  `description` TEXT DEFAULT NULL,
  `parent_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '继承的父PO',
  `code_snippet` TEXT DEFAULT NULL COMMENT '生成的代码片段',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_platform` (`platform`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PO页面对象表';

-- 4.2 UI元素表
DROP TABLE IF EXISTS `ui_elements`;
CREATE TABLE `ui_elements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `page_object_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL COMMENT '元素名称(如login_button)',
  `element_type` ENUM('button','input','link','text','select','checkbox','radio','table','image','custom') NOT NULL DEFAULT 'custom',
  `locator_strategy` ENUM('id','css','xpath','name','class_name','tag_name','text','accessibility_id','image') NOT NULL DEFAULT 'css' COMMENT '定位策略',
  `locator_value` VARCHAR(2000) NOT NULL COMMENT '定位值',
  `fallback_locators_json` JSON DEFAULT NULL COMMENT '备用定位策略数组',
  `action_type` ENUM('click','fill','select','check','hover','wait','assert','scroll','screenshot','custom') NOT NULL DEFAULT 'click',
  `action_value` VARCHAR(500) DEFAULT NULL COMMENT '操作参数(如输入值)',
  `description` TEXT DEFAULT NULL,
  `is_dynamic` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否动态元素',
  `ai_suggested` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否AI建议',
  `ai_confidence` DECIMAL(3,2) DEFAULT NULL,
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_page_object` (`page_object_id`),
  KEY `idx_strategy` (`locator_strategy`),
  CONSTRAINT `fk_ue_po` FOREIGN KEY (`page_object_id`) REFERENCES `page_objects`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='UI元素表';

-- 4.3 测试关键字表
DROP TABLE IF EXISTS `test_keywords`;
CREATE TABLE `test_keywords` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL COMMENT '关键字名称(login/user/create_order)',
  `category` VARCHAR(64) DEFAULT NULL COMMENT '分类(login/data/assertion/navigation)',
  `description` TEXT DEFAULT NULL,
  `params_json` JSON DEFAULT NULL COMMENT '参数定义',
  `steps_json` JSON NOT NULL COMMENT '关键字内部步骤',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测试关键字表';

-- -----------------------------------------------------------
-- 5. 测试执行模块（4张表）
-- -----------------------------------------------------------

-- 5.1 测试计划表
DROP TABLE IF EXISTS `test_plans`;
CREATE TABLE `test_plans` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL COMMENT '计划名称',
  `description` TEXT DEFAULT NULL,
  `plan_type` ENUM('smoke','regression','full','custom') NOT NULL DEFAULT 'custom',
  `case_ids_json` JSON NOT NULL COMMENT '关联用例ID数组',
  `env_config_json` JSON DEFAULT NULL COMMENT '环境配置',
  `schedule_type` ENUM('manual','cron','webhook','ci_cd') DEFAULT 'manual',
  `schedule_config_json` JSON DEFAULT NULL COMMENT '调度配置(cron/hook URL)',
  `status` ENUM('draft','active','paused','archived') DEFAULT 'draft',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测试计划表';

-- 5.2 测试环境表
DROP TABLE IF EXISTS `test_environments`;
CREATE TABLE `test_environments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL COMMENT '环境名称(dev/staging/prod)',
  `base_url` VARCHAR(500) NOT NULL COMMENT '基础URL',
  `variables_json` JSON DEFAULT NULL COMMENT '环境变量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_env` (`project_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测试环境表';

-- 5.3 测试执行记录表
DROP TABLE IF EXISTS `test_runs`;
CREATE TABLE `test_runs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `plan_id` BIGINT UNSIGNED DEFAULT NULL,
  `env_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '执行环境',
  `name` VARCHAR(255) NOT NULL COMMENT '执行名称',
  `run_type` ENUM('manual','schedule','ci_cd','api') NOT NULL DEFAULT 'manual',
  `run_mode` ENUM('sequential','parallel','distributed') NOT NULL DEFAULT 'parallel' COMMENT '执行模式',
  `trigger_source` VARCHAR(128) DEFAULT NULL COMMENT '触发来源(Git Hash/流水线)',
  `status` ENUM('queued','running','passed','failed','canceled','error') NOT NULL DEFAULT 'queued',
  `triggered_by` BIGINT UNSIGNED DEFAULT NULL,
  `started_at` DATETIME DEFAULT NULL,
  `finished_at` DATETIME DEFAULT NULL,
  `duration_ms` BIGINT DEFAULT NULL,
  `total_cases` INT NOT NULL DEFAULT 0,
  `passed_count` INT NOT NULL DEFAULT 0,
  `failed_count` INT NOT NULL DEFAULT 0,
  `skipped_count` INT NOT NULL DEFAULT 0,
  `error_count` INT NOT NULL DEFAULT 0,
  `pass_rate` DECIMAL(5,2) DEFAULT NULL COMMENT '通过率%',
  `report_url` VARCHAR(500) DEFAULT NULL,
  `retry_count` INT NOT NULL DEFAULT 0 COMMENT '失败重试次数',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_plan` (`plan_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_tr_env` FOREIGN KEY (`env_id`) REFERENCES `test_environments`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测试执行记录表';

-- 5.4 用例执行结果表
DROP TABLE IF EXISTS `test_results`;
CREATE TABLE `test_results` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_id` BIGINT UNSIGNED NOT NULL,
  `case_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('passed','failed','skipped','error','running') NOT NULL,
  `duration_ms` INT DEFAULT NULL COMMENT '执行耗时(ms)',
  `retry_attempt` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '重试次数',
  `error_message` TEXT DEFAULT NULL COMMENT '错误摘要',
  `stack_trace` TEXT DEFAULT NULL COMMENT '完整堆栈',
  `screenshot_url` VARCHAR(500) DEFAULT NULL COMMENT '失败截图URL',
  `video_url` VARCHAR(500) DEFAULT NULL COMMENT '执行录屏URL',
  `request_log_json` JSON DEFAULT NULL COMMENT 'API请求/响应日志',
  `ai_analysis_json` JSON DEFAULT NULL COMMENT 'AI失败根因分析结果',
  `executed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_run` (`run_id`),
  KEY `idx_case` (`case_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_results_run` FOREIGN KEY (`run_id`) REFERENCES `test_runs`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测试用例执行结果表';

-- -----------------------------------------------------------
-- 6. 性能压测模块（3张表）
-- -----------------------------------------------------------

-- 6.1 性能场景表
DROP TABLE IF EXISTS `perf_scenarios`;
CREATE TABLE `perf_scenarios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL COMMENT '场景名称',
  `description` TEXT DEFAULT NULL,
  `test_type` ENUM('single_interface','multi_interface','link_tracing','stability','spike') NOT NULL COMMENT '测试类型',
  `config_json` JSON NOT NULL COMMENT '压测配置(并发数/持续时间/ramp-up/think-time)',
  `target_endpoints_json` JSON NOT NULL COMMENT '目标接口数组',
  `assertion_json` JSON DEFAULT NULL COMMENT '性能断言(QPS>=X, RT<=Y)',
  `status` ENUM('draft','ready','archived') DEFAULT 'draft',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_type` (`test_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='性能测试场景表';

-- 6.2 性能执行记录表
DROP TABLE IF EXISTS `perf_runs`;
CREATE TABLE `perf_runs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `scenario_id` BIGINT UNSIGNED NOT NULL,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('queued','running','ramping','steady','passed','failed','canceled') NOT NULL DEFAULT 'queued',
  `started_at` DATETIME DEFAULT NULL,
  `finished_at` DATETIME DEFAULT NULL,
  `duration_seconds` INT DEFAULT NULL COMMENT '实际执行时长(s)',
  `target_users` INT NOT NULL COMMENT '目标并发数',
  `peak_qps` DECIMAL(10,2) DEFAULT NULL COMMENT '峰值QPS',
  `avg_rt_ms` DECIMAL(10,2) DEFAULT NULL COMMENT '平均响应时间(ms)',
  `p99_rt_ms` DECIMAL(10,2) DEFAULT NULL COMMENT 'P99响应时间(ms)',
  `error_rate` DECIMAL(5,4) DEFAULT NULL COMMENT '错误率',
  `config_snapshot_json` JSON NOT NULL COMMENT '执行时配置快照',
  `triggered_by` BIGINT UNSIGNED DEFAULT NULL,
  `report_url` VARCHAR(500) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_scenario` (`scenario_id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='性能测试执行记录表';

-- 6.3 性能监控指标表（MySQL侧缓存，主存储PG）
DROP TABLE IF EXISTS `perf_metrics_cache`;
CREATE TABLE `perf_metrics_cache` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `perf_run_id` BIGINT UNSIGNED NOT NULL,
  `timestamp_ms` BIGINT NOT NULL COMMENT '采集时间戳(ms)',
  `metric_type` ENUM('qps','rt','error_rate','concurrency','throughput') NOT NULL,
  `endpoint_name` VARCHAR(255) DEFAULT NULL COMMENT '接口名称',
  `metric_value` DECIMAL(12,4) NOT NULL,
  `labels_json` JSON DEFAULT NULL COMMENT '额外标签',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_run_metric` (`perf_run_id`,`metric_type`),
  KEY `idx_timestamp` (`timestamp_ms`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='性能监控指标缓存表(主存储在PG)';

-- -----------------------------------------------------------
-- 7. 报告与缺陷模块（2张表）
-- -----------------------------------------------------------

-- 7.1 缺陷表
DROP TABLE IF EXISTS `defects`;
CREATE TABLE `defects` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `severity` ENUM('critical','high','medium','low') NOT NULL DEFAULT 'medium',
  `status` ENUM('open','confirmed','in_progress','resolved','closed','wont_fix') DEFAULT 'open',
  `related_run_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '关联执行ID',
  `related_case_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '关联用例ID',
  `assigned_to` BIGINT UNSIGNED DEFAULT NULL,
  `external_id` VARCHAR(128) DEFAULT NULL COMMENT 'Jira/TAPD缺陷ID',
  `external_url` VARCHAR(500) DEFAULT NULL,
  `created_by` BIGINT UNSIGNED NOT NULL,
  `resolved_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`status`),
  KEY `idx_severity` (`severity`),
  KEY `idx_assigned` (`assigned_to`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='缺陷记录表';

-- 7.2 测试报告表
DROP TABLE IF EXISTS `test_reports`;
CREATE TABLE `test_reports` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT UNSIGNED NOT NULL,
  `run_id` BIGINT UNSIGNED NOT NULL COMMENT '关联执行ID',
  `title` VARCHAR(255) NOT NULL,
  `report_type` ENUM('execution','performance','trend','custom') NOT NULL DEFAULT 'execution',
  `summary_json` JSON NOT NULL COMMENT '报告摘要数据',
  `html_url` VARCHAR(500) DEFAULT NULL COMMENT 'Allure等静态报告URL',
  `generated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_run` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测试报告表';

-- -----------------------------------------------------------
-- 8. 系统与审计模块（2张表）
-- -----------------------------------------------------------

-- 8.1 操作审计日志
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED DEFAULT NULL,
  `action` VARCHAR(128) NOT NULL COMMENT '操作类型(user.login/case.create/plan.execute)',
  `resource_type` VARCHAR(64) NOT NULL COMMENT '资源类型',
  `resource_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '资源ID',
  `detail_json` JSON DEFAULT NULL COMMENT '变更详情',
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(500) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作审计日志表';

-- 8.2 系统配置表
DROP TABLE IF EXISTS `system_configs`;
CREATE TABLE `system_configs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `config_key` VARCHAR(128) NOT NULL COMMENT '配置键',
  `config_value` TEXT NOT NULL COMMENT '配置值',
  `value_type` ENUM('string','int','bool','json') NOT NULL DEFAULT 'string',
  `description` VARCHAR(255) DEFAULT NULL,
  `updated_by` BIGINT UNSIGNED DEFAULT NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- ============================================================
-- 第二部分：PostgreSQL 14 分析库 (testops_analytics)
-- ============================================================

-- 执行结果明细宽表
DROP TABLE IF EXISTS test_results_detail;
CREATE TABLE test_results_detail (
  id BIGSERIAL PRIMARY KEY,
  run_id BIGINT NOT NULL,
  case_id BIGINT NOT NULL,
  project_id BIGINT NOT NULL,
  case_type VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  duration_ms INT,
  retry_attempt SMALLINT DEFAULT 0,
  error_category VARCHAR(64) COMMENT 'AI分类: timeout/assertion/element_not_found/network/api_error',
  executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  env_name VARCHAR(64),
  executor_host VARCHAR(128),
  tags JSONB DEFAULT '[]'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_trd_project_time ON test_results_detail(project_id, executed_at);
CREATE INDEX idx_trd_case_type ON test_results_detail(case_type);
CREATE INDEX idx_trd_status ON test_results_detail(status);
CREATE INDEX idx_trd_tags ON test_results_detail USING GIN(tags);
CREATE INDEX idx_trd_error_cat ON test_results_detail(error_category) WHERE error_category IS NOT NULL;

-- 性能指标时序数据表（需安装TimescaleDB扩展）
DROP TABLE IF EXISTS perf_metrics;
CREATE TABLE perf_metrics (
  time TIMESTAMPTZ NOT NULL,
  perf_run_id BIGINT NOT NULL,
  scenario_id BIGINT NOT NULL,
  project_id BIGINT NOT NULL,
  metric_name VARCHAR(64) NOT NULL,
  metric_value DOUBLE PRECISION NOT NULL,
  endpoint_name VARCHAR(255),
  labels_json JSONB DEFAULT '{}'::jsonb,
  PRIMARY KEY (time, perf_run_id, metric_name)
);
-- 需要执行: SELECT create_hypertable('perf_metrics', 'time', chunk_time_interval => INTERVAL '1 day');
-- 压缩策略: SELECT add_compression_policy('perf_metrics', INTERVAL '7 days');

CREATE INDEX idx_pm_run ON perf_metrics(perf_run_id);
CREATE INDEX idx_pm_scenario ON perf_metrics(scenario_id, metric_name, time);

-- AI分析历史表
DROP TABLE IF EXISTS ai_analysis_log;
CREATE TABLE ai_analysis_log (
  id BIGSERIAL PRIMARY KEY,
  run_id BIGINT,
  result_id BIGINT,
  project_id BIGINT NOT NULL,
  analysis_type VARCHAR(64) NOT NULL COMMENT 'failure_root_cause/case_suggestion/risk_prediction/performance_bottleneck',
  input_text TEXT,
  output_json JSONB NOT NULL,
  model_name VARCHAR(64),
  model_version VARCHAR(32),
  tokens_used INT,
  confidence_score DOUBLE PRECISION,
  feedback_score SMALLINT COMMENT '用户反馈评分 1-5',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_aal_project ON ai_analysis_log(project_id, created_at);
CREATE INDEX idx_aal_type ON ai_analysis_log(analysis_type);

-- ============================================================
-- 第三部分：初始种子数据
-- ============================================================

-- 3.1 系统内置角色
INSERT INTO roles (name, code, description, is_system) VALUES
('超级管理员', 'super_admin', '系统级管理员，拥有所有权限', 1),
('管理员', 'admin', '团队/项目管理权限', 1),
('项目经理', 'pm', '项目管理与报告查看权限', 1),
('测试工程师', 'tester', '测试用例设计、执行权限', 1),
('观察者', 'viewer', '只读权限', 1);

-- 3.2 系统权限（资源:操作 格式）
INSERT INTO permissions (name, code, resource, action, description) VALUES
('创建项目', 'project:create', 'project', 'create', '创建新项目'),
('查看项目', 'project:read', 'project', 'read', '查看项目详情'),
('编辑项目', 'project:update', 'project', 'update', '修改项目配置'),
('删除项目', 'project:delete', 'project', 'delete', '删除项目'),
('创建用例', 'case:create', 'case', 'create', '创建测试用例'),
('编辑用例', 'case:update', 'case', 'update', '编辑测试用例'),
('删除用例', 'case:delete', 'case', 'delete', '删除测试用例'),
('执行测试', 'execution:execute', 'execution', 'execute', '触发测试执行'),
('查看报告', 'report:read', 'report', 'read', '查看测试报告'),
('管理用户', 'user:manage', 'user', 'update', '管理用户账号'),
('管理角色', 'role:manage', 'role', 'update', '管理角色与权限'),
('系统配置', 'system:config', 'system', 'update', '修改系统配置');

-- 3.3 系统配置初始值
INSERT INTO system_configs (config_key, config_value, value_type, description) VALUES
('max_concurrent_runs', '10', 'int', '最大并发执行数'),
('execution_timeout_minutes', '120', 'int', '单次执行超时(分钟)'),
('retry_max_attempts', '3', 'int', '失败重试最大次数'),
('screenshot_on_failure', 'true', 'bool', '失败时自动截图'),
('ai_analysis_enabled', 'true', 'bool', '启用AI分析'),
('registraion_open', 'true', 'bool', '开放注册'),
('default_language', 'zh-CN', 'string', '默认语言');

-- 3.4 创建初始管理员用户（密码: Admin@123，bcrypt加密）
INSERT INTO users (username, email, password_hash, display_name, status) VALUES
('admin', 'admin@testpilot.io', '$2b$12$LJ3m4ys3Lk0TSwHCpZmjYuGkQKqHRRGdBjOFsUqpGCMR5NlHjJR6a', '系统管理员', 'active');

-- 分配超级管理员角色
INSERT INTO user_roles (user_id, role_id, granted_by) 
SELECT u.id, r.id, u.id FROM users u, roles r 
WHERE u.username = 'admin' AND r.code = 'super_admin';
