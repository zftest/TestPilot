import { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { Layout, Menu, Button, Dropdown, Avatar, Breadcrumb } from "antd";
import type { MenuProps } from "antd";
import {
  DashboardOutlined,
  ApiOutlined,
  ThunderboltOutlined,
  BugOutlined,
  FileTextOutlined,
  SettingOutlined,
  TeamOutlined,
  ProjectOutlined,
  BarChartOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  LogoutOutlined,
  UserOutlined,
} from "@ant-design/icons";
import { useAuthStore } from "../stores/authStore";

const { Sider, Content, Header } = Layout;

// ── WebSphere 风格菜单：9个一级菜单骨架 ──
const menuItems: MenuProps["items"] = [
  { key: "/dashboard", icon: <DashboardOutlined />, label: "仪表盘" },
  { key: "/projects", icon: <ProjectOutlined />, label: "项目管理" },
  { key: "/api-test", icon: <ApiOutlined />, label: "API 测试" },
  { key: "/ui-test", icon: <BugOutlined />, label: "Web UI 测试" },
  { key: "/perf-test", icon: <ThunderboltOutlined />, label: "性能压测" },
  { key: "/reports", icon: <FileTextOutlined />, label: "测试报告" },
  { key: "/analytics", icon: <BarChartOutlined />, label: "数据分析" },
  { key: "/users", icon: <TeamOutlined />, label: "用户管理" },
  { key: "/settings", icon: <SettingOutlined />, label: "系统设置" },
];

// 面包屑映射
const breadcrumbMap: Record<string, string> = {
  "/dashboard": "仪表盘",
  "/projects": "项目管理",
  "/api-test": "API 测试",
  "/ui-test": "Web UI 测试",
  "/perf-test": "性能压测",
  "/reports": "测试报告",
  "/analytics": "数据分析",
  "/users": "用户管理",
  "/settings": "系统设置",
};

export default function WebSphereLayout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuthStore();

  const currentPath = "/" + (location.pathname.split("/")[1] || "dashboard");

  return (
    <Layout className="ws-layout">
      {/* ── 侧边栏 WebSphere 深蓝 ── */}
      <Sider
        collapsible
        collapsed={collapsed}
        onCollapse={setCollapsed}
        trigger={null}
        width={220}
        style={{
          background: "linear-gradient(180deg, #0a1f44 0%, #132c54 100%)",
        }}
      >
        <div className="ws-logo">
          {collapsed ? "🚀" : "🚀 TestPilot"}
        </div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[currentPath]}
          items={menuItems}
          onClick={({ key }) => navigate(key)}
          style={{
            background: "transparent",
            borderRight: 0,
          }}
        />
      </Sider>

      <Layout>
        {/* ── 顶部栏 ── */}
        <Header className="ws-header">
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
          />
          <div className="ws-header-right">
            <Dropdown
              menu={{
                items: [
                  { key: "profile", icon: <UserOutlined />, label: "个人中心" },
                  { type: "divider" },
                  {
                    key: "logout",
                    icon: <LogoutOutlined />,
                    label: "退出登录",
                    danger: true,
                  },
                ],
                onClick: ({ key }) => {
                  if (key === "logout") {
                    logout();
                    navigate("/login");
                  }
                },
              }}
            >
              <Button type="text">
                <Avatar size="small" icon={<UserOutlined />} style={{ marginRight: 8 }} />
                {user?.nickname || user?.username}
              </Button>
            </Dropdown>
          </div>
        </Header>

        {/* ── 面包屑 ── */}
        <div style={{ padding: "8px 24px", background: "#f5f5f5" }}>
          <Breadcrumb
            items={[
              { title: "首页" },
              { title: breadcrumbMap[currentPath] || "未知页面" },
            ]}
          />
        </div>

        {/* ── 内容区 ── */}
        <Content className="ws-content">{children}</Content>
      </Layout>
    </Layout>
  );
}
