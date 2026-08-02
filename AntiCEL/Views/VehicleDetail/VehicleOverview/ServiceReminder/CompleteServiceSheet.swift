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

        NavigationStack {

            Form {

                Section("Completion") {

                    DatePicker(
                        "Completion Date",
                        selection: $completionDate,
                        displayedComponents: .date
                    )

                    VStack(alignment: .leading, spacing: 6) {

                        Text("Mileage")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField(
                            "Current mileage",
                            text: $completionMileage
                        )
                        .keyboardType(.numberPad)

                    }

                }

            }
            .navigationTitle("Complete Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }

                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Continue") {

                        onContinue(
                            completionDate,
                            Int(completionMileage)
                        )
                        dismiss()

                    }
                    .bold()

                }

            }

        }

    }

}
