# LinguaFloat UI 设计规范

## 应用图标
- **风格**: macOS Big Sur+ 风格，圆角矩形
- **主元素**: 翻译符号（双向箭头 + 文字气泡）
- **配色**: 蓝色渐变（#007AFF → #5856D6）
- **尺寸**: 1024x1024 (AppIcon.appiconset)

## 颜色系统
| 用途 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 主色 | #007AFF | #0A84FF |
| 背景 | System Background | System Background |
| 文字主色 | .primary | .primary |
| 文字次色 | .secondary | .secondary |
| 边框 | .separator | .separator |
| 成功 | #34C759 | #30D158 |
| 错误 | #FF3B30 | #FF453A |

## 字体规范
| 元素 | 字体 | 大小 |
|------|------|------|
| 标题 | .title | 17pt |
| 正文 | .body | 13pt |
| 标签 | .caption | 11pt |
| 按钮 | .body | 13pt |

## 间距系统
- **xs**: 4pt
- **sm**: 8pt
- **md**: 16pt
- **lg**: 20pt
- **xl**: 24pt

## 窗口规范

### 菜单栏 Popover
- **宽度**: 360pt
- **高度**: 400pt (自适应)
- **圆角**: 12pt
- **内边距**: 16pt

### 设置窗口
- **宽度**: 480pt
- **高度**: 320pt (自适应)
- **Tab 栏**: 居中，图标 + 文字

### 翻译浮层
- **宽度**: 320pt - 480pt (自适应)
- **高度**: 自适应内容
- **层级**: .floating
- **位置**: 鼠标附近或选区附近

## 控件规范

### 按钮
- **主按钮**: .borderedProminent
- **次按钮**: .bordered
- **文字按钮**: .borderless

### 输入框
- **背景**: Color(nsColor: .controlBackgroundColor)
- **圆角**: 8pt
- **内边距**: 8pt

### 开关
- **样式**: .switch (macOS 原生)

### 下拉菜单
- **样式**: .menu
- **宽度**: 自适应内容

## 动画规范
- **时长**: 0.2s - 0.3s
- **曲线**: .easeInOut
- **浮层出现**: 淡入 + 轻微缩放
- **浮层消失**: 淡出

## 深色模式
- 使用系统语义色
- 避免硬编码颜色值
- 测试两种模式下的可读性
