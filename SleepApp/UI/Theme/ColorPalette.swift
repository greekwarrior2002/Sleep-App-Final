import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let sleepBackground = Color(hex: "0A0E1A")
    static let sleepSurface = Color(hex: "111827")
    static let sleepElevated = Color(hex: "1C2333")
    static let sleepBorder = Color(hex: "2D3748").opacity(0.6)

    // MARK: - Accents
    static let sleepPurple = Color(hex: "7C3AED")
    static let sleepPurpleLight = Color(hex: "A78BFA")
    static let sleepPurpleDim = Color(hex: "4C1D95").opacity(0.4)
    static let sleepTeal = Color(hex: "0D9488")
    static let sleepTealLight = Color(hex: "5EEAD4")

    // MARK: - Score tiers
    static let scoreExcellent = Color(hex: "8B5CF6")
    static let scoreGood = Color(hex: "0D9488")
    static let scoreFair = Color(hex: "D97706")
    static let scorePoor = Color(hex: "DC2626")

    // MARK: - Sleep stages
    static let stageDeep = Color(hex: "4F46E5")
    static let stageREM = Color(hex: "7C3AED")
    static let stageLight = Color(hex: "0891B2")
    static let stageAwake = Color(hex: "D97706")

    // MARK: - Text
    static let textPrimary = Color(hex: "F8FAFC")
    static let textSecondary = Color(hex: "94A3B8")
    static let textTertiary = Color(hex: "475569")

    // MARK: - Semantic
    static let positive = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let destructive = Color(hex: "EF4444")
}

extension ShapeStyle where Self == Color {
    static var sleepBackground: Color { .sleepBackground }
    static var sleepSurface: Color { .sleepSurface }
    static var sleepElevated: Color { .sleepElevated }
    static var sleepBorder: Color { .sleepBorder }
    static var sleepPurple: Color { .sleepPurple }
    static var sleepPurpleLight: Color { .sleepPurpleLight }
    static var sleepPurpleDim: Color { .sleepPurpleDim }
    static var sleepTeal: Color { .sleepTeal }
    static var sleepTealLight: Color { .sleepTealLight }
    static var scoreExcellent: Color { .scoreExcellent }
    static var scoreGood: Color { .scoreGood }
    static var scoreFair: Color { .scoreFair }
    static var scorePoor: Color { .scorePoor }
    static var stageDeep: Color { .stageDeep }
    static var stageREM: Color { .stageREM }
    static var stageLight: Color { .stageLight }
    static var stageAwake: Color { .stageAwake }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
    static var positive: Color { .positive }
    static var warning: Color { .warning }
    static var destructive: Color { .destructive }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

extension Color {
    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 85...: return .scoreExcellent
        case 70..<85: return .scoreGood
        case 50..<70: return .scoreFair
        default: return .scorePoor
        }
    }

    static func stageColor(for stage: SleepStage) -> Color {
        switch stage {
        case .deepSleep: return .stageDeep
        case .remSleep: return .stageREM
        case .lightSleep: return .stageLight
        case .awake: return .stageAwake
        case .inBed: return .textTertiary
        }
    }
}
