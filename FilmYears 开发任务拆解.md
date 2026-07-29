# FilmYears MVP — 开发任务拆解

> 基于 FilmYears MVP 产品文档 + 技术文档（SwiftUI + SwiftData）
> 目标：可并行开发的模块化任务清单
> 估算单位：人·天（1 人·天 = 1 个全职开发者 1 个工作日）

---

## 缩写说明

| 缩写 | 含义 |
|------|------|
| P0 | 阻塞性任务，必须最先完成 |
| P1 | 核心功能，MVP 必备 |
| P2 | 重要但不阻塞核心流程 |
| P3 | 锦上添花，可延后 |

---

## Phase 0：项目脚手架（P0）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| S-01 | 创建 Xcode 项目 | SwiftUI + SwiftData + iOS 18.0 最低部署，Git 初始化 | 0.5d | — |
| S-02 | SwiftData ModelContainer | 配置 3 个 @Model（FilmRoll/FilmFrame/AppSettings），CloudKit 容器标识 | 0.5d | S-01 |
| S-03 | App Group + Widget Target | 创建 Widget Extension target，配置 App Group 共享目录 | 0.5d | S-01 |
| S-04 | iCloud Entitlements | 添加 CloudKit container entitlement，后台模式 remote-notification | 0.5d | S-01 |
| S-05 | 设计 Token 文件 | DesignTokens.xcassets（颜色/字阶/圆角），AppIcon | 0.5d | — |

**Phase 0 总计：2.5 人·天**

---

## Phase 1：数据层（P0）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| D-01 | FilmRoll @Model | year（unique）、createdAt、isInitialized、@Relationship frames | 0.5d | S-02 |
| D-02 | FilmFrame @Model | date（unique）、photoPath、note、photoModifiedAt、focusActive、screenTimeScore、@Relationship roll | 0.5d | S-02 |
| D-03 | AppSettings @Model | id（unique "app_settings"）、birthDate、onboardingCompleted、firstLaunchDate、isCloudSyncEnabled、计算属性 birthYear/currentYear | 0.5d | S-02 |
| D-04 | PhotoManager Service | savePhoto/loadPhoto/deletePhoto，Documents/frames/ 目录管理 | 0.5d | D-02 |
| D-05 | RollGenerator Service | generateInitialRolls（从出生日期批量生成）、ensureTodayFrame（每日补帧） | 1d | D-01, D-02, D-03 |
| D-06 | Preview Data | ModelPreview 扩展、MockData 生成（3 卷胶卷 + 部分填充的帧） | 0.5d | D-01, D-02 |

**Phase 1 总计：3.5 人·天**

---

## Phase 2：Onboarding 引导流程（P0）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| OB-01 | OnboardingView UI | 品牌 Logo + 副标题 + DatePicker 选择出生日期 + 开始按钮 | 0.5d | D-03 |
| OB-02 | 日期验证逻辑 | 出生日期必须为过去日期，不允许未来日期 | 0.25d | OB-01 |
| OB-03 | 初始化胶卷 | 调用 RollGenerator.generateInitialRolls → 创建 AppSettings → 标记 onboardingCompleted | 0.5d | D-05, OB-01 |
| OB-04 | Onboarding → Home 过渡 | 条件路由：onboardingCompleted ? ContentView : OnboardingView，带淡入动画 | 0.25d | OB-03 |
| OB-05 | 首次启动闪屏适配 | 无 SwiftData 数据时显示 Onboarding，已存在数据时直接跳 Home | 0.25d | OB-04 |

**Phase 2 总计：1.75 人·天**

---

## Phase 3：首页 — 胶卷列表 / 年轮总览（P1）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| HM-01 | MainTabView 框架 | 双 Tab 底部 TabBar（🎞️ 胶卷列表 / ◎ 年轮总览），选中态琥珀色 | 0.5d | S-01 |
| HM-02 | FilmRollListView | @Query 按年份倒序取全部 FilmRoll，List + NavigationLink | 1d | D-01, D-06 |
| HM-03 | 年份条目 UI | MiniFilmStrip（48×48 微缩胶片 + 齿孔装饰 + 填充数量）+ 年份 + 帧计数 + DensityBar | 0.5d | HM-02 |
| HM-04 | 年轮总览 — SVG 同心圆 | 所有年份同心圆环叠加，琥珀色=已填充，深灰=空白，按年份从内到外排列 | 1.5d | D-01, D-06 |
| HM-05 | 年轮总览 — 年份行列表 | 每行 40px 微缩年轮 + 年份 + 帧计数，点击跳转 ReelView | 0.5d | HM-04 |
| HM-06 | TabBar 切换动画 | Tab 切换时内容区淡入淡出 | 0.25d | HM-01 |
| HM-07 | 设置按钮 + 导航 | 导航栏右侧⚙️按钮 → SettingsView | 0.25d | HM-01 |

