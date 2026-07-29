# FilmYears 技术文档（SwiftUI + SwiftData）

> 版本：MVP 1.0
> 最低部署目标：iOS 18.0
> 技术栈：SwiftUI + SwiftData + CloudKit + WidgetKit
> Swift 语言模式：Swift 6（完整严格并发）
> 架构模式：MVVM + SwiftData 驱动

---

## 1. 整体架构分层

```
┌─────────────────────────────────────────────────┐
│  View Layer (SwiftUI)         @MainActor        │
│  OnboardingView / HomeView / ReelView /         │
│  RingView / SettingsView / EditFrameSheet       │
├─────────────────────────────────────────────────┤
│  ViewModel Layer              @Observable       │
│  FilmRollViewModel / FrameViewModel /           │
│  OnboardingViewModel / AppViewModel             │
├─────────────────────────────────────────────────┤
│  Service Layer                sendable func     │
│  RollGenerator / FrameManager /                 │
│  CloudKitSyncService / IAPManager               │
├─────────────────────────────────────────────────┤
│  Data Layer (SwiftData + CloudKit)  @Model      │
│  FilmRoll / FilmFrame / AppSettings             │
│  └─ ModelActor for background operations        │
└─────────────────────────────────────────────────┘
```

### Swift 6 并发边界说明

| 层级 | 隔离域 | 说明 |
|------|--------|------|
| View | `@MainActor`（隐式） | SwiftUI 6 所有 View 自动在主线程 |
| ViewModel | `@MainActor` + `@Observable` | 属性变化自动触发 UI 刷新 |
| Service | 全局 actor 或 `sendable` 函数 | RollGenerator 使用 `ModelActor` 后台写入 |
| SwiftData | `@ModelActor` | iOS 18 新增的 actor 隔离数据操作 |

---

## 2. SwiftData 数据模型

### 2.1 FilmRoll — 胶卷（对应一年）

```swift
import SwiftData
import Foundation

@Model
final class FilmRoll {
    /// 年份（如 2026），唯一标识
    @Attribute(.unique) var year: Int
    
    /// 创建时间
    var createdAt: Date
    
    /// 该胶卷是否已完成初始化（所有已到达日期的帧已生成）
    var isInitialized: Bool
    
    /// 反向关联到该年的所有帧
    @Relationship(deleteRule: .cascade) var frames: [FilmFrame] = []
    
    init(year: Int) {
        self.year = year
        self.createdAt = .now
        self.isInitialized = false
    }
}

// MARK: - Computed properties
extension FilmRoll {
    /// 已填充帧数量
    var filledCount: Int { frames.filter(\.isFilled).count }
    
    /// 总帧数
    var totalCount: Int { frames.count }
    
    /// 填充百分比
    var fillRatio: Double { totalCount > 0 ? Double(filledCount) / Double(totalCount) : 0 }
}
```

### 2.2 FilmFrame — 胶片帧（代表一天）

```swift
@Model
final class FilmFrame {
    /// 日期（精确到年月日 UTC），在所属胶卷内唯一
    @Attribute(.unique) var date: Date
    
    /// 照片的本地 URL（存储在 app 的 Documents 目录）
    var photoPath: String?
    
    /// 单行备注（最多 80 字符）
    var note: String?
    
    /// 照片最后修改时间，用于 CloudKit 冲突处理
    var photoModifiedAt: Date?
    
    /// 可选：Focus 活跃状态
    var focusActive: Bool?
    
    /// 可选：ScreenTime 分数（0...1）
    var screenTimeScore: Double?
    
    /// 所属胶卷
    @Relationship(inverse: \FilmRoll.frames) var roll: FilmRoll?
    
    init(date: Date) {
        self.date = date
    }
}

// MARK: - Computed properties
extension FilmFrame {
    var isFilled: Bool { photoPath != nil }
    
    /// 格式化日期显示（如 "07/29 周三"）
    var displayDate: String {
        let df = DateFormatter()
        df.dateFormat = "MM/dd EEE"
        df.locale = Locale(identifier: "zh_CN")
        return df.string(from: date)
    }
    
    /// 格式化完整日期（如 "2026年7月29日"）
    var fullDate: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy年M月d日"
        df.locale = Locale(identifier: "zh_CN")
        return df.string(from: date)
    }
}
```

