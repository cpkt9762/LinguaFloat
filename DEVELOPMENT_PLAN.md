# LinguaFloat 开发计划书

## 目录
1. [项目概述](#项目概述)
2. [核心功能列表](#核心功能列表)
3. [技术栈与依赖](#技术栈与依赖)
4. [参考资源](#参考资源)
5. [详细开发阶段](#详细开发阶段)
    - [阶段1：准备与规划](#阶段1准备与规划)
    - [阶段2：MVP核心功能](#阶段2mvp核心功能)
    - [阶段3：AI集成与扩展](#阶段3ai集成与扩展)
    - [阶段4：OCR与高级交互](#阶段4ocr与高级交互)
    - [阶段5：测试优化与商业化](#阶段5测试优化与商业化)
6. [资源与预算估计](#资源与预算估计)
7. [后续维护计划](#后续维护计划)

---

## 项目概述
LinguaFloat 是一款专为 macOS 设计的高级翻译与 AI 辅助学习工具。其设计目标是提供无缝的跨应用翻译体验，通过全局快捷键、即时弹出窗口以及多模型 AI 集成，帮助用户更高效地阅读、编写和学习外语。应用将深度集成 macOS 原生框架，确保极佳的性能与用户体验。

## PRD 需求要点
- **目标用户**: macOS 日常工作者、学习者、翻译需求高频用户。
- **核心场景**: 选中文本翻译、输入框快速翻译、三连空格触发翻译。
- **性能要求**: 触发到显示译文的目标延迟 < 1.5s（网络可用时）。
- **权限策略**: 仅在启用三连空格时请求 Input Monitoring 与 Accessibility。
- **默认语言策略**: 自动检测源语言 → 翻译为简体中文，支持“中文→英语”规则切换。
- **输出策略**: 译文仅浮层展示，支持复制/关闭。
- **默认翻译引擎**: Google Translate Web（WKWebView）。

---

## 核心功能列表
- **即时翻译**: 选取屏幕上任何应用的文本后，通过快捷键立即触发翻译窗口。
- **三连空格触发**: 启用后全局检测空格三连击，触发翻译（仅在授权后生效）。
- **输入框翻译模式**: 无选中时支持三种范围（整框/光标句段/最后一行），默认整框。
- **OCR 屏幕识别**: 支持截屏识别图像中的文字并进行翻译。
- **AI 辅助学习**:
    - 词汇解释与定义
    - 文本重写与润色
    - 语法分析
    - 语音合成 (TTS) 朗读
- **多模型支持**: 集成 OpenAI (GPT-4), Claude, Gemini, DeepSeek 等主流 AI 模型。
- **历史记录**: 自动保存翻译历史，支持收藏与导出。
- **全局控制**: 自定义全局快捷键，支持菜单栏常驻。
- **Google 翻译 Web 模式**: 默认使用 WKWebView 打开 Google Translate 页面并预填文本。
- **代理支持**: 支持系统代理访问外部翻译服务。
- **译文输出**: 浮层显示译文，支持复制/关闭。

---

## 技术栈与依赖
- **编程语言**: Swift
- **UI 框架**: SwiftUI (主界面), AppKit (底层系统交互)
- **Web 渲染**: WebKit (WKWebView)
- **系统权限**: Accessibility、Input Monitoring（仅在启用三连空格时请求）
- **最低系统要求**: macOS 14.0 (Sonoma) 及以上
- **核心依赖**:
    - **快捷键管理**: KeyboardShortcuts (全局热键支持)
    - **事件监听**: CoreGraphics (CGEventTap)
    - **Web 翻译**: WKWebView（内置）
    - **文字识别**: Apple Vision Framework (原生 OCR)
    - **语音合成**: AVSpeechSynthesizer (AVFoundation)
    - **UI 组件**: Popover (用于实现类似 PopTranslate 的浮窗效果)
    - **密钥存储**: Keychain (Security)
    - **更新与分发**: Sparkle 2（站外更新）
    - **多模型扩展**: SwiftOpenAI, PreternaturalAI/AI（阶段 3）

---

## 参考资源

### GitHub 项目
- **整体应用架构**:
    - [markydoodled/Translate.it](https://github.com/markydoodled/Translate.it)
    - [tisfeng/Easydict](https://github.com/tisfeng/Easydict)
    - [hidden-spectrum/swift-translate](https://github.com/hidden-spectrum/swift-translate)
- **快捷键实现**:
    - [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
    - [soffes/HotKey](https://github.com/soffes/HotKey)
- **AI 模型集成**:
    - [jamesrochabrun/SwiftOpenAI](https://github.com/jamesrochabrun/SwiftOpenAI)
    - [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI)
    - [PreternaturalAI/AI](https://github.com/PreternaturalAI/AI)
- **OCR 识别**:
    - [adiaholic/SwiftOCR-Vision](https://github.com/adiaholic/SwiftOCR-Vision)
    - [bytefer/macos-vision-ocr](https://github.com/bytefer/macos-vision-ocr)
    - [louisbrulenaudet/apple-ocr](https://github.com/louisbrulenaudet/apple-ocr)
- **界面与弹出框**:
    - [iSapozhnik/Popover](https://github.com/iSapozhnik/Popover)

### 文档链接
- **Apple 开发者文档**:
    - [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
    - [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
    - [Vision Framework (OCR)](https://developer.apple.com/documentation/vision/)
    - [Accessibility API](https://developer.apple.com/documentation/accessibility/)
    - [AVSpeechSynthesizer (TTS)](https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer/)
    - [StoreKit (In-App Purchases)](https://developer.apple.com/documentation/storekit/)
- **AI API 参考**:
    - [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
    - [Anthropic Claude API](https://docs.anthropic.com/en/api/getting-started)
    - [Google Gemini API](https://ai.google.dev/docs)
    - [DeepSeek API](https://platform.deepseek.com/)

---

## 详细开发阶段

### 阶段1：准备与规划
- **目标**: 确立技术架构，完成项目初始化与分发策略。
- **任务列表**:
    - 明确功能需求清单 (PRD)。
    - 设计应用架构 (MVVM) 与模块边界（AppShell/UI/Domain/Provider）。
    - 初始化 Xcode 项目，配置 macOS 14+ 目标与 Bundle ID `com.pingzi.LinguaFloat`。
    - 集成基础依赖库 (Swift Package Manager)。
    - 设计应用图标与基础 UI 规范（参考提供的设置界面风格）。
    - 定义翻译 Provider 协议与错误模型（为多模型扩展预埋）。
    - 确定分发路线：站外发布（Developer ID 签名 + Hardened Runtime + Notarization + Sparkle）。
    - 权限策略设计：仅在启用“三连空格”时请求 Input Monitoring + Accessibility。
- **时间估计**: 1-2 周
- **风险点**: 依赖库版本冲突，系统权限申请流程与用户拒绝策略。
- **里程碑**: 完成项目脚手架与核心协议设计，应用能正常启动并显示菜单栏图标。

### 阶段2：MVP核心功能
- **目标**: 实现核心翻译流程、三连空格触发与浮窗交互。
- **任务列表**:
    - 实现选中文本获取：优先 Accessibility 读取选区，兜底使用剪贴板复制并恢复。
    - 集成 KeyboardShortcuts 实现全局快捷键触发。
    - 开发浮层 UI 窗口（NSPanel/Popover），支持鼠标附近定位与顶层显示。
    - 集成 Google Translate Web 模式（WKWebView）并预填 `sl=auto`、`tl=zh-CN`、`text`。
    - 实现三连空格触发（CGEventTap），仅在功能启用时请求 Input Monitoring + Accessibility。
    - 无选中时翻译范围：整框/光标句段/最后一行（默认整框）。
    - 语言方向规则：自动检测→简体中文，提供“中文→英语”可选规则。
    - 实现基础设置页面（翻译范围、语言规则、三连空格开关、权限状态）。
- **时间估计**: 2-4 周
- **风险点**: 不同应用间的文本选取兼容性、空格误触发、WKWebView 解析不稳定性。
- **里程碑**: 用户可通过快捷键或三连空格触发翻译，并在浮层中查看与复制结果。

### 阶段3：AI集成与扩展
- **目标**: 增强 AI 功能，支持多模型与多媒体辅助。
- **任务列表**:
    - 接入 Claude, Gemini, DeepSeek 等模型接口。
    - 实现翻译结果对比功能。
    - 开发 AI 工具集：重写、解释、语法检查。
    - 集成 AVSpeechSynthesizer 实现多语言 TTS 朗读。
    - 优化 AI 响应解析，支持 Markdown 渲染。
- **时间估计**: 3-5 周
- **风险点**: 各 AI 平台 API 限制与延迟，流式传输 (Streaming) 响应稳定性。
- **里程碑**: 应用具备全面的 AI 辅助能力，用户可自由切换模型。

### 阶段4：OCR与高级交互
- **目标**: 扩展识别能力，完善用户体验。
- **任务列表**:
    - 基于 Vision Framework 开发屏幕截图识别功能。
    - 实现历史翻译记录的本地存储 (Core Data/SwiftData)。
    - 添加历史记录搜索与筛选功能。
    - 开发“超级取词”模式，支持悬停自动识别。
    - 优化交互细节（淡入淡出动画、触控板手势支持）。
- **时间估计**: 2-4 周
- **风险点**: 截图权限获取，OCR 对特殊字体或复杂背景的识别率。
- **里程碑**: 实现完整的 OCR 翻译链路，具备完善的历史管理系统。

### 阶段5：测试优化与商业化
- **目标**: 确保应用质量，完成站外发布与商业化准备。
- **任务列表**:
    - 编写单元测试 (XCTest) 与 UI 测试。
    - 性能监控与内存泄漏修复。
    - 集成订阅与授权系统（非 App Store 渠道，可选自研或第三方）。
    - 完成应用本地化 (多语言支持)。
    - 构建站外发布链路：Developer ID 签名、Hardened Runtime、Notarization、Sparkle 自动更新。
- **时间估计**: 2-4 周
- **风险点**: 站外更新渠道安全性、签名/公证失败导致更新中断。
- **里程碑**: 应用完成签名、公证与更新链路，可对外发布。

---

## MVP 成功标准与测试计划
- **功能标准**:
    - 选中文本 + 快捷键触发 → 浮层展示译文。
    - 三连空格触发：
        - 启用功能且已授权 → 支持无选中文本翻译。
        - 未授权 → 必须选中才能翻译，并提示授权。
    - 无选中时支持三种范围（整框/光标句段/最后一行），默认整框。
    - 自动检测 → 目标语言为简体中文；可切换“中文→英语”规则。
    - WKWebView 能正确加载 Google Translate 并预填文本。
- **可观察标准**:
    - 权限仅在启用三连空格时请求。
    - 翻译失败时有明确错误提示与重试入口。
- **测试计划**:
    1. 选中文本 → 快捷键 → 浮层显示译文。
    2. 启用三连空格但未授权 → 触发 → 权限提示出现。
    3. 授权后不选中 → 三连空格 → 默认范围翻译。
    4. 切换范围（整框/句段/最后一行）→ 结果符合预期。
    5. 切换“中文→英语”规则 → 目标语言切换生效。
    6. WKWebView 打开 `translate.google.com` 并预填文本。

## 资源与预算估计
- **开发人力**: 1 名资深 iOS/macOS 开发者。
- **API 成本**: 预估每月 $50 - $200 (取决于模型调用量)。
- **基础设施**: Apple Developer Program ($99/年)，服务器中转 (可选，预估 $10/月)。
- **设计资源**: UI 资源包、图标设计、营销素材。

---

## 后续维护计划
- **模型跟进**: 及时接入最新发布的 AI 模型（如 GPT-5 或新版 Claude）。
- **社区反馈**: 建立用户反馈渠道，根据需求迭代功能。
- **系统适配**: 针对 macOS 年度大版本更新进行及时适配。
- **性能迭代**: 持续优化取词延迟与内存占用。