**Phase 3 总计：4.5 人·天**

---

## Phase 4：胶片卷轴视图（P1）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| RV-01 | 导航栏 | 返回按钮 + "2026 年" 标题 + 右侧"🪵 年轮"按钮 | 0.25d | HM-02 |
| RV-02 | LazyVStack 帧列表 | 按日期排序的帧列表，懒加载，仅渲染可见帧 | 0.5d | D-02 |
| RV-03 | FilmFrameCard 组件 | 左右齿孔（12px SprocketHoles）+ 帧主体（照片/空白+颗粒纹理）+ 底部信息栏 | 1d | D-02 |
| RV-04 | 空白帧状态 | 空白底片样式：📷图标 + "空白底片"文字，点击可编辑 | 0.25d | RV-03 |
| RV-05 | 已填充帧状态 | 显示照片（异步加载）+ 胶片颗粒纹理覆盖层 + 备注文字 | 0.5d | D-04, RV-03 |
| RV-06 | 帧色彩映射 | Focus 活跃→齿孔暖色调高亮；ScreenTime 高分→颗粒纹理加深 | 0.5d | RV-03 |
| RV-07 | EditFrameSheet（下半部分） | 底部弹出 Sheet，拖拽手柄 + 日期标题 + 照片区域（轻点添加/更换）+ 备注输入框（80 字限制 + 字符计数） | 1d | D-04, RV-03 |
| RV-08 | 保存帧 | 写入 photoPath/note → 更新 FilmFrame → 刷新列表 | 0.5d | D-04, RV-07 |
| RV-09 | 删除照片 | 删除本地文件 + 清空 photoPath/note → 恢复空白帧 | 0.25d | D-04, RV-07 |

**Phase 4 总计：4.25 人·天**

---

## Phase 5：年轮聚合视图 RingView（P1）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| RG-01 | RingChart 单卷年轮 | Shape 或 Canvas 绘制圆环，每段对应一天，琥珀色=已填充/深灰=空白 | 1.5d | D-02 |
| RG-02 | 年轮交互 | 点击某段→跳回 ReelView 并 ScrollViewReader 滚动到对应日期帧 | 0.5d | RG-01, RV-02 |
| RG-03 | 中心标签 | 年份 + "X 帧回忆"文字 | 0.25d | RG-01 |
| RG-04 | 年轮导出为图片 | ImageRenderer → UIImage → save to Photos | 0.5d | RG-01 |
| RG-05 | 图例 | 琥珀色圆点="已填充"，深灰色圆点="空白" | 0.25d | RG-01 |
| RG-06 | 年轮内部模式 B（多年总览） | 堆叠所有年轮圆环，用于首页 Tab 的「年轮总览」和设置页面入口 | 0.5d | RG-01, HM-04 |

**Phase 5 总计：3.5 人·天**

---

## Phase 6：设置页面（P1）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| ST-01 | 设置页面框架 | 分组列表样式，返回导航 | 0.25d | — |
| ST-02 | iCloud 同步开关 | Toggle 绑定 isCloudSyncEnabled | 0.25d | D-03 |
| ST-03 | 深色/浅色模式 | Toggle 控制 colorScheme | 0.25d | — |
| ST-04 | 购买解锁入口 | "$8.99 解锁全部功能" + 恢复购买 | 0.5d | IAP-02 |
| ST-05 | 清除所有数据 | 删除全部 SwiftData 记录 + 删除照片文件 → 重置 Onboarding | 0.5d | D-01, D-02, D-03 |
| ST-06 | 隐私政策链接 | 打开外部 URL（SafariView） | 0.25d | — |
| ST-07 | 确认清除弹窗 | Modal Sheet 样式，不可撤销警告，取消/确认按钮 | 0.5d | ST-05 |
| ST-08 | 出生日期只读展示 | 显示当前 birthDate（不可修改，仅展示） | 0.25d | D-03 |

