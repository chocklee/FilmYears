# FilmYears MVP — 编码前准备工作检查清单

> 在写第一行 Swift 代码之前，需要确认以下事项全部就绪。

---

## 1. 环境与工具

### 1.1 Xcode 版本
- [ ] **Xcode 16+**（iOS 18 SDK 需要 Xcode 16，从 Mac App Store 或 Apple Developer 下载）
- [ ] **Command Line Tools**：`xcode-select --install`
- [ ] **Swift 6 语言模式确认**：Xcode 16 默认 Swift 6，但需在 Build Settings 中检查 `Swift Language Version` 设为 `6`

### 1.2 Apple Developer Account
- [ ] **个人/组织开发者账户**（$99/年）
- [ ] 登录 Xcode → Settings → Accounts，确认 Apple ID 已添加
- [ ] **Team 已关联**：Project → Signing & Capabilities 中选择正确的 Team

### 1.3 设备准备
- [ ] **真机测试设备**（至少 1 台 iPhone，iOS 18+）
- [ ] **模拟器**：iOS 18 Simulator 已下载（Xcode → Settings → Platforms）
- [ ] **多设备测试计划**：iPhone + iPad 不同尺寸验证布局

---

## 2. 项目创建与配置

### 2.1 Xcode 项目初始化
- [ ] 选择模板：iOS → App → SwiftUI + SwiftData
- [ ] **Organization Identifier**：`com.yourcompany`（最终需匹配 App Store 上线 Bundle ID）
- [ ] **Bundle Identifier**：`com.yourcompany.filmyears`
- [ ] **Interface**：SwiftUI
- [ ] **Language**：Swift
- [ ] **Minimum Deployment**：iOS 18.0
- [ ] **Swift Concurrency Checking**：Complete（Swift 6 strict mode）
- [ ] 勾选所有目标设备（iPhone + iPad + Mac Catalyst）

### 2.2 项目结构（文件目录）
- [ ] 按技术文档中的文件夹结构建立 Group（不自动创建文件夹，用文件夹引用的 Group）

```
FilmYears/
├── App/
│   ├── FilmYearsApp.swift
│   ├── ContentView.swift
│   └── PersistenceController.swift
├── Models/
├── Views/
│   ├── Onboarding/
│   ├── Home/
│   ├── Reel/
│   ├── Ring/
│   ├── Settings/
│   └── Components/
├── ViewModels/
├── Services/
├── Widgets/
├── Resources/
│   ├── Assets.xcassets
│   └── Info.plist
└── Preview Content/
```

### 2.3 最低部署版本的重要影响
- **iOS 18+ 意味着**：
  - ✅ 可以直接用 `@Observable`（无 `ObservableObject` 包袱）
  - ✅ `@ModelActor` 可用（后台安全写数据）
  - ✅ `#Widgets` 宏可用
  - ✅ `@Entry` 环境值注册可用
  - ❌ 无法在 iOS 17 设备上运行
  - ❌ App Store 提交时需确认用户群是否有足够的 iOS 18 覆盖率

---

## 3. 证书、Capabilities 与 Entitlements

### 3.1 App Groups（Widget 数据共享）
- [ ] 添加 Capability：App Groups
- [ ] Group ID：`group.com.yourcompany.filmyears`
- [ ] **主 Target** + **Widget Extension Target** 都勾选同一个 Group

### 3.2 iCloud / CloudKit
- [ ] 添加 Capability：iCloud
- [ ] 勾选 **CloudKit** service
- [ ] Container ID：`iCloud.com.yourcompany.filmyears`
- [ ] 勾选 **Background Modes** → `Remote notifications`（CloudKit 推送同步需要）

### 3.3 Photo Library（用于导出年轮图片）
- [ ] 添加 Capability：Photo Library（Add Photos）
- [ ] Info.plist 添加：`NSPhotoLibraryAddUsageDescription` → "FilmYears 需要保存年轮图片到你的相册"

### 3.4 Screen Time（可选）
- [ ] Info.plist 添加：`NSFamilyControlsUsageDescription` → "开启后可让胶片帧根据屏幕使用时间显示色彩纹理（可选）"

---

## 4. App Store Connect & CloudKit Dashboard

