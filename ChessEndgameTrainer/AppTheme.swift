import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.035, green: 0.047, blue: 0.075)
    static let elevatedBackground = Color(red: 0.075, green: 0.090, blue: 0.125)
    static let card = Color.white.opacity(0.07)
    static let cardBorder = Color.white.opacity(0.10)
    static let primaryText = Color(red: 0.94, green: 0.95, blue: 0.98)
    static let secondaryText = Color(red: 0.66, green: 0.69, blue: 0.76)
    static let accent = Color(red: 0.46, green: 0.86, blue: 0.67)
    static let accentDark = Color(red: 0.19, green: 0.54, blue: 0.39)
    static let warning = Color(red: 0.96, green: 0.65, blue: 0.32)
    static let gold = Color(red: 0.91, green: 0.73, blue: 0.38)
    static let error = Color(red: 0.96, green: 0.38, blue: 0.42)
    static let lightSquare = Color(red: 0.67, green: 0.72, blue: 0.68)
    static let darkSquare = Color(red: 0.25, green: 0.40, blue: 0.34)
    static let smallRadius: CGFloat = 16
    static let cardRadius: CGFloat = 20
    static let largeRadius: CGFloat = 26

    static let backgroundGradient = LinearGradient(
        colors: [background, Color(red: 0.055, green: 0.075, blue: 0.11)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            }
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(red: 0.025, green: 0.08, blue: 0.055))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppTheme.accent, Color(red: 0.34, green: 0.73, blue: 0.56)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: AppTheme.accent.opacity(0.18), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
