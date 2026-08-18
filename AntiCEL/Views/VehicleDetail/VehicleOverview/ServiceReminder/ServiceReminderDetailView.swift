import SwiftUI
import SwiftData

struct ServiceReminderDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @State private var showDeleteAlert = false
    @State private var showCompletionSheet = false
    @State private var isCompleting = false

    let reminder: ServiceReminder

    var body: some View {
        VStack(spacing: 20) {
            DashPanel {
                VStack(alignment: .leading, spacing: 16) {
                    Text(reminder.name)
                        .font(.largeTitle.weight(.bold).width(.condensed))

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    infoRow(title: "Type", value: reminder.type.rawValue)
                    infoRow(title: "Related To", value: reminder.resolvedVehicleArea.displayName)

                    switch reminder.type {
                    case .date:
                        infoRow(
                            title: "Due Date",
                            value: reminder.dueDate?.formatted(
                                date: .abbreviated,
                                time: .omitted
                            ) ?? "Not Set"
                        )

                    case .mileage:
                        infoRow(
                            title: "Due Mileage",
                            value: settings.formattedMileage(reminder.dueMileage)
                        )

                    case .whicheverComesFirst:
                        infoRow(
                            title: "Due Date",
                            value: reminder.dueDate?.formatted(
                                date: .abbreviated,
                                time: .omitted
                            ) ?? "Not Set"
                        )

                        infoRow(
                            title: "Due Mileage",
                            value: settings.formattedMileage(reminder.dueMileage)
                        )
                    }

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    Text("Notes")
                        .font(.headline)

                    Text(
                        reminder.notes.isEmpty
                        ? "No notes."
                        : reminder.notes
                    )
                    .foregroundStyle(reminder.notes.isEmpty ? .secondary : .primary)
                }
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                DashButton(isSelected: true, kind: .bar) {
                    showCompletionSheet = true
                } label: {
                    Text("Complete Service")
                }
                .disabled(isCompleting)

                DashButton(kind: .bar, isDestructive: true) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete Reminder")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical)
        .appCanvas()
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .sheet(isPresented: $showCompletionSheet) {
            CompleteServiceSheet(reminder: reminder) { date, mileage, photoDraft in
                completeService(
                    completionDate: date,
                    completionMileage: mileage,
                    photoDraft: photoDraft
                )
            }
        }
        .alert(
            "Delete Reminder?",
            isPresented: $showDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(reminder)
                ReminderNotifications.refresh(using: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This reminder will be permanently deleted.")
        }
    }

    private func completeService(
        completionDate: Date,
        completionMileage: Int?,
        photoDraft: PhotoDraft
    ) {
        guard let vehicle = reminder.vehicle, !isCompleting else {
            return
        }

        isCompleting = true

        Task {
            let photoRef = await photoDraft.commit(
                copyIntoApp: settings.savePhotosInApp,
                kind: .attachment
            )

            let newEntry = HistoryEntry(
                title: reminder.name,
                details: reminder.notes,
                date: completionDate,
                mileage: completionMileage,
                category: .maintenance,
                vehicleArea: reminder.resolvedVehicleArea,
                photoFileName: photoRef,
                vehicle: vehicle
            )

            modelContext.insert(newEntry)
            vehicle.historyEntries.append(newEntry)
            modelContext.delete(reminder)
            ReminderNotifications.refresh(using: modelContext)
            dismiss()
        }
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.appBadge)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        ServiceReminderDetailView(
            reminder: ServiceReminder(
                name: "Oil Change",
                type: .whicheverComesFirst,
                dueDate: .now,
                dueMileage: 80000,
                notes: "Use Liqui Moly 5W-40"
            )
        )
    }
    .appTheme()
}