### 2.3 AppSettings — 用户设置（单例）

```swift
@Model
final class AppSettings {
    /// 使用 .unique 约束确保全局只有一条记录
    @Attribute(.unique) var id: String = "app_settings"
    
    /// 出生日期（决定胶卷起始年份）
    var birthDate: Date
    
    /// 是否已完成 Onboarding
    var onboardingCompleted: Bool
    
    /// 首次启动日期
    var firstLaunchDate: Date
    
    /// iCloud 同步开关
    var isCloudSyncEnabled: Bool = true
    
    init(birthDate: Date) {
        self.birthDate = birthDate
        self.onboardingCompleted = false
        self.firstLaunchDate = .now
    }
    
    /// 计算出生年份
    var birthYear: Int {
        Calendar.current.component(.year, from: birthDate)
    }
    
    /// 计算当前年份
    static var currentYear: Int {
        Calendar.current.component(.year, from: .now)
    }
}
```

---

## 3. SwiftData 容器配置（iOS 18 + CloudKit）

```swift
import SwiftData
import Foundation

/// iOS 18 的 ModelContainer 初始化方式
/// Swift 6 下容器自动处理 actor 隔离
@MainActor
struct PersistenceController {
    static let shared = PersistenceController()
    
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        return result
    }()
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        let schema = Schema([
            FilmRoll.self,
            FilmFrame.self,
            AppSettings.self
        ])
        
        // iOS 18 新 API：指定 CloudKit 容器标识
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(
                schema: schema,
                cloudKitContainerIdentifier: "iCloud.com.yourcompany.filmyears"
            )
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    /// iOS 18: 后台写入的 ModelActor
    func makeBackgroundActor() -> FilmRollActor {
        FilmRollActor(modelContainer: container)
    }
}

/// iOS 18 @ModelActor：后台安全写入，避免主线程阻塞
@ModelActor
actor FilmRollActor {
    /// 批量插入帧（Swift 6 安全并发）
    func insertInitialRolls(from birthDate: Date, to endDate: Date) throws {
        // ... 实现见 RollGenerator
    }
    
    /// 确保今日帧存在
    func ensureTodayFrame() throws {
        // ...
    }
}
```

---

## 4. App 入口 & 路由

```swift
import SwiftUI
import SwiftData

@main
struct FilmYearsApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(persistenceController.container)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var showOnboarding = true
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(completion: {
                    showOnboarding = false
                })
                .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showOnboarding)
    }
}
```

---

## 5. 核心 View 体系

### 5.1 OnboardingView

```swift
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var birthDate = Calendar.current.date(
        from: DateComponents(year: 1995, month: 6, day: 15)
    ) ?? .now
    let completion: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo & 品牌
            Text("🎞️").font(.system(size: 48))
            Text("FilmYears")
                .font(.largeTitle).bold()
                .foregroundColor(.accentColor)
            
            // 出生日期选择器
            DatePicker("出生日期",
                      selection: $birthDate,
                      in: ...Date.now,
                      displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            // 开始按钮
            Button("开始我的胶片年轮") {
                initializeApp()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .padding()
    }
    
    private func initializeApp() {
        let settings = AppSettings(birthDate: birthDate)
        context.insert(settings)
        
        // 初始化胶卷
        RollGenerator.generateInitialRolls(
            from: birthDate,
            to: .now,
            in: context
        )
        
        completion()
    }
}
```

### 5.2 MainTabView — 双 Tab 首页

