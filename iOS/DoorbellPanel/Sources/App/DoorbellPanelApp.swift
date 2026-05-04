import SwiftUI

@main
struct DoorbellPanelApp: App {
    @State private var viewModel = DoorbellViewModel()

    var body: some Scene {
        WindowGroup {
            DoorbellView(viewModel: viewModel)
        }
    }
}

