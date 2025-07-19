import Foundation
import Combine

@MainActor
class SettingsManager: ObservableObject {
    @Published var isRushModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isRushModeEnabled, forKey: "isRushModeEnabled")
        }
    }
    
    @Published var showRushModeWarning: Bool = false
    
    init() {
        self.isRushModeEnabled = UserDefaults.standard.bool(forKey: "isRushModeEnabled")
    }
    
    func toggleRushMode() {
        if !isRushModeEnabled {
            // Enabling Rush Mode - show warning
            showRushModeWarning = true
            
            // Auto-dismiss warning after 3 seconds
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    showRushModeWarning = false
                }
            }
        }
        
        isRushModeEnabled.toggle()
    }
}