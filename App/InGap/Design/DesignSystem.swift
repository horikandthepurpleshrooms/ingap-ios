import SwiftUI

struct DesignSystem {
    // MARK: - Layout
    static let cornerRadius: CGFloat = 12.0
    static let padding: CGFloat = 16.0
    static let smallPadding: CGFloat = 8.0
    static let strokeWidth: CGFloat = 1.0
    
    // MARK: - Colors
    struct Colors {
        static let primaryText = Color("PrimaryText") // Define in Assets or use adaptive
        static let secondaryText = Color.secondary
        static let background = Color("AppBackground") // Define in Assets
        static let surface = Color("Surface") // Define in Assets
        static let border = Color.gray.opacity(0.2)
        static let accent = Color("AccentColor")
    }
    
    // MARK: - Typography
    // Using system fonts for now, can be swapped for custom fonts later
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let caption = Font.system(size: 13, weight: .regular, design: .default)
        static let button = Font.system(size: 17, weight: .semibold, design: .default)
    }
}

// MARK: - View Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? DesignSystem.Colors.accent : Color.gray.opacity(0.3))
            .cornerRadius(DesignSystem.cornerRadius)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .stroke(DesignSystem.Colors.border, lineWidth: DesignSystem.strokeWidth)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

struct MinimalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(DesignSystem.Typography.body)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .stroke(DesignSystem.Colors.border, lineWidth: DesignSystem.strokeWidth)
            )
    }
}
