import SwiftUI

struct AppTheme {
    let scheme: ColorScheme
    var accent: AccentOption

    var isDark: Bool { scheme == .dark }

    var canvas: Color {
        isDark
            ? Color(red: 0.055, green: 0.055, blue: 0.06)
            : Color(red: 0.84, green: 0.82, blue: 0.78)
    }

    var canvasTop: Color {
        isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.11)
            : Color(red: 0.90, green: 0.88, blue: 0.84)
    }

    var infotainment: Color {
        isDark
            ? Color(red: 0.04, green: 0.04, blue: 0.045)
            : Color(red: 0.88, green: 0.86, blue: 0.82)
    }

    var panel: Color {
        isDark
            ? Color(red: 0.13, green: 0.13, blue: 0.145)
            : Color(red: 0.96, green: 0.95, blue: 0.92)
    }

    var housing: Color {
        isDark
            ? Color(red: 0.09, green: 0.09, blue: 0.10)
            : Color(red: 0.72, green: 0.70, blue: 0.66)
    }

    var keyFace: Color {
        isDark
            ? Color(red: 0.18, green: 0.18, blue: 0.195)
            : Color(red: 0.93, green: 0.92, blue: 0.89)
    }

    var keyFaceSelected: Color {
        accent.selectedKeyFace(for: scheme)
    }

    var accentColor: Color {
        accent.color(for: scheme)
    }

    var highlight: Color {
        isDark
            ? Color.white.opacity(0.16)
            : Color.white.opacity(0.70)
    }

    var edge: Color {
        isDark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.10)
    }

    var stallPaint: Color {
        isDark
            ? Color(white: 0.38)
            : Color.white.opacity(0.72)
    }

    var bayGlow: Color {
        isDark
            ? Color(red: 0.90, green: 0.94, blue: 1.0)
            : Color(red: 1.0, green: 0.98, blue: 0.92)
    }

    var doorMetalTop: Color {
        isDark
            ? Color(red: 0.28, green: 0.28, blue: 0.30)
            : Color(red: 0.62, green: 0.62, blue: 0.64)
    }

    var doorMetalBottom: Color {
        isDark
            ? Color(red: 0.12, green: 0.12, blue: 0.13)
            : Color(red: 0.42, green: 0.42, blue: 0.44)
    }

    var shadow: Color {
        Color.black.opacity(isDark ? 0.55 : 0.14)
    }

    var wordmark: Color {
        isDark ? Color.white.opacity(0.92) : Color.black.opacity(0.78)
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme(scheme: .dark, accent: .amberRed)
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

struct AppThemeInjector: ViewModifier {
    func body(content: Content) -> some View {
        AppThemeApplying(content: content)
    }
}

private struct AppThemeApplying<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable private var settings = AppSettings.shared
    var content: Content

    var body: some View {
        let option = settings.accentOption(for: colorScheme)
        content
            .environment(settings)
            .environment(\.appTheme, AppTheme(scheme: colorScheme, accent: option))
            .tint(option.color(for: colorScheme))
    }
}

extension View {
    func appTheme() -> some View {
        modifier(AppThemeInjector())
    }

    func appCanvas() -> some View {
        modifier(AppCanvasModifier())
    }
}

private struct AppCanvasModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(
                    colors: [theme.canvasTop, theme.canvas],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
    }
}

extension Font {
    static var appWordmark: Font {
        .system(size: 26, weight: .semibold, design: .default).width(.condensed)
    }

    static var appBadge: Font {
        .system(size: 11, weight: .semibold, design: .default)
    }

    static var appOdometer: Font {
        .system(.title3, design: .monospaced).weight(.medium)
    }
}
