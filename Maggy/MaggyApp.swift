import SwiftUI

@main
struct MaggyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
    }
}