import SwiftUI

// MARK: - FilmYears Design System
// 基于 Figma 设计稿与产品文档定义的设计 Token
// 所有 UI 组件应引用此文件中的常量，避免使用硬编码值

// MARK: - Colors
extension Color {
    // MARK: Background
    static let bgPrimary = Color(hex: "#0d0d0d")       // 页面背景
    static let bgCard = Color(hex: "#171717")           // 卡片表面
    static let bgCardElevated = Color(hex: "#1f1f1f")   // 卡片表面(二级)
    static let bgCardStrong = Color(hex: "#2a2a2a")     // 卡片表面(三级)

    // MARK: Accent
    static let accentGold = Color(hex: "#c8963e")       // 强调色(琥珀金)
    static let accentGoldSoft = Color(hex: "#c8963e22") // 强调色(半透明)
    static let accentGoldGlow = Color(hex: "#c8963e55") // 强调色(辉光)

    // MARK: Text
    static let textPrimary = Color(hex: "#f0ece4")      // 主文字(暖白)
    static let textSecondary = Color(hex: "#a09a92")    // 次要文字
    static let textTertiary = Color(hex: "#6b6660")     // 辅助文字

    // MARK: Border
    static let borderStandard = Color(hex: "#2a2a2a")   // 标准边框

    // MARK: Semantic
    static let dangerRed = Color(hex: "#e74c3c")        // 危险/删除
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
enum AppFont {
    /// Display: 36px Heavy — 用于 App 标题
    static let display = Font.system(size: 36, weight: .heavy)

    /// Heading 1: 22px Bold — 用于年份数字
    static let h1 = Font.system(size: 22, weight: .bold)

    /// Heading 2: 18px Semibold — 用于导航标题
    static let h2 = Font.system(size: 18, weight: .semibold)

    /// Body: 15px Regular — 用于正文
    static let body = Font.system(size: 15)

    /// Caption: 13px Regular — 用于辅助信息
    static let caption = Font.system(size: 13)

    /// Small: 11px Regular — 用于极小文字
    static let small = Font.system(size: 11)

    /// Tiny: 10px Monospaced — 用于胶片边缘标记
    static let filmMark = Font.system(size: 10, design: .monospaced)
}

// MARK: - Spacing (4px baseline grid)
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}

// MARK: - Border Radius
enum Radius {
    static let sm: CGFloat = 6      // 帧卡片
    static let md: CGFloat = 10     // 输入框
    static let lg: CGFloat = 14     // 列表卡片 / 主按钮
    static let xl: CGFloat = 20     // Modal Sheet
}

// MARK: - Layout Constants
enum Layout {
    /// iPhone 安全区
    static let safeTop: CGFloat = 54
    static let safeBottom: CGFloat = 34

    /// 内容左右边距
    static let contentPadding: CGFloat = 20

    /// 手机画布尺寸（iPhone 14 Pro）
    static let canvasWidth: CGFloat = 390
    static let canvasHeight: CGFloat = 844
}

// MARK: - Shadow
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - Accent Color (Asset Catalog 回退)
extension Color {
    /// 从 Asset Catalog 读取 AccentColor，兜底使用 #c8963e
    static let appAccent = Color("AccentColor", bundle: .main)
}
