# FilmYears MVP 产品文档

> 产品定位：**胶片‑年轮时间可视化记忆 App（iOS，海外市场）**
> 核心概念：每一年是一卷胶卷；每一天是胶卷内一张胶片帧。新一天生成空白底片，用户可填入照片与简短备注；允许回溯历史年份补录；年轮圆环聚合展示一整年记忆密度。
> 设计哲学：只回望**已经活过的时光**，不渲染未来、不做生命倒计时焦虑叙事。
> 技术栈：SwiftUI \+ CoreData \+ CloudKit \(iCloud 同步\) \+ WidgetKit；**无后端服务器**。
> 目标平台：iPhone /iPad；Mac \(Catalyst\) 支持 Universal Purchase；Apple Watch MVP 暂不实现。
> 变现模式：免费下载 \+ 一次性买断 Universal Purchase $8\.99。
> 版本：MVP 1\.0
> 
> 

## 1\. 核心用户故事

1. 午夜到来，App 生成当年胶卷的一张空白今日胶片帧；用户在主屏幕小组件看见空白底片，点击快速给今日帧添加一张照片 \+ 单行备注。

2. 用户可以选择任意历史年份胶卷，滚动到过去任意一天，回填老照片，补写当日备注。

3. 两种可视化视图：胶片卷轴看线性时间故事；年轮圆环看一整年记忆聚合纹理。

4. 全部照片、数据存储本地 \+ 用户私有 iCloud；服务商服务器不接触任何用户图片。

5. ScreenTime、系统 Focus 模式为可选授权，授权后给胶片帧增加色彩纹理反馈，不授权 App 完整可用。

## 2\. 术语定义

- **胶卷 FilmRoll**：对应一自然年，如 2026 胶卷；包含该年全部日期的胶片帧。**不会预生成未来年份胶卷**。

- **胶片帧 FilmFrame**：代表某一天；一条记录，可空白 / 填入 1 张照片、单行备注。

- **空白帧**：已存在的日期帧，没有填入照片，可以随时补填。

- **年轮 RingView**：单圈对应一卷胶卷；帧的填充状态、Focus、ScreenTime 映射圆环纹理亮度。

- **今日帧 Today‑Frame**：系统当前日期对应的胶片帧；主屏幕小组件核心样式。

- **出生年份 BirthYear**：用户在 Onboarding 设置的出生年份，决定胶卷列表的起始年份。App 只会生成从出生年份到当前年份的胶卷，绝不生成出生前的年份胶卷。

## 3\. MVP 功能范围

### 3\.1 App 主模块

#### 3\.1\.0 Onboarding 首次启动引导页

1. 首次启动流程：用户下载 App 后第一次打开时，进入 Onboarding 引导页（仅首次展示，后续启动直接进入胶卷列表页）。

2. 核心操作：用户输入出生日期（年月日选择器）。

3. 确认出生日期后，App 立即执行初始化：
   - 计算从出生年份至当前年份的全部年份。
   - 为每个年份创建一卷胶卷 FilmRoll。
   - 依据当前实际日期，为已到达的每一天创建空白胶片帧 FilmFrame（不留未来空白帧）。
     - 示例：出生日期 1995-06-15，当前日期 2026-07-29 → 生成 1995 ~ 2026 共 32 卷胶卷；
     - 1995 年仅生成 06-15 至 12-31 的帧，2026 年生成 01-01 至 07-29 的帧，中间年份生成全年帧。

4. 初始化完成后自动跳转至【胶卷列表页】，年份列表起始年份即出生年份。

5. 出生日期写入本地存储后不可在 App 内随意修改；如需重置，需前往「设置 → 清除所有数据」，重置后重新进入 Onboarding 流程。

6. 设计约束：
   - 出生日期验证：必须为过去日期，不允许选择未来日期。
   - 出生日期仅用于确定胶卷起始年份，App 绝不展示「从出生至今已过去多少天」等倒计时/生命剩余叙事。

#### 3\.1\.1 首页：胶卷列表页

1. 列表展示从**出生年份到当前年份的全部胶卷**，按倒序排列（最新年份在最上方）。

2. 胶卷列表项 UI：迷你胶片缩略 \+ 年份数字；显示本卷已经填充照片的帧数量。

3. 点击胶卷条目：进入该年【胶片卷轴视图】。

4. 进入 App 时本地逻辑校验：

    - 检查今日是否已经生成 FilmFrame；未生成则创建今日帧并归属到对应年份胶卷。

    - 不会预先生成未来任何日期帧、未来胶卷。

> 限制：iOS 无精准午夜后台任务；跨天帧生成策略为**App 前台打开时补生成今日帧**。
> 
> 

