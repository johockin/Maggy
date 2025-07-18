import SwiftUI

struct ContentView: View {
    @EnvironmentObject var driveDetector: DriveDetector
    @EnvironmentObject var transferEngine: TransferEngine
    @State private var showSettings = false
    @State private var isTestMode = true
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(showSettings: $showSettings, isTestMode: $isTestMode)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            HStack(spacing: 0) {
                SourceDrivesView()
                    .frame(minWidth: 300)
                
                Divider()
                
                DestinationDrivesView()
                    .frame(minWidth: 400)
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            TransferQueueView()
                .frame(height: 200)
            
            Divider()
            
            ControlsView()
                .padding()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isTestMode: $isTestMode)
        }
        .onAppear {
            if isTestMode {
                driveDetector.loadTestData()
            } else {
                driveDetector.startMonitoring()
            }
        }
    }
}

struct HeaderView: View {
    @Binding var showSettings: Bool
    @Binding var isTestMode: Bool
    
    var body: some View {
        HStack {
            Text("Maggy - Footage Dumper")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isTestMode {
                Text("(Test Mode)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gear")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }
}

struct ControlsView: View {
    @EnvironmentObject var transferEngine: TransferEngine
    
    var body: some View {
        HStack(spacing: 16) {
            Button("Start Transfers") {
                transferEngine.startTransfers()
            }
            .buttonStyle(.borderedProminent)
            .disabled(transferEngine.transfers.isEmpty || transferEngine.isTransferring)
            
            Button("Pause All") {
                transferEngine.pauseAll()
            }
            .disabled(!transferEngine.isTransferring)
            
            Spacer()
            
            if transferEngine.isTransferring {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Transferring...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}