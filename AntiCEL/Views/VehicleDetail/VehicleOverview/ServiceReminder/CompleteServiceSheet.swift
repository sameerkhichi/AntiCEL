import SwiftUI

struct CompleteServiceSheet: View {

    @Environment(\.dismiss) private var dismiss

    let reminder: ServiceReminder
    let onContinue: (Date, Int?) -> Void

    @State private var completionDate: Date
    @State private var completionMileage: String

    init(
        reminder: ServiceReminder,
        onContinue: @escaping (Date, Int?) -> Void
    ) {
        self.reminder = reminder
        self.onContinue = onContinue

        _completionDate = State(
            initialValue: reminder.dueDate ?? Date()
        )

        _completionMileage = State(
            initialValue: reminder.dueMileage.map(String.init) ?? ""
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
                    Int(completionMileage)
                )
                dismiss()
            }
        ) {
            InfotainmentField(label: "Completion Date") {
                DatePicker(
                    "Completion Date",
                    selection: $completionDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }

            InfotainmentField(label: "Mileage") {
                TextField("Current mileage", text: $completionMileage)
                    .keyboardType(.numberPad)
            }
        }
        .appTheme()
    }
}
