import SwiftUI

@main
struct MaggyApp: App {
    @StateObject private var driveDetector = DriveDetector()
    @StateObject private var transferEngine = TransferEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(driveDetector)
                .environmentObject(transferEngine)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem, addition: {})
        }
    }
}