**Phase 6 总计：2.25 人·天**

---

## Phase 7：WidgetKit 小组件（P1）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| WT-01 | AppGroup 数据共享 | 将 ModelContainer 配置为 App Group 共享路径，Widget 可读取 | 0.5d | S-03 |
| WT-02 | TodayFrameProvider | TimelineProvider，15 分钟刷新间隔，读取今日帧填充状态 | 0.5d | WT-01, D-02 |
| WT-03 | TodayFrameWidget UI | 空白态（胶片边框 + "Today's Frame · Add a photo"）+ 已填充态（照片 + 日期） | 1d | WT-02 |
| WT-04 | TodayFrame 深度链接 | widget://open-today-frame → 打开 App 跳转今年胶卷今日帧编辑 | 0.5d | WT-03 |
| WT-05 | RandomFrameWidget | 随机抽取已填充帧展示，点击跳转对应胶卷+帧 | 0.75d | WT-01 |
| WT-06 | YearRingWidget | 展示某卷胶卷的年轮缩略（RingChart Snapshot） | 0.75d | RG-01, WT-01 |
| WT-07 | 锁屏小组件 | 极简今日帧状态提示（小尺寸） | 0.5d | WT-03 |
| WT-08 | StandBy 模式 | 复用中号布局 | 0.25d | WT-03 |

**Phase 7 总计：4.25 人·天**

---

## Phase 8：IAP 买断与免费版限制（P2）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| IAP-01 | StoreKit 配置 | StoreKit Configuration File + App Store Connect 产品配置 | 0.5d | — |
| IAP-02 | PurchaseManager | Product.products 请求 + purchase + restore + Transaction.updates 监听 | 1d | IAP-01 |
| IAP-03 | UserDefaults.isUnlocked | 存储解锁状态（关联 UserDefaults + StoreKit 验证） | 0.25d | IAP-02 |
| IAP-04 | 免费版帧数限制 | 最多 60 个帧可填入照片；插入照片前检查 isUnlocked + 已填充帧计数 | 0.5d | IAP-03, RV-08 |
| IAP-05 | 导出水印 | 免费版导出图片叠加 FilmYears 水印 | 0.25d | RG-04 |
| IAP-06 | 小组件样式锁定 | 部分 widget style 需要 isUnlocked 才可切换 | 0.25d | IAP-03, WT-03 |
| IAP-07 | 买断 UI 文案 | 设置页面显示当前状态（未解锁/已解锁），购买按钮状态联动 | 0.25d | IAP-02, ST-04 |

**Phase 8 总计：3 人·天**

---

## Phase 9：iCloud + CloudKit 同步（P2）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| CK-01 | CloudKit 容器配置 | ModelConfiguration 添加 cloudKitContainerIdentifier | 0.5d | S-04 |
| CK-02 | 冲突策略 | photoModifiedAt 时间戳 + merge policy（last-write-wins） | 0.5d | D-02, CK-01 |
| CK-03 | 同步状态指示器 | 设置页面显示 iCloud 同步状态（进行中/已同步/未同步） | 0.5d | CK-01 |
| CK-04 | CKAsset 照片存储 | 照片作为 CloudKit Asset 存储在用户私有 iCloud 空间 | 1d | D-04, CK-01 |
| CK-05 | 跨设备测试 | 多设备登录同一 iCloud 账号验证同步一致性 | 0.5d | CK-04 |

**Phase 9 总计：3 人·天**

---

## Phase 10：动画与打磨（P3）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| AN-01 | 屏幕转场动画 | Onboarding→Home 淡入、Tab 切换、Push/Pop 导航自定义过渡 | 0.5d | — |
| AN-02 | 胶片颗粒 Shader | Metal Shader 或 CoreImage 实时胶片颗粒滤镜 | 1d | RV-05 |
| AN-03 | 帧卡片入场动画 | 逐帧 fade-in + 轻微上移交错入场 | 0.5d | RV-02 |
| AN-04 | Sprocket 齿孔呼吸动画 | 齿孔圆点脉冲透明度 | 0.25d | RV-03 |
| AN-05 | 年轮绘制动画 | 圆环从 0 到完整周长 stroke 动画 | 0.5d | RG-01 |
| AN-06 | Haptic Feedback | 编辑保存、删除照片等操作的触觉反馈 | 0.25d | RV-08 |
| AN-07 | 空状态/错误状态 | 无数据时的引导占位、加载失败重试 | 0.5d | — |

