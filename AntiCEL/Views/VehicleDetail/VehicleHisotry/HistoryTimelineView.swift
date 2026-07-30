import SwiftUI

struct HistoryTimelineView: View {

    @Bindable var vehicle: Vehicle

    var body: some View {

        ContentUnavailableView(
            "Timeline Coming Soon",
            systemImage: "point.bottomleft.forward.to.point.topright.scurvepath",
            description: Text("The timeline view will be available in a future update.")
        )

    }

}
