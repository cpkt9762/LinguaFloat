# LinguaFloat

macOS 菜单栏翻译工具，支持快捷键翻译、OCR 截图翻译、多翻译引擎。

## 功能特性

- **快速翻译替换**：选中文本后 `Cmd+A → R`，自动翻译并替换原文
- **浮窗翻译**：选中文本后 `Cmd+Shift+T`，显示翻译结果浮窗
- **OCR 截图翻译**：`Cmd+Shift+O` 截图识别文字并翻译
- **多翻译引擎**：支持 Google Web、OpenAI、Claude、DeepSeek
- **翻译历史**：自动保存翻译记录，可搜索查看
- **翻译方向可选**：中文→英语 或 英语→中文

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+A` → `R` | 选中文本后，先按 Cmd+A 全选，保持 Cmd 不松开，按 R 触发翻译并自动替换 |
| `Cmd+Shift+T` | 选中文本后显示翻译浮窗 |
| `Cmd+Shift+O` | 截图 OCR 识别并翻译 |

## 安装

### 从 Release 下载

1. 下载最新的 `LinguaFloat.app.zip`
2. 解压后拖入 `/Applications` 文件夹
3. 首次运行需要右键选择"打开"（因为未上架 App Store）

### 从源码构建

```bash
git clone https://github.com/pingz1/LinguaFloat.git
cd LinguaFloat
swift build -c release
cp -R dist/LinguaFloat.app /Applications/
```

## 权限设置

LinguaFloat 需要以下系统权限才能正常工作：

### 辅助功能权限（必需）

用于获取选中文本和模拟粘贴操作。

1. 打开「系统设置」→「隐私与安全性」→「辅助功能」
2. 点击 `+` 添加 LinguaFloat
3. 确保开关已开启

### 屏幕录制权限（OCR 功能需要）

用于截图识别文字。

1. 打开「系统设置」→「隐私与安全性」→「屏幕录制」
2. 点击 `+` 添加 LinguaFloat
3. 确保开关已开启

## 配置翻译引擎

点击菜单栏图标 → 右键 → 设置

### Google Web（默认，免费）

无需配置，直接使用。

### OpenAI

1. 获取 [OpenAI API Key](https://platform.openai.com/api-keys)
2. 在设置中填入 API Key
3. 可选配置自定义 API 地址（用于代理）

### Claude

1. 获取 [Anthropic API Key](https://console.anthropic.com/)
2. 在设置中填入 API Key

### DeepSeek

1. 获取 [DeepSeek API Key](https://platform.deepseek.com/)
2. 在设置中填入 API Key

## 使用方法

### 快速翻译替换（推荐）

1. 在任意应用中选中要翻译的文本
2. 按 `Cmd+A` 全选（保持 Cmd 不松开）
3. 按 `R` 触发翻译
4. 翻译完成后自动粘贴替换原文

适合在微信、邮件、文档等场景快速翻译。

### 浮窗翻译

1. 选中要翻译的文本
2. 按 `Cmd+Shift+T`
3. 在浮窗中查看翻译结果
4. 可点击复制按钮复制译文

### OCR 截图翻译

1. 按 `Cmd+Shift+O`
2. 框选屏幕区域
3. 自动识别文字并翻译

## 技术栈

- Swift 5.9 + SwiftUI
- SwiftData（翻译历史存储）
- Sparkle（自动更新）
- KeyboardShortcuts（全局快捷键）

## 许可证

MIT License
