# TestPilot CI/CD集成 · 完整方案

> 更新日期：2026-06-17 | 所属文档：TRD 补充章节

---

## 一、CI/CD集成架构总览

```
Git Push → CI Pipeline 触发 → TestPilot API 触发测试
                                    ↓
                  测试执行中（WebSocket实时推送）
                                    ↓
                  完成 → TestPilot 回调 CI → 质量门禁判定
                        ↓                        ↓
                   报告生成              ✅ 通过 → 继续部署
                                              ❌ 不通过 → 阻塞 + 通知
```

---

## 二、触发方式

| 方式 | 说明 | 配置 |
|------|------|------|
| **API触发** | CI Pipeline中调TestPilot REST API | 所有CI工具通用 |
| **Webhook触发** | Git Push自动触发测试 | GitHub/GitLab/Gitee |
| **定时触发** | Cron表达式定时执行回归 | 平台内配置 |
| **手动触发** | 平台上手动执行 | 平台UI操作 |

---

## 三、Jenkins Pipeline 完整配置

### 3.1 Jenkinsfile

```groovy
pipeline {
    agent any
    
    environment {
        TESTPILOT_HOST = 'https://testpilot.example.com'
        TESTPILOT_TOKEN = credentials('testpilot-api-token')
        PROJECT_ID = 'proj_001'
        PLAN_ID = 'plan_smoke'
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Deploy to Test Env') {
            steps {
                sh 'docker compose -f docker-compose.test.yml up -d'
                sh 'sleep 15'  // 等待服务就绪
            }
        }
        
        stage('Trigger TestPilot') {
            steps {
                script {
                    // 触发测试计划
                    def response = httpRequest(
                        url: "${TESTPILOT_HOST}/api/v1/executions",
                        httpMode: 'POST',
                        contentType: 'APPLICATION_JSON',
                        customHeaders: [[name: 'Authorization', value: "Bearer ${TESTPILOT_TOKEN}"]],
                        requestBody: groovy.json.JsonOutput.toJson([
                            project_id: PROJECT_ID,
                            plan_id: PLAN_ID,
                            trigger_type: 'ci_cd',
                            ci_info: [
                                job_name: env.JOB_NAME,
                                build_number: env.BUILD_NUMBER,
                                branch: env.GIT_BRANCH
                            ],
                            callback_url: "${env.BUILD_URL}"
                        ])
                    )
                    
                    def execData = readJSON text: response.content
                    env.EXECUTION_ID = execData.data.execution_id
                    
                    // 轮询等待执行完成（或使用回调模式）
                    timeout(time: 30, unit: 'MINUTES') {
                        waitUntil {
                            def statusResp = httpRequest(
                                url: "${TESTPILOT_HOST}/api/v1/executions/${env.EXECUTION_ID}",
                                customHeaders: [[name: 'Authorization', value: "Bearer ${TESTPILOT_TOKEN}"]]
                            )
                            def statusData = readJSON text: statusResp.content
                            def status = statusData.data.status
                            echo "Test execution status: ${status}"
                            return status in ['completed', 'failed', 'aborted']
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    def gateResp = httpRequest(
                        url: "${TESTPILOT_HOST}/api/v1/gates/check/${env.EXECUTION_ID}",
                        customHeaders: [[name: 'Authorization', value: "Bearer ${TESTPILOT_TOKEN}"]]
                    )
                    def gateData = readJSON text: gateResp.content
                    
                    if (!gateData.data.passed) {
                        error "质量门禁未通过: ${gateData.data.failures.join(', ')}"
                    }
                    echo "质量门禁通过！通过率: ${gateData.data.pass_rate}%"
                }
            }
        }
        
        stage('Deploy to Staging') {
            when { expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' } }
            steps {
                sh 'docker compose -f docker-compose.staging.yml up -d'
            }
        }
    }
    
    post {
        always {
            // 获取测试报告链接
            script {
                if (env.EXECUTION_ID) {
                    echo "测试报告: ${TESTPILOT_HOST}/reports/${env.EXECUTION_ID}"
                }
            }
        }
        failure {
            // 发送飞书通知
            sh '''
                curl -X POST https://open.feishu.cn/open-apis/bot/v2/hook/xxx \
                    -H "Content-Type: application/json" \
                    -d '{"msg_type":"text","content":{"text":"❌ 流水线失败: '${JOB_NAME}' #${BUILD_NUMBER}"}}'
            '''
        }
    }
}
```

---

## 四、GitLab CI 配置

### 4.1 .gitlab-ci.yml

