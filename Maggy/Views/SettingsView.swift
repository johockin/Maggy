import SwiftUI

struct SettingsView: View {
    @AppStorage("isRushModeEnabled") private var isRushModeEnabled = false
    @State private var showRushModeWarning = false
    @AppStorage("showDetailedLogs") private var showDetailedLogs = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Maggy Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.return)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Verification Mode")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Default Mode")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Cryptographic verification with SHA-256 (~200 MB/s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Bit-perfect accuracy guaranteed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !isRushModeEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(isRushModeEnabled ? Color.clear : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Rush Mode")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "bolt.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Text("High-speed integrity checking with xxHash (~1 GB/s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Still excellent error detection")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { isRushModeEnabled },
                            set: { newValue in 
                                if newValue && !isRushModeEnabled {
                                    showRushModeWarning = true
                                    // Auto-dismiss warning after 3 seconds
                                    Task {
                                        try await Task.sleep(nanoseconds: 3_000_000_000)
                                        await MainActor.run {
                                            showRushModeWarning = false
                                        }
                                    }
                                }
                                isRushModeEnabled = newValue
                            }
                        ))
                        .toggleStyle(.switch)
                    }
                    .padding()
                    .background(isRushModeEnabled ? Color(NSColor.controlBackgroundColor) : Color.clear)
                    .cornerRadius(8)
                }
                
                if isRushModeEnabled {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Use only in trusted environments. Not cryptographically secure.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }
                
                if showRushModeWarning {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.orange)
                        Text("Rush Mode enabled - faster transfers with lightweight verification")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advanced")
                        .font(.headline)
                    
                    Toggle("Show Detailed Logs", isOn: $showDetailedLogs)
                        .help("Display verbose logging information during transfers")
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 450)
    }
}