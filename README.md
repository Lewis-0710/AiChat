# AI聊天室 (AI Chat Room)

一个基于 Flutter 开发的桌面端多 AI 协作对话系统，支持同时接入多个 AI 成员，实现智能协作对话。

## 🌟 功能特性

### 核心功能
- **多 AI 成员管理**：支持添加多个 AI 成员，每个成员可选择不同的 AI 工具（Codex、Claude、OpenCode、PI、Goose、Cursor、Zcode、TraeCode、CodeBuddy）
- **智能协作对话**：AI 成员可自动接力回复，形成连续的协作对话
- **灵活的接入方式**：支持 OpenAI Chat API、OpenAI Response API、Anthropic API 等多种接入方式
- **本地 SDK 检测**：自动检测本地安装的 AI 工具 SDK，支持手动配置路径
- **对话管理**：创建、编辑、删除对话，支持多对话并行
- **消息流式输出**：支持实时流式回复，提升交互体验

### 技术特性
- **跨平台支持**：支持 macOS、Windows、Linux
- **状态管理**：使用 Provider 进行状态管理
- **数据持久化**：本地 JSON 文件存储
- **UI/UX**：Material Design 3 风格，深色主题
- **响应式设计**：自适应不同屏幕尺寸

## 🚀 快速开始

### 环境要求
- Flutter 3.8.0 或更高版本
- Dart 3.8.0 或更高版本
- macOS 10.14+ / Windows 10+ / Ubuntu 18.04+

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd aigroup_desktop
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

### 开发调试
```bash
# 开启调试模式
flutter run --debug

# 构建发布版本
flutter build --release
```

## 📖 使用指南

### 1. 添加 AI 成员

1. 点击主界面右下角的"+"按钮
2. 填写成员信息：
   - **名称**：AI 成员的显示名称
   - **AI 工具**：选择要使用的 AI 工具
   - **接入类型**：
     - OpenAI Chat：标准 OpenAI Chat API
     - OpenAI Response：OpenAI Response API
     - Anthropic：Anthropic Claude API
   - **供应商 URL**：API 服务器地址（默认使用官方地址）
   - **API Key**：API 密钥
   - **模型 ID**：使用的模型名称
3. 点击"确定"保存

### 2. 创建对话

1. 点击工具栏的"新建对话"按钮
2. 选择参与对话的 AI 成员（可多选）
3. 输入对话标题
4. 点击"确定"创建对话

### 3. 进行对话

1. 在消息输入框中输入内容
2. 可以 @ 特定成员进行回复
3. 支持粘贴图片（自动转换为 base64）
4. 发送消息后，AI 成员会自动接力回复

### 4. SDK 配置

系统会自动检测本地安装的 AI 工具 SDK。如果检测失败，可以：

1. 在成员管理页面手动配置 SDK 路径
2. 支持的路径格式：
   - 绝对路径：`/path/to/sdk`
   - 相对路径：`~/path/to/sdk`
   - 环境变量：`<npm-prefix>/bin/tool`

### 5. 对话管理

- **切换对话**：点击左侧对话列表切换不同对话
- **编辑标题**：右键点击对话选择"重命名"
- **删除对话**：右键点击对话选择"删除"
- **结束对话**：点击工具栏的"结束对话"按钮停止 AI 自动接力

## 🔧 配置说明

### AI 工具支持

| 工具名称 | 支持的 SDK 路径 | 说明 |
|---------|----------------|------|
| Codex | `/Applications/ChatGPT.app/Contents/MacOS/ChatGPT` | ChatGPT 桌面版 |
| Claude | `/Applications/Claude.app/Contents/MacOS/Claude` | Claude 桌面版 |
| OpenCode | `~/.opencode` | OpenCode AI 工具 |
| Zcode | 多种路径 | Zcode AI 工具 |
| TraeCode | 多种路径 | TraeCode AI 工具 |
| CodeBuddy | 多种路径 | CodeBuddy AI 工具 |

### API 配置

#### OpenAI API
```yaml
供应商 URL: https://api.openai.com/v1
API Key: sk-xxx...
模型: gpt-4, gpt-4-turbo, gpt-3.5-turbo 等
```

#### Anthropic API
```yaml
供应商 URL: https://api.anthropic.com
API Key: xxx...
模型: claude-3-opus, claude-3-sonnet, claude-3-haiku 等
```

## 📁 项目结构

```
lib/
├── app.dart                 # 应用入口
├── main.dart                # 主入口文件
├── models/                  # 数据模型
│   ├── member.dart         # AI 成员模型
│   ├── conversation.dart   # 对话模型
│   └── message.dart        # 消息模型
├── providers/               # 状态管理
│   ├── member_provider.dart # 成员管理
│   └── conversation_provider.dart # 对话管理
├── services/               # 业务服务
│   ├── api_client.dart     # API 客户端
│   ├── storage_service.dart # 存储服务
│   ├── sdk_detector.dart   # SDK 检测服务
│   └── model_fetcher.dart  # 模型获取服务
├── pages/                  # 页面
│   ├── home_page.dart      # 主页面
│   ├── member_management_page.dart # 成员管理页面
│   └── widgets/           # 页面组件
├── theme/                  # 主题样式
│   └── app_theme.dart      # 应用主题
└── utils/                  # 工具类
    └── constants.dart      # 常量定义
```

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/sdk_detector_test.dart
```

## 📝 开发说明

### 添加新的 AI 工具支持

1. 在 `lib/models/member.dart` 中添加新的 `AiTool` 枚举
2. 在 `lib/services/sdk_detector.dart` 中添加对应的可执行文件名和搜索路径
3. 在 `lib/services/api_client.dart` 中添加对应的 API 客户端实现
4. 更新 `lib/utils/constants.dart` 中的配置

### 添加新的 API 接入方式

1. 在 `lib/models/member.dart` 中添加新的 `AccessType` 枚举
2. 在 `lib/services/api_client.dart` 中实现对应的 API 客户端
3. 在 `lib/services/api_client.dart` 中的 `ApiClientFactory` 中注册

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🆘 常见问题

### Q: 如何更换 API 供应商？
A: 在成员管理页面编辑成员，修改"供应商 URL"字段即可。

### Q: AI 成员不自动回复怎么办？
A: 检查 API Key 是否正确，网络是否畅通，或尝试手动 @ 成员。

### Q: 如何备份对话数据？
A: 对话数据存储在用户目录下的 `Application Support/aigroup` 文件夹中。

### Q: 支持哪些图片格式？
A: 支持所有浏览器可识别的图片格式（JPG、PNG、GIF 等）。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 Issue
- 发送邮件
- 参与讨论

---

**注意**：本项目仅用于学习和研究目的，请遵守相关 API 的使用条款。
