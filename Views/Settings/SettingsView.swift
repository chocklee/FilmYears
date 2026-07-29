import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]

    var body: some View {
        List {
            if let setting = settings.first {
                Section("数据") {
                    LabeledContent("出生日期") {
                        Text(setting.birthDate.formatted(date: .numeric, time: .omitted))
                    }
                }

                Section("同步") {
                    Toggle("iCloud 同步", isOn: Binding(
                        get: { setting.isCloudSyncEnabled },
                        set: { setting.isCloudSyncEnabled = $0 }
                    ))
                }

                Section("外观") {
                    Toggle("深色模式", isOn: .constant(true))
                }

                Section("购买") {
                    Button("解锁全部功能 — $8.99") { }
                    Button("恢复购买") { }
                }

                Section("数据管理") {
                    Button("清除所有数据", role: .destructive) { }
                }

                Section("其他") {
                    Link("隐私政策", destination: URL(string: "https://example.com/privacy")!)
                    Text("版本 MVP 1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
    }
}
