import SwiftUI

struct ScannedFaultVerificationBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
            Text("Auto-added from vehicle scan")
        }
        .font(.appBadge)
        .foregroundStyle(Color.accentColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Automatically created from a fault scanned by the car")
    }
}
