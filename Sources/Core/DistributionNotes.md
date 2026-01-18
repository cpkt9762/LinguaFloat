# LinguaFloat 站外发布链路

## 分发策略
- **不上架 App Store**
- 使用 Developer ID 签名 + Hardened Runtime + Notarization + Sparkle 自动更新

## 签名与公证流程

### 1. 前置准备
- Apple Developer Program 账号（$99/年）
- Developer ID Application 证书
- Developer ID Installer 证书（可选，用于 pkg）

### 2. Hardened Runtime 配置
在 Xcode 项目中启用：
- Target > Signing & Capabilities > + Capability > Hardened Runtime

需要的 Entitlements:
```xml
<key>com.apple.security.automation.apple-events</key>
<true/>
```

### 3. 公证流程
```bash
# 创建 ZIP 或 DMG
ditto -c -k --keepParent "LinguaFloat.app" "LinguaFloat.zip"

# 提交公证
xcrun notarytool submit "LinguaFloat.zip" \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# 装订公证票据
xcrun stapler staple "LinguaFloat.app"
```

### 4. Sparkle 自动更新

#### SPM 集成
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
]
```

#### Info.plist 配置
```xml
<key>SUFeedURL</key>
<string>https://your-domain.com/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_ED_PUBLIC_KEY</string>
```

#### Appcast.xml 示例
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>LinguaFloat Updates</title>
    <item>
      <title>Version 1.0.1</title>
      <sparkle:version>1.0.1</sparkle:version>
      <sparkle:shortVersionString>1.0.1</sparkle:shortVersionString>
      <pubDate>Sat, 18 Jan 2026 00:00:00 +0000</pubDate>
      <enclosure url="https://your-domain.com/releases/LinguaFloat-1.0.1.zip"
                 sparkle:edSignature="SIGNATURE"
                 length="12345678"
                 type="application/octet-stream"/>
    </item>
  </channel>
</rss>
```

## 发布检查清单
- [ ] 版本号更新（CFBundleShortVersionString, CFBundleVersion）
- [ ] 签名有效（codesign --verify）
- [ ] 公证完成（spctl --assess）
- [ ] Sparkle 签名生成
- [ ] Appcast.xml 更新
- [ ] 上传新版本 ZIP/DMG