5. **底部 TabBar 切换（新增）**：首页底部固定 TabBar，两个标签页切换视图。

    - **🎞️ 胶卷列表**：默认标签页，按倒序展示所有年份胶卷。

    - **◎ 年轮总览**：切换到年轮总览模式，堆叠展示从出生年份至当前年份的全部年轮圆环（复用 3\.1\.3 模式 B）。各年轮按由外到内（最早年份在外圈、最近年份在内圈）排列。

    - 切换 Tab 不影响导航状态；点击年轮总览中的某一年轮可进入该年【胶片卷轴视图】。

#### 3\.1\.2 胶片卷轴视图（单卷胶卷）

1. 纵向滚动卷轴，一帧 = 一天；采用懒加载，只渲染可视区域帧，保证性能。

2. 帧 UI：胶片齿孔边框、胶片颗粒滤镜 Shader。

    - 空白帧：空白底片样式。

    - 已填充帧：显示照片，叠加胶片颗粒滤镜；底部展示单行备注（截断）。

3. 帧色彩映射（可选权限）

    - Focus 活跃：帧齿孔暖色调高亮。

    - ScreenTime 高分：胶片颗粒纹理加深。

4. 交互

    - 点击任意帧：弹出编辑弹窗。

        - 从相册选取 1 张照片填入；一帧仅支持 1 张照片。

        - 填写 / 修改单行备注（最大 80 字符）。

        - 删除照片，恢复空白帧。

5. 视图内提供按钮，切换打开【年轮聚合视图】（当前胶卷）。

#### 3\.1\.3 年轮聚合视图 RingView

1. 模式 A：单卷模式，只渲染当前选中胶卷的一圈年轮。

2. 模式 B：多年总览模式，堆叠所有已存在胶卷的年轮圆环。
   - 入口：可从首页视图切换进入（首页「年轮总览」模式），也可从设置页面进入。

3. 数据映射：

    - 该日有照片：圆环对应角度区域变亮。

    - Focus、ScreenTime 数据映射纹理深浅。

4. 点击年轮某段区域，跳转回胶片卷轴，定位对应日期帧。

5. 支持导出当前年轮为图片。

#### 3\.1\.4 设置页面

1. iCloud 同步开关（CloudKit）。

2. ScreenTime 权限跳转、Focus 权限跳转；提示：权限为可选，不开不影响核心使用。

3. 深色 / 浅色模式切换。

4. 购买解锁按钮（Universal Purchase 买断）；恢复购买。

5. 隐私政策链接。

6. 导出功能入口：导出单帧图片、导出年轮图片。

7. 清除所有数据入口：清除出生日期、全部胶卷及帧数据，重置 App 回到 Onboarding 状态。

### 3\.2 WidgetKit 小组件（主屏幕 \+ 锁屏 \+ StandBy）

> 小组件全部支持：小号 1×1、中号 2×2；StandBy 复用中号布局。
> 
> 

#### 小组件 1：今日帧 Today‑Frame【新增，MVP 必做】

> 绑定系统真实今日帧；不支持自定义选择历史帧（二期）
> 
> 

- 状态 1｜空白未填充：胶片边框 \+ 颗粒纹理；提示文字 `Today’s Frame · Add a photo`

- 状态 2｜已填充：胶片边框包裹照片，底部简短日期 / 备注。

- 点击深度链接：`widget://open‑today‑frame`，打开 App，自动定位到今年胶卷的今日帧编辑位置。

- 更新触发：跨天系统刷新；用户增删今日帧照片 / 备注主动刷新小组件。

- 齿孔色调跟随 App 内逻辑：Focus、ScreenTime 映射色彩。

#### 小组件 2：随机胶片帧 Random‑Frame

随机抽取一条已经填入照片的历史胶片帧展示；点击跳转对应胶卷 \+ 对应帧。

#### 小组件 3：年轮缩略 Year‑Ring

展示某一卷胶卷的年轮缩略概览。

#### 锁屏小组件

极简今日帧提醒；只做状态提示，不展示大图。

### 3\.3 数据同步与存储

1. 本地存储：CoreData 保存胶卷、帧元数据。

2. iCloud CloudKit 同步：

    - FilmRoll、FilmFrame 元数据同步跨设备。

    - 照片作为 CloudKit Asset 保存在用户私有 iCloud 空间；开发者服务器**不存储原图**。

3. 冲突处理：CloudKit 默认冲突策略；照片资源优先保留最新修改。

### 3\.4 变现｜免费版 vs 买断版 $8\.99 Universal Purchase

**免费版限制**

1. 最多可以为 **60 个胶片帧填入照片**；空白帧生成数量无上限。

2. 导出图片带 FilmYears 水印。

3. 部分小组件样式锁定不可选。

**买断解锁全部（一次性）**

1. 不限数量填充照片帧。

