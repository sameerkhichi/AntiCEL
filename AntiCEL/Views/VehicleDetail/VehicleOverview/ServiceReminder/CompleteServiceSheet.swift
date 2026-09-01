import SwiftUI

struct CompleteServiceSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    let reminder: ServiceReminder
    let onContinue: (Date, Int?, PhotoDraft) -> Void

    @State private var completionDate: Date
    @State private var completionMileage: Int
    @State private var photoDraft = PhotoDraft()

    init(
        reminder: ServiceReminder,
        onContinue: @escaping (Date, Int?, PhotoDraft) -> Void
    ) {
        self.reminder = reminder
        self.onContinue = onContinue

        _completionDate = State(
            initialValue: reminder.dueDate ?? Date()
        )

        let storedKilometers = reminder.dueMileage
            ?? reminder.vehicle?.currentMileage
            ?? 0
        _completionMileage = State(
            initialValue: AppSettings.shared.mileageUnit.displayValue(
                fromStoredKilometers: storedKilometers
            )
        )
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Complete Service",
            confirmTitle: "Continue",
            onCancel: { dismiss() },
            onConfirm: {
                onContinue(
                    completionDate,
                    settings.mileageUnit.storedKilometers(fromDisplay: completionMileage),
                    photoDraft
                )
                dismiss()
            }
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfotainmentField(label: "Completion Date") {
                    DatePicker(
                        "Completion Date",
                        selection: $completionDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                shortcutButton("Use Current Date") {
                    completionDate = Date()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                InfotainmentField(label: "Mileage (\(settings.mileageUnit.abbreviation))") {
                    MileageDigitScroller(mileage: $completionMileage)
                        .frame(maxWidth: .infinity)
                }

                shortcutButton("Use Current Mileage") {
                    applyCurrentMileage()
                }
            }

            PhotoAttachmentField(
                label: "Photo",
                footnote: "Optional. You can also add this later on the history record itself.",
                draft: $photoDraft
            )
        }
        .appTheme()
    }

    private func applyCurrentMileage() {
        let storedKilometers = reminder.vehicle?.currentMileage ?? 0
        completionMileage = settings.mileageUnit.displayValue(
            fromStoredKilometers: storedKilometers
        )
    }

    @ViewBuilder
    private func shortcutButton(_ title: String, action: @escaping () -> Void) -> some View {
        HStack {
            DashButton(kind: .compact, action: action) {
                Text(title)
            }
            Spacer(minLength: 0)
        }
    }
}
