enum HistoryDisplayMode: String, CaseIterable, Identifiable {
    case model = "Model"
    case list = "List"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .model:
            return "car.side.fill"
        case .list:
            return "list.bullet"
        }
    }

    var toggleTitle: String {
        switch self {
        case .model:
            return "List"
        case .list:
            return "Model"
        }
    }

    var toggleIconName: String {
        switch self {
        case .model:
            return "list.bullet"
        case .list:
            return "car.side.fill"
        }
    }

    mutating func toggle() {
        self = self == .model ? .list : .model
    }
}
