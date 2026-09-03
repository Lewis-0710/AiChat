# AI聊天室 (AI Chat Room)

<p align="center">
  <img src="macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" alt="AI聊天室 Logo" width="128" height="128" />
</p>

<p align="center">
  <b>基于 Flutter 构建的高性能多 AI 协同对话桌面客户端</b>
</p>

<p align="center">
  <a href="https://github.com/Lewis-0710/AiChat/releases"><img src="https://img.shields.io/github/v/release/Lewis-0710/AiChat?label=Latest%20Release" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/Flutter-%3E%3D3.8.0-blue.svg" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.8.0-blue.svg" alt="Dart Version" />
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-lightgrey.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License" />
</p>

---

## 📖 项目简介

**AI聊天室** 是一个专为桌面端（macOS / Windows / Linux）打造的多 AI 协同对话应用。打破单一模型交互限制，支持在同一个会话中组合接入 DeepSeek、Claude、OpenAI (Codex)、Cursor、TraeCode、Zcode 等多款主流 AI 工具与模型，实现智能自动接力应答、多轮协同推理与跨模型协同工作。

---

## 🌟 核心功能特性

### 1. 多 AI 成员自由编排与协同
- **多角色入群**：支持同时添加并配置多个 AI 成员，支持主流工具全家桶：**DeepSeek、Codex、Claude、Cursor、TraeCode、CodeBuddy、Zcode、OpenCode、PI、Goose**。
- **自动接力对话**：多 AI 成员可按顺序智能接力推理，形成连续递进的讨论流；亦可通过 `@` 明确指定目标成员应答。
- **随时控制节奏**：支持随时手动一键中断接力，掌控对话走向。

### 2. 广泛的 API 协议接入
- **OpenAI Chat Completions 协议**：标准 `/v1/chat/completions` 接口（支持 OpenAI 官方及兼容转发服务）。
- **OpenAI Response 协议**：支持最新 Response 格式流式交互。
- **Anthropic Claude 协议**：原生 `/v1/messages` 流式通信。
- **DeepSeek 官方 API**：内置 DeepSeek 官方服务地址（`https://api.deepseek.com`）与模型支持。
- **动态模型发现**：支持配置 API 后一键拉取供应商可用模型列表。

### 3. 本地 SDK 智能检测与动态扫描
- **多维度检索策略**：内置环境变量 `PATH` 探针、常见全局安装路径检测、npm prefix 映射。
- **动态 Hash / 通配符扫描**：全面支持 DeepSeek（DSH Desktop 动态哈希路径扫描）、TRAE SOLO CN 独立应用、WorkBuddy / CodeBuddy 解包二进制、Zcode 等复杂 SDK 路径智能识别。
- **灵活的手动覆盖**：支持自定义路径并提供实时可用性校验与状态指示灯。

### 4. 丝滑交互与极致性能
- **流式输出节流优化**：针对高速吐字和大篇幅代码长文本深度优化，平滑 UI 渲染频率，彻底告别掉帧与列表滑动卡顿。
- **发送自动触底**：用户发出新消息即刻精准滚动至底部，保证交互无延时。
- **左侧消息指示器 & 快速导航**：
  - 侧边实时渲染用户消息节点列表。
  - 鼠标悬停即时展示**内容纯文本摘要**（前 30 字）或 `[图片]` 标签。
  - 单击即平滑滚动并准确定位至对应消息，智能补偿多段 AI 长回复带来的偏移误差。
- **剪贴板多模态支持**：直接 `Command + V` / `Ctrl + V` 粘贴剪贴板图片，自动压缩转为 Base64 并传递给多模态模型。

### 5. 现代化桌面体验
- **Material Design 3 风格**：深色科技极客风界面，结合各 AI 工具专属品牌渐变色彩标识。
- **数据安全本地化**：所有对话历史与成员配置均安全保存在用户本机，支持异常熔断与容错回退机制。

---

## 📦 快速下载（推荐）

无需自行配置编译环境，直接前往 GitHub Release 获取最新的预编译安装镜像：

