import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedYear = Calendar.current.component(.year, from: .now) - 29
    @State private var selectedMonth = 6
    @State private var selectedDay = 15
    @State private var isInitializing = false
    @State private var showError = false
    @State private var errorMessage = ""
    let completion: () -> Void

    private let currentYear = Calendar.current.component(.year, from: .now)
    private let currentMonth = Calendar.current.component(.month, from: .now)
    private let currentDay = Calendar.current.component(.day, from: .now)

    private var years: [Int] { Array(1900...currentYear) }

    private var months: [Int] {
        selectedYear >= currentYear ? Array(1...currentMonth) : Array(1...12)
    }

    private var days: [Int] {
        if selectedYear > currentYear { return [] }
        if selectedYear == currentYear && selectedMonth > currentMonth { return [] }
        if selectedYear == currentYear && selectedMonth == currentMonth {
            return Array(1...currentDay)
        }
        let maxDay = Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(
            from: DateComponents(year: selectedYear, month: selectedMonth)
        ) ?? .now)?.count ?? 30
        return Array(1...maxDay)
    }

    private var birthDate: Date {
        Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? .now
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo area
                VStack(spacing: Spacing.md) {
                    Text("🎞️")
                        .font(.system(size: 72))

                    Text("FilmYears")
                        .font(AppFont.display)
                        .foregroundColor(.accentGold)

                    Text("每一年是一卷胶卷，每一天是一张胶片帧")
                        .font(AppFont.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Each year is a roll of film, every day one frame.")
                        .font(.system(size: 12).italic())
                        .foregroundColor(.textTertiary)
                }
                .padding(.bottom, Spacing.huge)

                // Date picker section
                VStack(spacing: Spacing.lg) {
                    Text("你的出生日期是？")
                        .font(AppFont.body.weight(.medium))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: Spacing.md) {
                        PickerField(label: "年", value: $selectedYear, range: years, width: 100)
                        PickerField(label: "月", value: $selectedMonth, range: months, width: 80)
                        PickerField(label: "日", value: $selectedDay, range: days, width: 80)
                    }
                    .onChange(of: selectedYear) { _, _ in
                        if !months.contains(selectedMonth) {
                            selectedMonth = months.last ?? 1
                        }
                        if !days.contains(selectedDay) {
                            selectedDay = days.last ?? 1
                        }
                    }
                    .onChange(of: selectedMonth) { _, _ in
                        if !days.contains(selectedDay) {
                            selectedDay = days.last ?? 1
                        }
                    }
                }
                .padding(.bottom, Spacing.huge)

                // Start button
                VStack(spacing: Spacing.md) {
                    Button(action: initializeApp) {
                        HStack(spacing: Spacing.sm) {
                            if isInitializing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.black)
                            }
                            Text(isInitializing ? "正在生成你的胶卷..." : "开始我的胶片年轮")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            isInitializing
                                ? Color.white.opacity(0.15)
                                : Color.accentGold
                        )
                        .foregroundColor(
                            isInitializing ? .textSecondary : .black
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    }
                    .disabled(isInitializing)

                    Text("只回望你已经活过的时光 · 不渲染未来")
                        .font(AppFont.small)
                        .foregroundColor(.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.xxl)
        }
        .alert("初始化失败", isPresented: $showError) {
            Button("重试") { initializeApp() }
            Button("取消", role: .cancel) { isInitializing = false }
        } message: {
            Text(errorMessage)
        }
    }

    private func initializeApp() {
        isInitializing = true
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

// MARK: - Custom picker wheel
private struct PickerField: View {
    let label: String
    @Binding var value: Int
    let range: [Int]
    let width: CGFloat

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(label)
                .font(AppFont.small.weight(.medium))
                .foregroundColor(.textTertiary)

            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.accentGold.opacity(0.3), lineWidth: 1)
                    )

                Picker("", selection: $value) {
                    ForEach(range, id: \.self) { num in
                        Text("\(num)")
                            .tag(num)
                            .foregroundColor(.textPrimary)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipped()
            }
            .frame(width: width, height: 120)
        }
    }
}
