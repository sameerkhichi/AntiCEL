enum HistoryDisplayMode: String, CaseIterable, Identifiable {
    case list = "List"
    case timeline = "Timeline"

    var id: Self { self }
}