```swift
struct MainTabView: View {
    @State private var selectedTab: HomeTab = .list
    
    enum HomeTab: String, CaseIterable {
        case list = "🎞️ 胶卷列表"
        case ring  = "◎ 年轮总览"
    }
    
    var body: some View {
        @Bindable var selection = $selectedTab
        
        TabView(selection: $selectedTab) {
            FilmRollListView()
                .tabItem {
                    Label("胶卷列表", systemImage: "film.stack")
                }
                .tag(HomeTab.list)
            
            RingOverviewView()
                .tabItem {
                    Label("年轮总览", systemImage: "circle.dotted")
                }
                .tag(HomeTab.ring)
        }
        .tint(.accentColor)
    }
}

// 注：iOS 18 TabView 默认使用系统 TabBar 样式
// 如需自定义 TabBar 外观，使用 .tabViewStyle(.sidebarAdaptable)
```

### 5.3 FilmRollListView — 胶卷列表

```swift
struct FilmRollListView: View {
    @Query(sort: \FilmRoll.year, order: .reverse) private var rolls: [FilmRoll]
    
    var body: some View {
        List(rolls) { roll in
            NavigationLink {
                ReelView(roll: roll)
            } label: {
                HStack {
                    // 微缩胶片指示器
                    MiniFilmStrip(filledCount: roll.filledCount)
                    
                    VStack(alignment: .leading) {
                        Text("\(roll.year)")
                            .font(.title2).bold()
                        Text("\(roll.filledCount)/\(roll.totalCount) 帧已填充")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 密度竖条
                    DensityBar(ratio: roll.fillRatio)
                }
            }
        }
        .listStyle(.plain)
    }
}
```

### 5.4 ReelView — 胶片卷轴

```swift
struct ReelView: View {
    let roll: FilmRoll
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(roll.frames.sorted(by: { $0.date < $1.date })) { frame in
                    FilmFrameCard(frame: frame)
                }
            }
            .padding()
        }
        .navigationTitle("\(roll.year) 年")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    RingView(year: roll.year)
                } label: {
                    Image(systemName: "circle.dotted")
                }
            }
        }
    }
}
```

### 5.5 FilmFrameCard — 单张胶片帧卡片

```swift
struct FilmFrameCard: View {
    let frame: FilmFrame
    @State private var showEditor = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧齿孔
            SprocketHoles()
            
            // 帧主体
            VStack(spacing: 0) {
                ZStack {
                    if frame.isFilled, let path = frame.photoPath {
                        // 加载本地图片
                        ImageLoader(path: path)
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        // 空白底片
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                    }
                    
                    // 胶片颗粒纹理
                    FilmGrainOverlay()
                }
                .clipped()
                
                // 底部信息
                HStack {
                    Text(frame.displayDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let note = frame.note {
                        Text(note)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            
            // 右侧齿孔
            SprocketHoles()
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { showEditor = true }
        .sheet(isPresented: $showEditor) {
            EditFrameSheet(frame: frame)
        }
    }
}
```

### 5.6 RingView — 年轮聚合

```swift
struct RingView: View {
    let year: Int
    @Query private var rolls: [FilmRoll]
    
    init(year: Int) {
        self.year = year
        let predicate = #Predicate<FilmRoll> { $0.year == year }
        _rolls = Query(filter: predicate)
    }
    
    var body: some View {
        VStack {
            if let roll = rolls.first {
                RingChart(frames: roll.frames)
                    .frame(width: 280, height: 280)
                
                Text("\(roll.filledCount)/\(roll.totalCount) 天已填充")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("\(year) 年轮")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("导出") { /* 导出年轮为图片 */ }
            }
        }
    }
}

struct RingChart: View {
    let frames: [FilmFrame]
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 20
            let total = frames.count
            let segmentAngle = 2 * .pi / Double(max(total, 1))
            
            ZStack {
                ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                    let startAngle = Angle(radians: Double(index) * segmentAngle - .pi / 2)
                    let endAngle = Angle(radians: Double(index + 1) * segmentAngle - .pi / 2)
                    
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                    }
                    .stroke(
                        frame.isFilled ? Color.accentColor : Color(.systemGray4),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                }
                
                VStack {
                    Text("\(year)").font(.title2).bold()
                    Text("\(frames.filter(\.isFilled).count) 帧回忆")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
```

---

## 6. 核心业务逻辑

### 6.1 RollGenerator — 胶卷初始化引擎（Swift 6 并发安全）