```yaml
stages:
  - build
  - test
  - quality_gate
  - deploy

variables:
  TESTPILOT_HOST: "https://testpilot.example.com"
  TESTPILOT_TOKEN: $TESTPILOT_API_TOKEN  # GitLab CI变量

trigger_testpilot:
  stage: test
  image: curlimages/curl:latest
  script:
    - |
      EXECUTION_ID=$(curl -s -X POST "${TESTPILOT_HOST}/api/v1/executions" \
        -H "Authorization: Bearer ${TESTPILOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
          \"project_id\": \"proj_001\",
          \"plan_id\": \"plan_smoke\",
          \"trigger_type\": \"ci_cd\",
          \"ci_info\": {
            \"pipeline_id\": \"${CI_PIPELINE_ID}\",
            \"branch\": \"${CI_COMMIT_BRANCH}\",
            \"commit\": \"${CI_COMMIT_SHORT_SHA}\"
          },
          \"callback_url\": \"${CI_PIPELINE_URL}\"
        }" | jq -r '.data.execution_id')
      echo "EXECUTION_ID=${EXECUTION_ID}" >> testpilot.env
  artifacts:
    reports:
      dotenv: testpilot.env

wait_for_test:
  stage: test
  image: curlimages/curl:latest
  needs: ["trigger_testpilot"]
  script:
    - |
      for i in $(seq 1 60); do
        STATUS=$(curl -s "${TESTPILOT_HOST}/api/v1/executions/${EXECUTION_ID}" \
          -H "Authorization: Bearer ${TESTPILOT_TOKEN}" | jq -r '.data.status')
        echo "Status: ${STATUS}"
        if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
          break
        fi
        sleep 30
      done

quality_gate:
  stage: quality_gate
  image: curlimages/curl:latest
  needs: ["wait_for_test"]
  script:
    - |
      RESULT=$(curl -s "${TESTPILOT_HOST}/api/v1/gates/check/${EXECUTION_ID}" \
        -H "Authorization: Bearer ${TESTPILOT_TOKEN}")
      PASSED=$(echo $RESULT | jq -r '.data.passed')
      if [ "$PASSED" != "true" ]; then
        echo "质量门禁不通过"
        echo $RESULT | jq '.data.failures'
        exit 1
      fi
      echo "质量门禁通过！"

deploy_staging:
  stage: deploy
  needs: ["quality_gate"]
  script:
    - echo "部署到预发布环境"
  only:
    - main
```

---

## 五、GitHub Actions 配置

```yaml
name: TestPilot CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  trigger-testpilot:
    runs-on: ubuntu-latest
    outputs:
      execution_id: ${{ steps.trigger.outputs.execution_id }}
    steps:
      - name: Trigger TestPilot
        id: trigger
        run: |
          RESPONSE=$(curl -s -X POST "${{ secrets.TESTPILOT_HOST }}/api/v1/executions" \
            -H "Authorization: Bearer ${{ secrets.TESTPILOT_TOKEN }}" \
            -H "Content-Type: application/json" \
            -d '{
              "project_id": "proj_001",
              "plan_id": "plan_smoke",
              "trigger_type": "ci_cd",
              "ci_info": {
                "repo": "${{ github.repository }}",
                "branch": "${{ github.ref_name }}",
                "sha": "${{ github.sha }}",
                "run_id": "${{ github.run_id }}"
              },
              "callback_url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            }')
          echo "execution_id=$(echo $RESPONSE | jq -r '.data.execution_id')" >> $GITHUB_OUTPUT

  wait-and-gate:
    runs-on: ubuntu-latest
    needs: trigger-testpilot
    steps:
      - name: Wait and check quality gate
        run: |
          EXEC_ID="${{ needs.trigger-testpilot.outputs.execution_id }}"
          for i in $(seq 1 120); do
            STATUS=$(curl -s "${{ secrets.TESTPILOT_HOST }}/api/v1/executions/${EXEC_ID}" \
              -H "Authorization: Bearer ${{ secrets.TESTPILOT_TOKEN }}" | jq -r '.data.status')
            if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
              GATE=$(curl -s "${{ secrets.TESTPILOT_HOST }}/api/v1/gates/check/${EXEC_ID}" \
                -H "Authorization: Bearer ${{ secrets.TESTPILOT_TOKEN }}")
              PASSED=$(echo $GATE | jq -r '.data.passed')
              if [ "$PASSED" != "true" ]; then
                echo "Quality gate failed!"
                exit 1
              fi
              echo "Quality gate passed!"
              exit 0
            fi
            sleep 30
          done
          echo "Timeout waiting for test execution"
          exit 1
```

---

## 六、CI/CD集成UI（平台内）

### 6.1 CI/CD配置页

| 配置项 | 内容 |
|--------|------|
| API Token管理 | 生成/吊销CI专用Token，可设有效期和权限范围 |
| Webhook URL | 自动生成唯一Webhook URL，配置到Git平台 |
| Pipeline模板 | 提供Jenkins/GitLab CI/GitHub Actions一键复制模板 |
| 回调配置 | 配置测试完成后的回调URL |
| 通知渠道 | 选择飞书/企微/钉钉/邮件通知 |

### 6.2 CI/CD执行历史

在平台内可查看所有由CI/CD触发的执行记录，包括来源Pipeline链接。
