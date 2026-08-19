import AppIntents
import SwiftUI
import UIKit
import WidgetKit

struct MileageWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: AntiCELWidgetKind.mileage,
            intent: MileageWidgetConfiguration.self,
            provider: MileageTimelineProvider()
        ) { entry in
            MileageWidgetView(entry: entry)
                .appTheme()
        }
        .configurationDisplayName("Odometer")
        .description("Check a vehicle’s mileage. Tap to type a new reading, or use the dash keys to add distance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct MileageEntry: TimelineEntry {
    let date: Date
    let snapshot: MileageSnapshot?
    var photo: UIImage? = nil
}

struct MileageTimelineProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> MileageEntry {
        MileageEntry(
            date: Date(),
            snapshot: MileageSnapshot(
                vehicleID: UUID(),
                name: "Daily Driver",
                mileage: 79500
            )
        )
    }

    func snapshot(
        for configuration: MileageWidgetConfiguration,
        in context: Context
    ) async -> MileageEntry {
        entry(for: configuration)
    }

    func timeline(
        for configuration: MileageWidgetConfiguration,
        in context: Context
    ) async -> Timeline<MileageEntry> {
        Timeline(
            entries: [entry(for: configuration)],
            policy: .after(Date().addingTimeInterval(15 * 60))
        )
    }

    private func entry(for configuration: MileageWidgetConfiguration) -> MileageEntry {
        let snapshot = try? MileageWriter.snapshot(for: configuration.vehicle?.id)
        let photo = snapshot.flatMap { snap in
            PhotoStore.loadSync(snap.photoRef).map { PhotoStore.preparedForWidget($0) }
        }
        return MileageEntry(date: Date(), snapshot: snapshot, photo: photo)
    }
}

struct MileageWidgetView: View {

    @Environment(\.widgetFamily) private var family
    @Environment(\.appTheme) private var theme

    var entry: MileageEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                populatedView(snapshot: snapshot)
            } else {
                emptyView
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .widgetURL(entry.snapshot.map { AntiCELDeepLink.mileage(vehicleID: $0.vehicleID) })
    }

    @ViewBuilder
    private func populatedView(snapshot: MileageSnapshot) -> some View {
        let vehicle = VehicleEntity(id: snapshot.vehicleID, name: snapshot.name)

        switch family {
        case .systemMedium:
            VStack(alignment: .leading, spacing: 10) {
                vehicleHeader(snapshot.name, onPhoto: usesPhotoBackdrop)
                OdometerView(mileage: snapshot.mileage, compact: true)
                    .frame(maxWidth: .infinity)
                incrementRow(vehicle: vehicle, kind: .key)
            }
            .padding(.vertical, 2)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(AppSettings.shared.formattedMileage(snapshot.mileage))
                    .font(.system(.title3, design: .monospaced).weight(.medium))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default:
            //small: mileage up top, full-width keys stacked so "+100" has room
            VStack(spacing: 6) {
                OdometerView(mileage: snapshot.mileage, compact: true)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 5) {
                    incrementButton(vehicle: vehicle, amount: 10, kind: .key, showsPlus: true)
                    incrementButton(vehicle: vehicle, amount: 50, kind: .key, showsPlus: true)
                    incrementButton(vehicle: vehicle, amount: 100, kind: .key, showsPlus: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func incrementRow(vehicle: VehicleEntity, kind: DashButtonKind) -> some View {
        HStack(spacing: 8) {
            incrementButton(vehicle: vehicle, amount: 10, kind: kind, showsPlus: true)
            incrementButton(vehicle: vehicle, amount: 50, kind: kind, showsPlus: true)
            incrementButton(vehicle: vehicle, amount: 100, kind: kind, showsPlus: true)
        }
    }

    private func incrementButton(
        vehicle: VehicleEntity,
        amount: Int,
        kind: DashButtonKind,
        showsPlus: Bool
    ) -> some View {
        let kilometers = AppSettings.shared.mileageUnit.storedKilometers(fromDisplay: amount)
        return Button(intent: AddMileageIntent(vehicle: vehicle, kilometers: kilometers)) {
            Text(showsPlus ? "+\(amount)" : "\(amount)")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        //unselected dash keys use primary label colour (selected forces accent blue)
        .buttonStyle(DashButtonStyle(isSelected: false, kind: kind))
        .invalidatableContent()
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.side")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text("Park a vehicle")
                .font(.appBadge)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var usesPhotoBackdrop: Bool {
        family == .systemMedium && entry.photo != nil
    }

    @ViewBuilder
    private var widgetBackground: some View {
        if usesPhotoBackdrop, let photo = entry.photo {
            ZStack {
                Color.black
                FramedPhotoView(
                    image: photo,
                    framing: entry.snapshot?.photoFraming ?? .identity
                )
                VehiclePhotoScrim()
            }
        } else {
            LinearGradient(
                colors: [theme.canvasTop, theme.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func vehicleHeader(_ name: String, onPhoto: Bool = false) -> some View {
        Text(name)
            .font(.appBadge)
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(onPhoto ? Color.white.opacity(0.92) : Color.primary)
            .shadow(color: onPhoto ? .black.opacity(0.45) : .clear, radius: 4, y: 1)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

#Preview("Small", as: .systemSmall) {
    MileageWidget()
} timeline: {
    MileageEntry(
        date: .now,
        snapshot: MileageSnapshot(vehicleID: UUID(), name: "Batmobile", mileage: 79500)
    )
}

#Preview("Medium", as: .systemMedium) {
    MileageWidget()
} timeline: {
    MileageEntry(
        date: .now,
        snapshot: MileageSnapshot(vehicleID: UUID(), name: "Batmobile", mileage: 79500)
    )
}
