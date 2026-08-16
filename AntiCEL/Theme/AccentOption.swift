import SwiftUI

enum AccentOption: String, CaseIterable, Identifiable, Codable {
    case amber
    case amberRed
    case iceWhite
    case verdant
    case turquoise
    case guardsRed
    case cobalt
    case racingYellow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .amber: return "Amber"
        case .amberRed: return "Amber Red"
        case .iceWhite: return "Ice White"
        case .verdant: return "Green"
        case .turquoise: return "Turquoise"
        case .guardsRed: return "Guards Red"
        case .cobalt: return "Cobalt"
        case .racingYellow: return "Racing Yellow"
        }
    }

    func color(for scheme: ColorScheme) -> Color {
        let rgb = scheme == .dark ? darkRGB : lightRGB
        return Color(red: rgb.0, green: rgb.1, blue: rgb.2)
    }

    func selectedKeyFace(for scheme: ColorScheme) -> Color {
        let accent = scheme == .dark ? darkRGB : lightRGB
        if scheme == .dark {
            return Color(
                red: accent.0 * 0.32 + 0.13,
                green: accent.1 * 0.32 + 0.10,
                blue: accent.2 * 0.32 + 0.09
            )
        }

        return Color(
            red: min(1, accent.0 * 0.22 + 0.90),
            green: min(1, accent.1 * 0.22 + 0.88),
            blue: min(1, accent.2 * 0.22 + 0.82)
        )
    }

    /// Light-mode swatch: deep enough to read on concrete.
    private var lightRGB: (Double, Double, Double) {
        switch self {
        case .amber: return (0.780, 0.480, 0.050)
        case .amberRed: return (0.82, 0.28, 0.12)
        case .iceWhite: return (0.42, 0.46, 0.50)
        case .verdant: return (0.12, 0.55, 0.38)
        case .turquoise: return (0.08, 0.58, 0.56)
        case .guardsRed: return (0.72, 0.12, 0.16)
        case .cobalt: return (0.12, 0.34, 0.78)
        case .racingYellow: return (0.78, 0.58, 0.04)
        }
    }

    /// Dark-mode swatch: brighter cluster-style glow.
    private var darkRGB: (Double, Double, Double) {
        switch self {
        case .amber: return (1.00, 0.72, 0.18)
        case .amberRed: return (1.00, 0.310, 0.145)
        case .iceWhite: return (0.92, 0.94, 0.96)
        case .verdant: return (0.28, 0.92, 0.52)
        case .turquoise: return (0.32, 0.90, 0.86)
        case .guardsRed: return (1.00, 0.32, 0.30)
        case .cobalt: return (0.40, 0.68, 1.00)
        case .racingYellow: return (1.00, 0.84, 0.18)
        }
    }
}
