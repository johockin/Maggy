import SwiftUI

struct SettingsView: View {
    @Binding var isTestMode: Bool
    @AppStorage("checksumAlgorithm") private var checksumAlgorithm = "SHA-256"
    @AppStorage("showDetailedLogs") private var showDetailedLogs = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            Form {
                Section("General") {
                    Toggle("Test Mode", isOn: $isTestMode)
                        .help("Use simulated drives and test data instead of real hardware")
                    
                    Toggle("Show Detailed Logs", isOn: $showDetailedLogs)
                        .help("Display verbose logging information during transfers")
                }
                
                Section("Checksum") {
                    Picker("Algorithm", selection: $checksumAlgorithm) {
                        Text("SHA-256 (Maximum Security)").tag("SHA-256")
                        Text("xxHash (Fast Verification)").tag("xxHash")
                            .disabled(true)
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text("SHA-256 is the industry standard for secure file verification. xxHash support coming soon.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Purpose")
                        Spacer()
                        Text("Hedge Replacement")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 400)
    }
}