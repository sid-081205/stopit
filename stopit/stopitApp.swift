import SwiftUI

@main
struct stopitApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .tint(.white)
                .task { await model.load() }
        }
    }
}
