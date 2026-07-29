import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var birthDate: Date = {
        let cal = Calendar.current
        let comps = DateComponents(year: 1995, month: 6, day: 15)
        return cal.date(from: comps) ?? .now
    }()
    @State private var isInitializing = false
    @State private var showError = false
    @State private var errorMessage = ""
    let completion: () -> Void

    private var isFutureDate: Bool {
        Calendar.current.startOfDay(for: birthDate) > Calendar.current.startOfDay(for: .now)
    }

    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    // Logo area
                    VStack(spacing: 12) {
                        Text("🎞️")
                            .font(.system(size: 72))

                        Text("FilmYears")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(.accentColor)

                        Text("每一年是一卷胶卷，每一天是一张胶片帧")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text("Each year is a roll of film, every day one frame.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                    .padding(.bottom, 48)

                    // Date picker section
                    VStack(spacing: 16) {
                        Text("你的出生日期是？")
                            .font(.headline)
                            .foregroundColor(.primary)

                        DatePicker(
                            "出生日期",
                            selection: $birthDate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .disabled(isInitializing)

                        if isFutureDate {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text("出生日期不能是未来日期")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 40)

                    // Start button
                    VStack(spacing: 12) {
                        Button(action: initializeApp) {
                            HStack(spacing: 8) {
                                if isInitializing {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                }
                                Text(isInitializing ? "正在生成你的胶卷..." : "开始我的胶片年轮")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .controlSize(.large)
                        .disabled(isInitializing || isFutureDate)

                        Text("只回望你已经活过的时光 · 不渲染未来")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .alert("初始化失败", isPresented: $showError) {
            Button("重试") { initializeApp() }
            Button("取消", role: .cancel) {
                isInitializing = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func initializeApp() {
        guard !isFutureDate else { return }
        isInitializing = true
        errorMessage = ""
        showError = false

        let settings = AppSettings(birthDate: birthDate)
        context.insert(settings)

        let actor = PersistenceController.shared.makeBackgroundActor()
        Task {
            do {
                try await actor.insertInitialRolls(from: birthDate, to: .now)
                settings.onboardingCompleted = true
                try context.save()
                await MainActor.run { completion() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isInitializing = false
                }
            }
        }
    }
}
