import SwiftUI

@main
struct MacCleanerApp: App {
    @StateObject private var model = AppModel()
    
    var body: some Scene {
        WindowGroup {
            Views(model: model)
                .navigationTitle("MacCleaner")
        }
        .windowStyle(TitleBarWindowStyle())
    }
}