👉 **[前往 GitHub Releases 下载最新安装包](https://github.com/Lewis-0710/AiChat/releases)**

| 平台 | 安装包名称 | 架构说明 |
|:---|:---|:---|
| **macOS (最新)** | `AiChat-macOS-v1.0.1.dmg` | 支持 Apple Silicon (M1/M2/M3/M4) 及 Intel 芯片 |

> **macOS 首次打开提示“已损坏”或“无法打开”？**
> 
> 请打开终端执行以下命令清除系统安全隔离标识即可正常打开：
> ```bash
> xattr -cr /Applications/AI聊天室.app
> ```

---

## 🚀 源码编译与运行

### 环境要求
- **Flutter SDK**：`>= 3.8.0`（推荐使用当前稳定版 3.44+）
- **Dart SDK**：`>= 3.8.0`
- **操作系统**：macOS (10.14+) / Windows (10+) / Ubuntu (18.04+)
- **构建工具**：macOS 需安装 Xcode 及 Command Line Tools

### 1. 获取代码与依赖
```bash
# 克隆仓库
git clone https://github.com/Lewis-0710/AiChat.git
cd AiChat/aigroup_desktop

# 安装依赖
flutter pub get
```

### 2. 本地开发调试
```bash
# 启动 macOS 桌面客户端调试
flutter run -d macos

# 启动 Windows 客户端调试（需在 Windows 环境）
flutter run -d windows
```

### 3. 构建发布版本
```bash
# 构建 macOS Release 产物 (.app)
flutter build macos --release

# 构建 Windows Release 产物 (.exe)
flutter build windows --release

# 构建 Linux Release 产物
flutter build linux --release
```

---

## 🔧 AI 工具与 SDK 检测矩阵

系统内置对以下 AI 工具的本地 SDK 智能探查支持：

| AI 工具 | 默认可执行文件名 | 典型预设检测路径 | 备注 |
|:---|:---|:---|:---|
| **DeepSeek** | `dsh`, `deepseek` | `~/Library/Application Support/DSH Desktop/cli/*/bin/dsh`<br>`~/.local/bin/dsh`<br>`/opt/homebrew/bin/dsh` | 支持动态哈希版本目录通配扫描 |
| **Codex** | `ChatGPT` | `/Applications/ChatGPT.app/Contents/MacOS/ChatGPT` | OpenAI 官方桌面端 |
| **Claude** | `Claude` | `/Applications/Claude.app/Contents/MacOS/Claude` | Anthropic 官方桌面端 |
| **Cursor** | `cursor` | 系统 `PATH` / `/usr/local/bin/cursor` | Cursor AI 编辑器 CLI |
| **TraeCode** | `trae-cn`, `traecli`, `traework`, `trae-work` | `/Applications/TRAE SOLO CN.app/Contents/Resources/app/bin/code`<br>`~/.npm-global/bin/traecli` | 字节跳动 Trae 智能编码环境 |
| **CodeBuddy** | `codebuddy`, `codebuudy` | `/Applications/WorkBuddy.app/Contents/Resources/app.asar.unpacked/cli/bin/codebuddy`<br>`/opt/homebrew/bin/codebuddy` | 腾讯 WorkBuddy / CodeBuddy CLI |
| **Zcode** | `zcode` | `~/.zcode/cli/zcode`<br>`/Applications/ZCode.app/Contents/Resources/glm/zcode.cjs` | 智谱 Zcode 命令行 |
| **OpenCode** | `opencode` | `~/.opencode` | OpenCode 工具集 |
| **PI** | `pi` | 系统 `PATH` | Inflection PI |
| **Goose** | `goose` | 系统 `PATH` | Block Goose 开发者代理 |

---

## ⚙️ 接入配置说明

### 常用供应商 API 配置指南

#### 1. DeepSeek 官方接入
```yaml
接入类型: OpenAI Chat
供应商 URL: https://api.deepseek.com
API Key: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
推荐模型: deepseek-chat, deepseek-reasoner
```

#### 2. OpenAI 官方 / 转发服务
```yaml
接入类型: OpenAI Chat 或 OpenAI Response
供应商 URL: https://api.openai.com/v1 (或兼容中转地址)
API Key: sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
推荐模型: gpt-4o, gpt-4o-mini, o1-preview, o3-mini
```

#### 3. Anthropic Claude
```yaml
接入类型: Anthropic
供应商 URL: https://api.anthropic.com
API Key: sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
推荐模型: claude-3-7-sonnet-20250219, claude-3-5-sonnet-20241022, claude-3-5-haiku-20241022
```

---

## 📁 项目工程架构

```
aigroup_desktop/
├── lib/
│   ├── app.dart                   # 应用入口、主题配置与路由
│   ├── main.dart                  # 应用启动与存储初始化
│   ├── models/                    # 数据持久化与传输模型
│   │   ├── member.dart            # AI 成员实体（支持 10 种 AI 工具）
│   │   ├── conversation.dart      # 对话会话模型
│   │   └── message.dart           # 消息实体（支持多模态图片、状态流）
│   ├── providers/                 # 响应式状态管理 (Provider)
│   │   ├── member_provider.dart   # 成员增删改查、SDK 探测与连接测试
│   │   └── conversation_provider.dart # 对话调度、流式响应处理、多 AI 接力控制
│   ├── services/                  # 核心基础服务
│   │   ├── api_client.dart        # 统一 API 客户端（OpenAI Chat / Response / Claude）
│   │   ├── storage_service.dart   # 本地 JSON 存储服务（带异常自愈机制）
│   │   ├── sdk_detector.dart      # 跨平台本地 SDK 智能检测与通配扫描引擎
│   │   └── model_fetcher.dart     # 供应商模型在线拉取探测
│   ├── pages/                     # UI 页面
│   │   ├── home_page.dart         # 主页面（会话列表、聊天窗口、消息导航）
│   │   ├── member_management_page.dart # 成员列表、配置与管理
│   │   └── widgets/               # 组件库（消息气泡、表单弹窗、创建对话）
│   ├── theme/                     # 主题系统
│   │   ├── app_theme.dart         # Material 3 深色科技主题
│   │   └── widgets/               # 动态发光渐变装饰组件
│   └── utils/                     # 常量与工具
│       └── constants.dart         # API 默认端点、SDK 匹配规则
├── test/                          # 自动化测试套件
│   ├── sdk_detector_test.dart     # SDK 检测规则与通配路径自动化测试
│   └── message_list_and_bubble_test.dart # 消息滚动、双向定位与指示器单元测试
└── pubspec.yaml                   # 依赖配置与元数据
```

---

## 🧪 自动化测试

项目已编写完备的自动化测试用例，涵盖 SDK 检索机制、通配符解析、滚动定位与指示器交互：

```bash
# 运行全部单元与 Widget 测试
flutter test

# 单独运行 SDK 探测测试（包含动态 Hash 目录扫描用例）
flutter test test/sdk_detector_test.dart

# 单独运行消息列表定位与导航测试
flutter test test/message_list_and_bubble_test.dart
```

---

## 📝 最近更新日志

### v1.0.1
- **新增 DeepSeek 支持**：新增 DeepSeek 工具类型、专属主题色与默认 API 端点；支持扫描 DSH Desktop 动态哈希路径。
- **SDK 探查能力增强**：全面支持 TRAE SOLO CN 独立应用、WorkBuddy / CodeBuddy 解包二进制与通配符路径匹配。
- **长文本渲染与流畅度大幅优化**：重构流式响应通知节流机制，彻底解决超长回复和高频吐字下的 UI 掉帧卡顿。
- **导航与定位体验升级**：
  - 发送新消息即时平滑滚动到底部。
  - 左侧用户消息指示器支持精准点击定位，解决长回复位移偏差。
  - 优化指示器 Tooltip 提示为纯文本摘要预览。
- **存储与平台配置加固**：完善 macOS Entitlements 网络权限与用户存储目录回退机制。

---

## 📄 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源发布。
