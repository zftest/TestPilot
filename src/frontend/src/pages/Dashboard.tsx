import { Card, Col, Row, Statistic, Table, Tag } from "antd";
import {
  ApiOutlined,
  BugOutlined,
  CheckCircleOutlined,
  ThunderboltOutlined,
} from "@ant-design/icons";

const recentRuns = [
  { key: "1", name: "登录模块回归", status: "passed", time: "2分钟前", duration: "32s" },
  { key: "2", name: "订单API测试", status: "failed", time: "15分钟前", duration: "1m12s" },
  { key: "3", name: "用户模块冒烟", status: "passed", time: "1小时前", duration: "45s" },
  { key: "4", name: "支付接口联调", status: "running", time: "正在执行", duration: "-" },
];

const statusColor: Record<string, string> = {
  passed: "green",
  failed: "red",
  running: "blue",
};

export default function DashboardPage() {
  return (
    <div>
      <h2 style={{ marginBottom: 24, fontSize: 20 }}>📊 项目仪表盘</h2>

      {/* 指标卡片 */}
      <Row gutter={16} style={{ marginBottom: 24 }}>
        <Col span={6}>
          <Card>
            <Statistic
              title="今日执行次数"
              value={128}
              prefix={<ThunderboltOutlined />}
              valueStyle={{ color: "#1677ff" }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="通过率"
              value={94.5}
              suffix="%"
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: "#52c41a" }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="活跃项目"
              value={8}
              prefix={<ApiOutlined />}
              valueStyle={{ color: "#722ed1" }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="待修复缺陷"
              value={3}
              prefix={<BugOutlined />}
              valueStyle={{ color: "#ff4d4f" }}
            />
          </Card>
        </Col>
      </Row>

      {/* 最近运行 */}
      <Card title="最近执行记录" style={{ marginBottom: 24 }}>
        <Table
          dataSource={recentRuns}
          pagination={false}
          columns={[
            { title: "任务名称", dataIndex: "name", key: "name" },
            {
              title: "状态",
              dataIndex: "status",
              key: "status",
              render: (s: string) => (
                <Tag color={statusColor[s] || "default"}>{s.toUpperCase()}</Tag>
              ),
            },
            { title: "执行时间", dataIndex: "time", key: "time" },
            { title: "耗时", dataIndex: "duration", key: "duration" },
          ]}
        />
      </Card>

      {/* 快速入口 */}
      <Card title="快速入口">
        <Row gutter={16}>
          {[
            { color: "#1677ff", label: "API 测试", icon: <ApiOutlined /> },
            { color: "#52c41a", label: "Web UI 测试", icon: <BugOutlined /> },
            { color: "#722ed1", label: "性能压测", icon: <ThunderboltOutlined /> },
            { color: "#fa8c16", label: "测试报告", icon: <CheckCircleOutlined /> },
          ].map((item) => (
            <Col span={6} key={item.label}>
              <div
                className="dashboard-card"
                style={{ cursor: "pointer" }}
                onClick={() => {}}
              >
                <div style={{ fontSize: 32, color: item.color }}>{item.icon}</div>
                <div className="label" style={{ marginTop: 12 }}>
                  {item.label}
                </div>
              </div>
            </Col>
          ))}
        </Row>
      </Card>
    </div>
  );
}