**Phase 10 总计：3.5 人·天**

---

## Phase 11：无障碍与国际化（P3）

| ID | 任务 | 描述 | 估算 | 依赖 |
|----|------|------|------|------|
| AX-01 | VoiceOver 标签 | 所有可交互元素 accessibilityLabel + accessibilityHint | 0.5d | — |
| AX-02 | Dynamic Type | 使用 Dynamic Type 字体（headline/body/caption 等）而非固定字号 | 0.25d | — |
| AX-03 | Reduce Motion | @Environment(\.accessibilityReduceMotion) 禁用动画 | 0.25d | AN-01 |
| AX-04 | 颜色对比度 | 验证 WCAG AA（4.5:1 正常文字，3:1 大文字） | 0.25d | — |
| AX-05 | 本地化字符串 | 所有用户可见文案抽取 String Catalog（至少 en/zh） | 0.5d | — |
| AX-06 | 深色模式适配 | 在深色/浅色模式下验证全部界面可读性 | 0.25d | — |

**Phase 11 总计：2 人·天**

---

## 总工时汇总

| Phase | 内容 | 人·天 |
|-------|------|-------|
| Phase 0 | 项目脚手架 | 2.5 |
| Phase 1 | 数据层 | 3.5 |
| Phase 2 | Onboarding | 1.75 |
| Phase 3 | 首页 TabBar | 4.5 |
| Phase 4 | 胶片卷轴 | 4.25 |
| Phase 5 | 年轮聚合 | 3.5 |
| Phase 6 | 设置页面 | 2.25 |
| Phase 7 | WidgetKit | 4.25 |
| Phase 8 | IAP 买断 | 3.0 |
| Phase 9 | iCloud + CloudKit | 3.0 |
| Phase 10 | 动画与打磨 | 3.5 |
| Phase 11 | 无障碍与国际化 | 2.0 |
| **总计** | | **38 人·天** |

> 1 人全职开发约 **8 周**（38 工作日）；2 人团队约 **4 周**；3 人团队约 **2.5 周**。
> 以上含设计复核 + 代码 review + 简单 QA 验证时间，不含 App Store 提审周期。

---

## 推荐并行策略

```
Week 1-2          Week 3-4          Week 5-6          Week 7-8
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Phase 0      │  │ Phase 3      │  │ Phase 5      │  │ Phase 8      │
│ Phase 1      │  │ Phase 4      │  │ Phase 6      │  │ Phase 9      │
│ Phase 2      │  │              │  │ Phase 7      │  │ Phase 10     │
│              │  │              │  │              │  │ Phase 11     │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘

Phase 0+1+2 ─────▶ Phase 3+4 ──────▶ Phase 5+6+7 ────▶ Phase 8+9+10+11
(基础+Onboarding)  (首页+卷轴)       (年轮+设置+Widget) (IAP+同步+打磨)
```

---

## 风险标注

| 风险 | 影响 | 缓解 |
|------|------|------|
| SwiftData + CloudKit 在 iOS 18 上仍可能有兼容性问题 | 数据同步不可靠 | 保留 CoreData 回退方案；设置页面提供手动同步按钮 |
| Widget TimelineProvider 无法精确跨天刷新 | 今日帧状态更新延迟 | 配合 BackgroundTasks 定时刷新，App 打开时主动刷新 Widget |
| 年轮 365 段 SVG 渲染性能 | 低端设备卡顿 | 使用 Canvas API 替代 Shape 避免 View 层级爆炸；30 天为单位聚合渲染 |
| ScreenTime API 权限申请 | 审核被拒风险 | 标注为完全可选功能；不上传任何 ScreenTime 数据 |
| IAP 免费版帧数限制绕过 | 用户通过重置出生日期绕过 | 出生日期写入后不可修改（清除数据视为重置全 App） |
