import SwiftUI

/// Floating bottom switcher for vehicle detail sections.
struct VehicleSectionTabBar: View {

    @Binding var selection: VehicleDetailSection

    var body: some View {

        HStack(spacing: 4) {

            ForEach(VehicleDetailSection.allCases) { section in

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = section
                    }
                } label: {

                    VStack(spacing: 4) {

                        Image(systemName: section.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .symbolEffect(.bounce, value: selection == section)

                        Text(section.rawValue)
                            .font(.caption2.weight(.semibold))

                    }
                    .foregroundStyle(selection == section ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selection == section {
                            Capsule()
                                .fill(Color.accentColor.opacity(0.14))
                                .matchedGeometryEffect(id: "sectionTab", in: tabNamespace)
                        }
                    }
                    .contentShape(Rectangle())

                }
                .buttonStyle(.plain)

            }

        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .padding(.top, 4)

    }

    @Namespace private var tabNamespace

}
