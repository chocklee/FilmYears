import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var birthDate = Calendar.current.date(
        from: DateComponents(year: 1995, month: 6, day: 15)
    ) ?? .now
    let completion: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎞️")
                .font(.system(size: 64))
                .padding(.bottom, 8)

            Text("FilmYears")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.accentColor)

            Text("每一年是一卷胶卷，每一天是一张胶片帧")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                Text("你的出生日期是？")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DatePicker(
                    "出生日期",
                    selection: $birthDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
            }

            Spacer()

            Button("开始我的胶片年轮") {
                initializeApp()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .controlSize(.large)

            Text("只回望你已经活过的时光 · 不渲染未来")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
        }
        .padding()
    }

    private func initializeApp() {
        let settings = AppSettings(birthDate: birthDate)
        context.insert(settings)

        let actor = PersistenceController.shared.makeBackgroundActor()
        Task {
            try? await actor.insertInitialRolls(
                from: birthDate,
                to: .now
            )
            settings.onboardingCompleted = true
            try? context.save()
            await MainActor.run {
                completion()
            }
        }
    }
}
