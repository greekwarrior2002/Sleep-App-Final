import SwiftUI

extension Font {
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 40, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 34, weight: .bold, design: .default)
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let titleMedium = Font.system(size: 17, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 15, weight: .semibold, design: .default)
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    static let caption = Font.system(size: 11, weight: .regular, design: .default)
}

extension View {
    func monoDigits() -> some View {
        self.monospacedDigit()
    }
}
