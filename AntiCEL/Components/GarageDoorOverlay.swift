import SwiftUI

struct GarageDoorOverlay: View {

    @Environment(\.appTheme) private var theme

    var isOpen: Bool
    private let panelCount = 8

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height + 8

            VStack(spacing: 0) {
                ForEach(0..<panelCount, id: \.self) { index in
                    doorPanel(index: index)
                        .frame(height: height / CGFloat(panelCount))
                }
            }
            .overlay(alignment: .bottom) {
                handle
                    .padding(.bottom, 28)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 4)
                    .blur(radius: 5)
                    .opacity(isOpen ? 0.15 : 0.85)
                    .offset(y: 2)
            }
            .offset(y: isOpen ? -(height + 24) : 0)
        }
        .ignoresSafeArea()
        .allowsHitTesting(!isOpen)
    }

    private func doorPanel(index: Int) -> some View {
        let lift = Double(index) * 0.012

        return ZStack {
            LinearGradient(
                colors: [
                    theme.doorMetalTop.opacity(1 - lift),
                    theme.doorMetalBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.14))
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .fill(Color.black.opacity(0.38))
                    .frame(height: 2)
            }

            HStack {
                rivet
                Spacer()
                rivet
            }
            .padding(.horizontal, 22)
        }
    }

    private var rivet: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.45),
                        Color.black.opacity(0.35)
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 5
                )
            )
            .frame(width: 7, height: 7)
    }

    private var handle: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.28),
                        Color.black.opacity(0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 86, height: 10)
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
    }
}