```swift
import SwiftData

/// 胶卷生成器：所有方法通过 @ModelActor 执行，不直接访问 ModelContext
enum RollGenerator {
    
    /// 从出生日期到当前日期初始化全部胶卷与帧
    /// 通过 ModelActor 在后台 actor 上执行，不阻塞主线程
    static func generateInitialRolls(
        from birthDate: Date,
        to endDate: Date,
        using actor: FilmRollActor
    ) async throws {
        try await actor.insertInitialRolls(from: birthDate, to: endDate)
    }
    
    /// 每日 App 启动时调用：检查今日帧是否已生成
    static func ensureTodayFrame(using actor: FilmRollActor) async throws {
        try await actor.ensureTodayFrame()
    }
}

// MARK: - ModelActor 实现（iOS 18 + Swift 6）
extension FilmRollActor {
    
    func insertInitialRolls(from birthDate: Date, to endDate: Date) throws {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: birthDate)
        let endYear = calendar.component(.year, from: endDate)
        
        for year in birthYear...endYear {
            let roll = FilmRoll(year: year)
            modelContext.insert(roll)
            
            let yearStart: Date
            let yearEnd: Date
            
            if year == birthYear {
                yearStart = birthDate
            } else {
                yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
            }
            
            if year == endYear {
                yearEnd = endDate
            } else {
                yearEnd = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
            }
            
            var currentDate = yearStart
            while currentDate <= yearEnd {
                let frame = FilmFrame(date: currentDate)
                frame.roll = roll
                modelContext.insert(frame)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            roll.isInitialized = true
        }
        
        try modelContext.save()
    }
    
    func ensureTodayFrame() throws {
        let today = Calendar.current.startOfDay(for: .now)
        let currentYear = Calendar.current.component(.year, from: today)
        
        // iOS 18: #Predicate 支持更复杂的查询
        let predicate = #Predicate<FilmFrame> { frame in
            frame.date >= today
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        guard try modelContext.fetch(descriptor).isEmpty else { return }
        
        // 查找或创建当前年份胶卷
        let yearPredicate = #Predicate<FilmRoll> { $0.year == currentYear }
        let yearDescriptor = FetchDescriptor(predicate: yearPredicate)
        let rolls = try modelContext.fetch(yearDescriptor)
        
        let roll: FilmRoll
        if let existingRoll = rolls.first {
            roll = existingRoll
        } else {
            roll = FilmRoll(year: currentYear)
            modelContext.insert(roll)
        }
        
        let frame = FilmFrame(date: today)
        frame.roll = roll
        modelContext.insert(frame)
        
        try modelContext.save()
    }
}
```

### 6.2 照片管理（Swift 6 + @MainActor）

```swift
import UIKit

/// 照片读写涉及 UIKit（UIImage），标记为 @MainActor
enum PhotoManager: Sendable {
    nonisolated static let documentsDir = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first!
        .appendingPathComponent("frames", isDirectory: true)
    
    /// 保存照片到本地，返回相对路径
    @MainActor
    static func savePhoto(_ image: UIImage, for date: Date) throws -> String {
        try FileManager.default.createDirectory(at: documentsDir,
            withIntermediateDirectories: true)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = formatter.string(from: date) + ".jpg"
        let fileURL = documentsDir.appendingPathComponent(filename)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.compressionFailed
        }
        try data.write(to: fileURL)
        return "frames/" + filename
    }
    
    /// 根据相对路径加载照片
    @MainActor
    static func loadPhoto(at path: String) -> UIImage? {
        let fileURL = documentsDir
            .deletingLastPathComponent()
            .appendingPathComponent(path)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// 删除照片文件
    static func deletePhoto(at path: String) {
        let fileURL = documentsDir
            .deletingLastPathComponent()
            .appendingPathComponent(path)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    enum PhotoError: Error {
        case compressionFailed
        case fileNotFound
    }
}
```

---

## 7. WidgetKit 小组件

### 7.1 TodayFrameWidget — 今日帧

