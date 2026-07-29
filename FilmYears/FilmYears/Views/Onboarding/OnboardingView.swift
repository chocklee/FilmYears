import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedYear = 1995
    @State private var selectedMonth = 6
    @State private var selectedDay = 15
    @State private var isInitializing = false
    @State private var showError = false
    @State private var errorMessage = ""
    let completion: () -> Void

    private let years = Array(1920...2026)
    private let months = Array(1...12)
    private let days = Array(1...31)

    private var birthDate: Date {
        Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? .now
    }

    var body: some View {
        ZStack {
            // Background — solid dark
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo area
                VStack(spacing: 12) {
                    Text("🎞️")
                        .font(.system(size: 72))

                    Text("FilmYears")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(Color(red: 0.78, green: 0.59, blue: 0.24))

                    Text("每一年是一卷胶卷，每一天是一张胶片帧")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    Text("Each year is a roll of film, every day one frame.")
                        .font(.system(size: 12).italic())
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .padding(.bottom, 48)

                // Date picker section
                VStack(spacing: 16) {
                    Text("你的出生日期是？")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        PickerField(label: "年", value: $selectedYear, range: years, width: 100)
                        PickerField(label: "月", value: $selectedMonth, range: months, width: 80)
                        PickerField(label: "日", value: $selectedDay, range: days, width: 80)
                    }
                }
                .padding(.bottom, 48)

                // Start button
                VStack(spacing: 12) {
                    Button(action: initializeApp) {
                        HStack(spacing: 8) {
                            if isInitializing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.black)
                            }
                            Text(isInitializing ? "正在生成你的胶卷..." : "开始我的胶片年轮")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.78, green: 0.59, blue: 0.24))
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isInitializing)

                    Text("只回望你已经活过的时光 · 不渲染未来")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
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
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.78, green: 0.59, blue: 0.24).opacity(0.3), lineWidth: 1)
                    )

                Picker("", selection: $value) {
                    ForEach(range, id: \.self) { num in
                        Text("\(num)")
                            .tag(num)
                            .foregroundColor(.white)
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