2. 全部小组件样式可用。

3. 全部导出无水印高清。

4. 解锁后续版本新增功能。

### 3\.5 MVP 明确砍掉（不进入 1\.0，二期迭代）

1. ❌ 一帧多张照片；长篇日记文本。

2. ❌ Apple Intelligence AI 回顾文案。

3. ❌ Apple Watch App 完整浏览。

4. ❌ PDF 完整胶卷长卷导出。

5. ❌ App 内社交、社区。

6. ❌ 习惯打卡、倒计时、Todo 清单。

7. ❌ 小组件自定义选择历史某帧作为小组件。

## 4\. 二期迭代规划（MVP 上线之后）

1. Apple Intelligence 本地 AI：选中一卷胶卷生成温柔年度回顾文案。

2. Apple Watch：胶卷列表、随机帧浏览。

3. 帧高光标记功能。

4. 完整胶卷长卷 PDF 导出。

5. 用户自选历史帧放到小组件。

6. 更多胶片滤镜主题包。

## 5\. 关键数据模型伪代码

```swift
// 胶卷：代表一年
struct FilmRoll {
    var year: Int
    var createDate: Date
    var frames: [FilmFrame] // 该年全部胶片帧
}

// 胶片帧：代表一天
struct FilmFrame {
    var date: Date // 精确到年月日，唯一
    var photoAsset: CKAsset? // iCloud图片资源，可为nil
    var note: String? // 单行备注，最多80字符
    var focusActive: Bool? // 可选授权
    var screenTimeScore: Double? // 可选授权
    var isFilled: Bool { photoAsset != nil }
}

// 用户设置：首次启动 Onboarding 时写入
struct UserSettings {
    var birthDate: Date // 出生日期，决定胶卷起始年份
    var onboardingCompleted: Bool // 是否完成引导
    var appFirstLaunchDate: Date // 首次启动日期
}
```

## 6\. 风险与技术注意事项

1. **帧生成时机**：iOS 没有可靠午夜后台执行；采用 App 打开时校验并补生成今日帧。

2. **性能**：胶片卷轴必须懒加载；不一次性渲染全部 365 帧，防止滚动卡顿。年轮圆环绘图做性能优化。

3. **权限策略**：ScreenTime、Focus 为**完全可选**；没有授权 App 全部核心功能可用，仅缺少色彩纹理。

4. **审核红线（非常重要）**

    - UI、文案**绝不展示未来帧、未来胶卷、剩余生命倒计时**。

    - 叙事只讲：look back on days/years you have lived（回望你活过的时光）。

    - 禁止死亡、剩余寿命相关描述。

5. **隐私卖点文案**

> All photos stay on‑device \& your private iCloud\. Never uploaded to our servers\.
> 所有照片保存在设备和你的私有 iCloud，不会上传到开发者服务器。
> 
> 

6. **出生日期设置风险**：出生日期决定所有胶卷的起始范围，设置后不应允许用户随意修改（防止有意调整日期绕过免费版帧数限制）。如需修改，应在设置页面提供「清除所有数据」重置入口，重置后重新进入 Onboarding 流程。

## 7\. App Store 文案初稿

### App 标题

FilmYears · Film \& Ring Time Widget

### 副标题

Each year is a roll of film, every day one frame\.

### App 描述

FilmYears visualizes your life as film rolls and tree‑ring diagrams\.

Each year becomes one film roll\. Every new day arrives as a blank film frame\.
Add a photo and short note to today’s frame directly from your home‑screen widget\.
You can also go back to past years and fill old frames with your memories\.

‑ Today‑Frame home‑screen widget: quick access to record your day
‑ Scroll film‑reel view to browse days in a year
‑ Tree‑ring ring‑view: see memory density of each whole year
‑ iCloud sync your rolls and frames across iPhone \& iPad
‑ ScreenTime \& Focus mode optional integration for subtle frame textures
‑ All photos stay on your device and private iCloud\. No server uploads\.

No future frames, no life‑countdown anxiety\. Only look back on the days you have lived\.

In‑App Purchase: one‑time Universal Purchase to unlock unlimited photo frames, watermark‑free export and all widget styles\.

> Keywords（ASO）：life calendar widget, film reel time, tree ring visualizer, memory journal, mindful time, photo diary, life in weeks widget
> 
> 

### 截图文案要点

1. 胶卷列表页：Your years as film rolls

2. 胶片卷轴：Each day is one film frame

3. 年轮视图：Tree‑ring overview of your year

4. 今日帧小组件空白：Today’s Frame — Capture your day

5. 今日帧小组件填充：Fill frames with your photos

如果你需要，我可以继续输出：开发任务拆解清单，或者 WidgetKit 今日帧示例代码片段。

> （注：部分内容可能由 AI 生成）