```swift
import WidgetKit
import SwiftUI
import SwiftData

struct TodayFrameProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayFrameEntry {
        TodayFrameEntry(date: .now, isFilled: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodayFrameEntry) -> Void) {
        let entry = TodayFrameEntry(date: .now, isFilled: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayFrameEntry>) -> Void) {
        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // 通过 App Group 共享的 ModelContainer 读取今日帧
        let container = PersistenceController.shared.container
        let context = ModelContext(container)
        
        let predicate = #Predicate<FilmFrame> {
            $0.date >= today && $0.date < tomorrow
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        let frames = try? context.fetch(descriptor)
        let isFilled = frames?.first?.isFilled ?? false
        
        let entry = TodayFrameEntry(date: .now, isFilled: isFilled)
        // 每 15 分钟刷新一次
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct TodayFrameEntry: TimelineEntry {
    let date: Date
    let isFilled: Bool
}

struct TodayFrameWidgetEntryView: View {
    var entry: TodayFrameEntry
    
    var body: some View {
        VStack(spacing: 4) {
            if entry.isFilled {
                // 已填充状态
                Image(systemName: "photo.fill")
                    .font(.title)
                Text("今日已记录")
                    .font(.caption2)
            } else {
                // 空白状态
                FilmBorder()
                Text("Today's Frame")
                    .font(.caption2)
                Text("Add a photo")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .widgetURL(URL(string: "widget://open-today-frame"))
    }
}
```

### 7.2 Widget 配置（iOS 18）

```swift
import WidgetKit

/// iOS 18: WidgetBundle 支持 #Widgets 宏简化注册
#Widgets {
    TodayFrameWidget()
    RandomFrameWidget()
    YearRingWidget()
}

// 或传统写法：
struct FilmYearsWidgets: WidgetBundle {
    var body: some Widget {
        TodayFrameWidget()
        RandomFrameWidget()
        YearRingWidget()
    }
}
```

---

## 8. Navigation / Deep Link 路由（iOS 18）

```swift
import SwiftUI

/// iOS 18: 使用 @Entry 注册环境值替代自定义 EnvironmentKey
enum AppRoute: Hashable {
    case reel(year: Int)
    case frame(year: Int, date: Date)
    case ring(year: Int)
    case settings
}

// iOS 18 @Entry 语法：
extension EnvironmentValues {
    @Entry var navigationState = NavigationState()
}

@MainActor
@Observable
final class NavigationState {
    var path = NavigationPath()
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "open-today-frame":
            let currentYear = Calendar.current.component(.year, from: .now)
            path.append(AppRoute.reel(year: currentYear))
        case "open-frame":
            break
        default:
            break
        }
    }
}

/// 使用示例：
/// @Environment(\.navigationState) private var navState
/// navState.path.append(AppRoute.reel(year: 2026))

---

## 9. 设计组件库（Design System）

### 9.1 胶片齿孔 SprocketHoles

```swift
struct SprocketHoles: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<6) { i in
                Circle()
                    .fill(i == 1 || i == 4 ? Color.accentColor.opacity(0.6) : Color.accentColor.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 8)
        .frame(width: 12)
    }
}
```

### 9.2 胶片颗粒纹理 FilmGrainOverlay

```swift
struct FilmGrainOverlay: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.03))
            .overlay(
                Rectangle()
                    .fill(
                        ImageFilterNoise()
                            .opacity(0.06)
                    )
                    .blendMode(.overlay)
            )
            .allowsHitTesting(false)
    }
}

/// 使用 Core Image 的颗粒噪点
struct ImageFilterNoise: View {
    var body: some View {
        Color.clear
            .drawingGroup { context in
                // 通过 Metal/CoreImage 生成噪点纹理
            }
    }
}
```

### 9.3 密度条 DensityBar

```swift
struct DensityBar: View {
    let ratio: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(.systemGray4))
            .frame(width: 4, height: 32)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(height: 32 * ratio)
            }
    }
}
```

---

## 10. 关键配置项

### Info.plist / Entitlements

```xml
<!-- iCloud 容器 -->
com.apple.developer.icloud-container-identifiers:
  - iCloud.com.yourcompany.filmyears

<!-- CloudKit 服务 -->
com.apple.developer.icloud-services:
  - CloudKit

