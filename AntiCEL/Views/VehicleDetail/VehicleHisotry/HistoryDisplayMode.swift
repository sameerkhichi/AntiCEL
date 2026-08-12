enum HistoryDisplayMode: String, CaseIterable, Identifiable {
    case list = "List"
    case model = "Model"

    var id: Self { self }
}