### 4.1 App Store Connect 应用记录
- [ ] 登录 [App Store Connect](https://appstoreconnect.apple.com)
- [ ] 创建新 App：
  - 平台：iOS
  - 名称：FilmYears
  - 语言：简体中文（主要）/ 英文
  - Bundle ID：`com.yourcompany.filmyears`
  - SKU：`FILMYEARS_001`
- [ ] **注意**：Bundle ID 需先在 Apple Developer Portal 注册

### 4.2 CloudKit Container
- [ ] App Store Connect 应用页 → CloudKit → 确认 container 已自动创建
- [ ] 或手动在 [CloudKit Dashboard](https://icloud.developer.apple.com) 创建
- [ ] Container ID 与 Xcode 中填写的完全一致

### 4.3 IAP Product（买断）
- [ ] App Store Connect → App → Features → In-App Purchases
- [ ] 创建一次性买断产品：
  - Reference Name：FilmYears Unlock
  - Product ID：`com.yourcompany.filmyears.unlock`
  - Type：Non-Consumable
  - Price：$8.99 USD（其他地区自动换算）
  - 本地化名称/描述：中英文
  - **截图**：准备买断功能的介绍图（审核需要）
- [ ] **StoreKit Configuration File**（本地测试用）：
  - Xcode → File → New → File → StoreKit Configuration File
  - 添加与 App Store Connect 中相同的 Product ID 和价格
  - 在 Scheme 的 Run 参数中指定此配置文件

---

## 5. 设计资源准备

### 5.1 Assets.catalog
- [ ] **App Icon**：1024pt 全尺寸（App Store 需要），自动生成其他尺寸
  - 可使用 Xcode 16 的 AI App Icon 生成（需开发者账户登录 Apple Intelligence）
  - 或从设计师处获取设计稿导出
- [ ] **Accent Color**：暖琥珀色 `#c8963e` 在 Asset Catalog 中设定
- [ ] **Symbols / SF Symbols**：优先使用 SF Symbols 6（iOS 18 新增符号集）
  - 关键符号：`film.stack`、`circle.dotted`、`photo.badge.plus`、`gearshape`、`square.and.arrow.down`

### 5.2 设计 Token（可选）
- [ ] 可创建一个 `DesignTokens.swift` 统一管理：
  - 圆角常量（`.radiusSm = 6`, `.radiusMd = 10`, `.radiusLg = 14`）
  - 间距常量（`.spacingXs = 4`, `.spacingSm = 8`, `.spacingMd = 16`, `.spacingLg = 24`, `.spacingXl = 32`）
  - 字阶（`.display`, `.heading1`, `.heading2`, `.body`, `.caption`）

### 5.3 占位照片
- [ ] 准备一组色块/渐变占位图（用于开发阶段帧列表预览）
  - 约 10 种不同色调，代表不同季节/心情
- [ ] 可用 SF Symbol `photo` 作为纯空态占位

---

## 6. 第三方依赖管理

### 6.1 依赖评估
本项目设计为**无第三方依赖**（纯 Apple 原生框架），但需确认不需要：

| 可能的依赖 | 决定 | 理由 |
|-----------|------|------|
| Kingfisher / SDWebImage | ❌ 不需要 | 照片全部本地存储，无需远程加载 |
| RevenueCat | ❌ 不需要 | 产品单一买断，StoreKit 2 直接处理 |
| Firebase | ❌ 不需要 | 所有照片用户私有 iCloud，无后端 |
| Lottie | ❌ 不需要 | 动画用 SwiftUI 原生实现 |

> ✅ 保持零第三方依赖，减少审核风险和维护成本。

---

## 7. 版本控制

### 7.1 Git 初始化
- [ ] `git init`
- [ ] `.gitignore`：[iOS Swift 模板](https://github.com/github/gitignore/blob/main/Swift.gitignore)

```gitignore
# Xcode
*.xcworkspace
xcuserdata/
DerivedData/
*.ipa

# CocoaPods (即使不用也保留)
Pods/

# Swift Package Manager
.build/
Package.resolved

# macOS
.DS_Store
```

- [ ] 初始 commit：`git add . && git commit -m "feat: initial project setup"`

### 7.2 Git 分支策略（可选但推荐）

```
main          ─── 稳定版本，只合入已验证的 develop
develop       ─── 每日开发集成分支
feature/ob-* ─── Onboarding 功能分支
feature/hm-* ─── 首页功能分支
feature/rv-* ─── 卷轴功能分支
...
```

---

## 8. Widget Extension Target

- [ ] Xcode → File → New → Target → **Widget Extension**
  - Product Name：`FilmYearsWidgets`
  - Language：Swift
  - **Bundle Identifier**：`com.yourcompany.filmyears.widgets`
- [ ] 确保 Widget Target 的 Minimum Deployment 也是 **iOS 18.0**
- [ ] 确保 Widget Target 勾选相同的 **App Group**
- [ ] 确认 Widget Target 的 Info.plist 不包含不必要的 Capabilities

---

## 9. 本地化准备

- [ ] Xcode → Project → Info → Localizations
  - 添加 **English**（Development Language）
  - 添加 **简体中文**（zh-Hans）
- [ ] **String Catalog**（iOS 16+ 方式）：
  - Xcode → File → New → File → String Catalog
  - 命名为 `Localizable.xcstrings`
  - 后续开发中将所有用户可见文字抽取到此文件

需要本地化的文案范围：
- App 名称（Info.plist CFBundleDisplayName）
- Onboarding 引导文案
- 帧编辑界面文案
- 设置页面全部文案
- Widget 文案
- IAP 产品描述
- 隐私政策（网页）

---

## 10. 测试策略

### 10.1 Xcode Scheme 配置
- [ ] 创建 **Debug** Scheme：使用 StoreKit Configuration File（本地测试 IAP）
- [ ] 创建 **Release** Scheme：指向生产环境（App Store Connect 的 IAP）
- [ ] `-com.apple.CoreData.ConcurrencyDebug 1` 添加到 Scheme 的 Arguments（SwiftData 沿用 CoreData 的调试标志）

### 10.2 XCTest 准备
- [ ] 项目已自动包含 Unit Test Target（`FilmYearsTests`）
- [ ] 创建 UI Test Target（`FilmYearsUITests`）
- [ ] 测试数据工厂：`ModelPreview.swift`（注入 3 卷胶卷 + 部分已填充帧的预览数据）

### 10.3 手动测试清单
- [ ] Xcode 真机运行（签名配置通过）
- [ ] 多语言切换验证（中/英文 UI 完整性）
- [ ] 深色/浅色模式切换
- [ ] Dynamic Type 调节（辅助功能 → 字体大小）
- [ ] 辅助功能 → 减少动画 → 确认动画禁用

---

## 11. CI/CD（可选，但推荐）

### 11.1 GitHub Actions 或 Xcode Cloud
- [ ] 至少配置 **Build 验证**：每次 PR 自动编译
- [ ] 配置 **Test 运行**：单元测试 + UI 测试自动运行
- [ ] 配置 **Archive + Export**：自动生成 .ipa（用于 TestFlight 分发）

### 11.2 TestFlight
- [ ] App Store Connect → App → TestFlight
- [ ] 添加内部测试员（开发团队成员邮箱）
- [ ] 首次提交需要审核（之后同版本更新无需重复审核）

---

## 12. 逐项检查快速总表

```
编码前必须完成：
☐ Xcode 16 + iOS 18 SDK 就绪
☐ Developer Account 已配置
☐ Bundle ID 已注册
☐ App Groups + CloudKit + Photo Library Capability 已添加
☐ App Store Connect 应用记录已创建
☐ CloudKit Container 已创建
☐ IAP Product 已配置 + StoreKit Config File 已创建
☐ Widget Extension Target 已添加
☐ Git 仓库已初始化
☐ 真机已连接可运行

开发早期完成：
☐ String Catalog 已创建
☐ 设计 Token 文件已创建
☐ 测试数据工厂已创建
☐ App Icon 就位
☐ 占位照片资源就位

上线前完成：
☐ App Store 截图（6.7"/6.5"/5.5" 三套 + iPad）
☐ 隐私政策 URL
☐ 审核备注（说明 ScreenTime/Focus 为可选）
☐ 测试员 TestFlight 分组
```

---

## 13. 可能踩的坑

| 坑 | 表现 | 解决 |
|----|------|------|
| CloudKit container 名称不一致 | 运行时崩溃 `NSCocoaErrorDomain` | Xcode → Signing & Capabilities iCloud container 名称与 ModelConfiguration 中 `cloudKitContainerIdentifier` 完全一致（含 `iCloud.` 前缀） |
| App Group 两个 Target 未同时勾选 | Widget 读取不到数据 | 主 App Target 和 Widget Target 的 App Groups Capability 都勾选同一个 ID |
| Swift 6 编译错误 `Sendable` 相关 | `@Model` 类跨 actor 传递报错 | `@Model` 已经隐式 `@unchecked Sendable`，但如果自定义类型含非 Sendable 属性需加 `@preconcurrency import` |
| Widget 无法刷新 | 小组件一直显示旧数据 | 确认 `TimelineProvider` 返回的 `Timeline` 设置了合理的 `policy`；主 App 修改数据后手动调用 `WidgetCenter.shared.reloadTimelines(ofKind:)` |
| 照片文件被 iCloud 备份 | 用户 iCloud 空间被占满 | Documents/ 目录默认会被 iCloud 备份，在 `Info.plist` 中添加 `UIFileSharingEnabled = NO` 且 `LSSupportsOpeningDocumentsInPlace = NO`；照片路径使用 `Application Support/` 替代 |
