import SwiftUI

enum AppTheme {
    static let background = Color(red: 5/255, green: 8/255, blue: 20/255)
    static let card = Color(red: 17/255, green: 17/255, blue: 17/255)
    static let border = Color(red: 39/255, green: 39/255, blue: 42/255)
    static let cyan = Color(red: 0, green: 212/255, blue: 1)
    static let green = Color(red: 0, green: 1, blue: 135/255)
    static let secondary = Color(red: 154/255, green: 162/255, blue: 176/255)
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16).background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border))
    }
}

extension View {
    func appCard() -> some View { modifier(CardModifier()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.black).frame(maxWidth: .infinity)
            .padding(.vertical, 14).background(AppTheme.cyan.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

