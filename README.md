# Discourse Check-in Plugin

一个功能完整的Discourse签到插件，支持每日签到、积分系统、连续签到奖励和补签机制。

## 功能特性

### 🎯 核心功能
- **每日签到**: 用户可以每天签到获取积分奖励
- **积分系统**: 独立的积分表管理用户积分
- **连续签到奖励**: 连续签到达到指定天数可获得额外奖励
- **补签机制**: 用户可以消耗积分补签错过的日期
- **签到记录**: 完整的签到历史记录查询
- **管理员配置**: 灵活的后台配置选项

### 🎨 界面特性
- **响应式设计**: 适配桌面和移动设备
- **Discourse风格**: 完美融入Discourse的UI设计
- **多语言支持**: 支持中文和英文界面
- **实时更新**: 签到状态实时更新

### ⚙️ 管理功能
- **灵活配置**: 管理员可配置签到奖励、连续奖励等参数
- **数据统计**: 查看签到统计数据和用户排行
- **积分管理**: 管理员可手动调整用户积分

## 安装指南

### 方法一：Git克隆（推荐）

1. 进入Discourse的plugins目录：
```bash
cd /var/discourse/plugins
```

2. 克隆插件：
```bash
git clone https://github.com/werta666/Discourse-Check-in.git
```

3. 重建容器：
```bash
cd /var/discourse
./launcher rebuild app
```

### 方法二：手动安装

1. 下载插件文件
2. 解压到 `/var/discourse/plugins/discourse-check-in/`
3. 重建Discourse容器

## 配置说明

安装完成后，进入管理后台 → 设置 → 插件 → Check-in System 进行配置：

### 基础设置
- **check_in_enabled**: 启用/禁用签到系统
- **check_in_daily_points**: 每日签到获得的积分数量（默认：10）

### 连续签到奖励
- **check_in_consecutive_bonus_enabled**: 启用连续签到奖励
- **check_in_consecutive_bonus_days**: 连续签到天数要求（默认：3天）
- **check_in_consecutive_bonus_points**: 连续签到奖励积分（默认：10）

### 补签设置
- **check_in_makeup_enabled**: 启用补签功能
- **check_in_makeup_cost_points**: 补签消耗积分（默认：5）
- **check_in_makeup_max_days**: 最大可补签天数（默认：7天）

## 使用指南

### 用户使用

1. **访问签到页面**: 点击导航菜单中的"签到"链接
2. **每日签到**: 点击"签到"按钮完成当日签到
3. **查看记录**: 切换到"记录"标签查看签到历史
4. **补签操作**: 在"补签"标签中选择日期进行补签

### 管理员操作

1. **查看统计**: 访问 `/check-in/admin/statistics` 查看整体数据
2. **用户管理**: 访问 `/check-in/admin/user-points` 管理用户积分
3. **积分调整**: 可以为用户增加或减少积分

## 数据库结构

### 表结构

#### user_points (用户积分表)
- `user_id`: 用户ID
- `total_points`: 总积分
- `created_at`, `updated_at`: 时间戳

#### check_in_records (签到记录表)
- `user_id`: 用户ID
- `check_in_date`: 签到日期
- `is_makeup`: 是否为补签
- `points_earned`: 获得积分
- `consecutive_days`: 连续签到天数
- `created_at`, `updated_at`: 时间戳

#### point_transactions (积分交易记录表)
- `user_id`: 用户ID
- `points`: 积分变化（正数为增加，负数为减少）
- `transaction_type`: 交易类型
- `description`: 描述
- `check_in_record_id`: 关联的签到记录ID
- `created_at`, `updated_at`: 时间戳

## API接口

### 用户接口

#### 签到
```
POST /check-in/check-in
```

#### 补签
```
POST /check-in/makeup-check-in
参数: { date: "2024-01-01" }
```

#### 获取签到状态
```
GET /check-in/check-in-status
```

#### 获取签到记录
```
GET /check-in/check-in-records?page=1&per_page=20
```

#### 获取积分信息
```
GET /check-in/points
```

#### 获取积分交易记录
```
GET /check-in/point-transactions?page=1&per_page=20&type=check_in
```

### 管理员接口

#### 获取统计数据
```
GET /check-in/admin/statistics
```

#### 获取用户积分列表
```
GET /check-in/admin/user-points?page=1&per_page=20&search=username
```

#### 调整用户积分
```
POST /check-in/admin/adjust-points
参数: { user_id: 1, points: 100, reason: "管理员调整" }
```

## 开发信息

### 技术栈
- **后端**: Ruby on Rails 7.0+
- **前端**: Ember.js (Discourse版本)
- **数据库**: PostgreSQL
- **样式**: SCSS

### 文件结构
```
discourse-check-in/
├── plugin.rb                          # 插件主文件
├── config/
│   ├── routes.rb                      # 路由配置
│   ├── settings.yml                   # 设置配置
│   └── locales/                       # 语言文件
├── app/
│   ├── models/                        # 数据模型
│   ├── controllers/                   # 控制器
│   └── services/                      # 业务逻辑服务
├── assets/
│   ├── javascripts/discourse/         # 前端JS文件
│   └── stylesheets/                   # 样式文件
├── db/migrate/                        # 数据库迁移
└── spec/                             # 测试文件
```

## 兼容性

- **Discourse版本**: 2.7.0+
- **Ruby版本**: 2.7+
- **Rails版本**: 7.0+

## 许可证

MIT License

## 支持

如有问题或建议，请提交Issue到GitHub仓库：
https://github.com/werta666/Discourse-Check-in/issues

## 更新日志

### v0.1.0 (2024-01-XX)
- 初始版本发布
- 实现基础签到功能
- 添加积分系统
- 支持连续签到奖励
- 实现补签机制
- 添加管理员配置界面
- 支持中英文双语
