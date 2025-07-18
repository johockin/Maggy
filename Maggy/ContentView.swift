import SwiftUI

struct ContentView: View {
    @StateObject private var driveDetector = DriveDetector()
    @StateObject private var transferEngine = TransferEngine()
    @State private var showSettings = false
    @State private var isTestMode = true
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(showSettings: $showSettings, isTestMode: $isTestMode)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            // Source/Destination panels - ALWAYS VISIBLE but adapt size when transferring
            HStack(spacing: 0) {
                SourceDrivesView()
                    .frame(minWidth: 250)
                
                Divider()
                
                DestinationDrivesView()
                    .frame(minWidth: 300)
            }
            .frame(maxHeight: transferEngine.isTransferring ? 200 : .infinity)
            
            // Transfer queue - PRIMARY FOCUS when active
            if !transferEngine.transfers.isEmpty {
                Divider()
                
                ScrollViewReader { proxy in
                    TransferQueueView()
                        .frame(height: transferEngine.isTransferring ? 300 : 150)
                        .onAppear {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        .onChange(of: transferEngine.isTransferring) { isTransferring in
                            if isTransferring {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                }
                
                Divider()
            }
            
            ControlsView()
                .padding()
        }
        .environmentObject(driveDetector)
        .environmentObject(transferEngine)
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
        .onChange(of: isTestMode) { newValue in
            if newValue {
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
    @EnvironmentObject var driveDetector: DriveDetector
    
    var body: some View {
        VStack(spacing: 12) {
            // Single Batch Queue Button - Simple!
            HStack(spacing: 12) {
                Button("🎯 Queue All Sources → All Destinations") {
                    transferEngine.queueAllSourcesAllDestinations(driveDetector: driveDetector)
                }
                .buttonStyle(.borderedProminent)
                .disabled(allSources.isEmpty || allDestinations.isEmpty || transferEngine.isTransferring)
                
                if !transferEngine.transfers.isEmpty {
                    Button("Clear Queue") {
                        transferEngine.clearAllTransfers()
                    }
                    .disabled(transferEngine.isTransferring)
                }
            }
            
            Divider()
            
            // Transfer Controls
            HStack(spacing: 16) {
                Button("▶️ Start Transfers (\(transferEngine.transfers.count))") {
                    transferEngine.startTransfers()
                }
                .buttonStyle(.borderedProminent)
                .disabled(transferEngine.transfers.isEmpty || transferEngine.isTransferring)
                
                Spacer()
                
                if transferEngine.isTransferring {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Transferring...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !transferEngine.transfers.isEmpty {
                    Text("\(transferEngine.transfers.count) transfers queued")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var allSources: [DriveInfo] {
        driveDetector.manualSourceFolders + driveDetector.sourceCards
    }
    
    private var allDestinations: [DriveInfo] {
        driveDetector.manualDestinationFolders + driveDetector.destinationDrives
    }
}