<!-- App Groups（Widget 共享数据） -->
com.apple.security.application-groups:
  - group.com.yourcompany.filmyears
```

### SwiftData + WidgetKit 共享容器

```swift
// 在 Widget Target 中使用相同的 ModelContainer 配置
// 通过 App Group 共享目录确保 Widget 和主 App 访问同一数据

let config = ModelConfiguration(
    schema: schema,
    url: FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourcompany.filmyears")!
        .appendingPathComponent("FilmYears.data")
)
```

---

## 11. IAP 买断逻辑（StoreKit 2 + Swift 6）

```swift
import StoreKit

/// Swift 6: 使用 Actor 隔离确保线程安全
@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()
    
    private(set) var isUnlocked: Bool = false
    private var updates: Task<Void, Never>?
    
    private let productID = "com.yourcompany.filmyears.unlock"
    
    init() {
        updates = observeTransactionUpdates()
    }
    
    deinit {
        updates?.cancel()
    }
    
    /// 购买解锁 — Swift 6 下 async throws 自动处理 actor 跳转
    func purchase() async throws {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            isUnlocked = transaction.productID == productID
            await transaction.finish()
        case .pending:
            break
        case .userCancelled:
            break
        @unknown default:
            break
        }
    }
    
    /// 恢复购买
    func restore() async throws {
        try await AppStore.sync()
    }
    
    /// 验证当前解锁状态
    func checkEntitlement() async {
        // iOS 18: Transaction.currentEntitlement 提供最新状态
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID {
                isUnlocked = true
                return
            }
        }
        isUnlocked = false
    }
    
    private nonisolated func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await verification in Transaction.updates {
                guard let transaction = try? verification.payloadValue else { continue }
                await transaction.finish()
                await MainActor.run {
                    self?.isUnlocked = transaction.productID == self?.productID
                }
            }
        }
    }
}
```

---

## 12. 工程结构建议

```
FilmYears/
├── App/
│   ├── FilmYearsApp.swift
│   ├── ContentView.swift
│   └── PersistenceController.swift
├── Models/
│   ├── FilmRoll.swift
│   ├── FilmFrame.swift
│   └── AppSettings.swift
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   ├── Home/
│   │   ├── MainTabView.swift
│   │   ├── FilmRollListView.swift
│   │   └── RingOverviewList.swift
│   ├── Reel/
│   │   ├── ReelView.swift
│   │   ├── FilmFrameCard.swift
│   │   └── EditFrameSheet.swift
│   ├── Ring/
│   │   ├── RingView.swift
│   │   └── RingChart.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       ├── SprocketHoles.swift
│       ├── FilmGrainOverlay.swift
│       ├── DensityBar.swift
│       ├── MiniFilmStrip.swift
│       └── RingSegment.swift
├── ViewModels/
│   ├── NavigationState.swift
│   └── AppViewModel.swift
├── Services/
│   ├── RollGenerator.swift
│   ├── PhotoManager.swift
│   ├── PurchaseManager.swift
│   └── CloudKitSyncService.swift
├── Widgets/
│   ├── TodayFrameWidget.swift
│   ├── RandomFrameWidget.swift
│   └── YearRingWidget.swift
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

---

## 13. 性能注意事项

1. **LazyVStack**：胶片卷轴使用 `LazyVStack` 替代 `VStack`，确保只渲染可见帧
2. **照片缩略图**：帧列表仅加载缩略图（`ImageRenderer`），全尺寸图仅在编辑时加载
3. **年轮渲染**：`RingChart` 使用 `Canvas` 或 `Shape` 直接绘制，不创建大量 `View` 节点
4. **SwiftData 查询**：`@Query` 配合 `#Predicate` 确保高效增量更新
5. **Swift 6 严格并发**：`View` 默认 `@MainActor`，后台数据操作使用 `@ModelActor` 隔离，避免数据竞争
6. **Widget 刷新**：设置 15 分钟最小刷新间隔，避免过度唤醒
7. **CloudKit 冲突**：使用 `photoModifiedAt` 时间戳 + SwiftData 默认 last-write-wins 策略
