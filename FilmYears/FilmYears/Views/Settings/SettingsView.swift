import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showClearConfirm = false
    @State private var showClearSuccess = false

    var body: some View {
        List {
            if let setting = settings.first {
                // MARK: Data
                Section("数据") {
                    LabeledContent("出生日期") {
                        Text(setting.birthDate.formatted(date: .numeric, time: .omitted))
                    }
                }

                // MARK: Sync
                Section("同步") {
                    Toggle("iCloud 同步", isOn: Binding(
                        get: { setting.isCloudSyncEnabled },
                        set: { setting.isCloudSyncEnabled = $0 }
                    ))
                }

                // MARK: Appearance
                Section("外观") {
                    Toggle("深色模式", isOn: $isDarkMode)
                }

                // MARK: Purchase
                Section("购买") {
                    Button {
                        // Phase 8: implement IAP
                    } label: {
                        HStack {
                            Text("解锁全部功能")
                            Spacer()
                            Text("$8.99")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("恢复购买") {
                        // Phase 8: implement restore
                    }
                }

                // MARK: Data Management
                Section("数据管理") {
                    Button("清除所有数据", role: .destructive) {
                        showClearConfirm = true
                    }
                }

                // MARK: Other
                Section("其他") {
                    if let url = URL(string: "https://example.com/privacy") {
                        Link("隐私政策", destination: url)
                    }
                    Text("版本 MVP 1.0")
                        .foregroundColor(.secondary)
                }
            } else {
                ContentUnavailableView("加载中", systemImage: "gearshape")
            }
        }
        .navigationTitle("设置")
        .alert("清除所有数据", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认清除", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("这将删除你的出生日期、全部胶卷、所有照片和数据。此操作不可撤销。")
        }
        .alert("已清除", isPresented: $showClearSuccess) {
            Button("好的", role: .cancel) { }
        } message: {
            Text("所有数据已清除，回到首次启动引导页。")
        }
    }

    private func clearAllData() {
        Task {
            // Delete all photo files
            let fileManager = FileManager.default
            let documentsDir = PhotoManager.documentsDir
            if fileManager.fileExists(atPath: documentsDir.path) {
                try? fileManager.removeItem(at: documentsDir)
            }

            // Delete all SwiftData objects
            let frameFetch = FetchDescriptor<FilmFrame>()
            if let frames = try? context.fetch(frameFetch) {
                for f in frames { context.delete(f) }
            }
            let rollFetch = FetchDescriptor<FilmRoll>()
            if let rolls = try? context.fetch(rollFetch) {
                for r in rolls { context.delete(r) }
            }
            for s in settings {
                context.delete(s)
            }
            try? context.save()

            await MainActor.run {
                showClearSuccess = true
            }
        }
    }
}
