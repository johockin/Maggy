import SwiftUI

struct ContentView: View {
    @StateObject private var driveDetector = DriveDetector()
    @StateObject private var transferEngine = TransferEngine()
    @AppStorage("isRushModeEnabled") private var isRushModeEnabled = false
    @State private var showSourceDestination = false
    @State private var showRushModeWarning = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            // Main content area - switches between queue view and source/destination view
            if !transferEngine.transfers.isEmpty && !showSourceDestination {
                // Transfer queue takes over 90% of interface when transfers exist
                VStack(spacing: 0) {
                    // Compact header showing counts and toggle button
                    HStack {
                        HStack(spacing: 16) {
                            Label("\(allSources.count) Sources", systemImage: "folder.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Label("\(allDestinations.count) Destinations", systemImage: "externaldrive.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Add More Transfers") {
                            showSourceDestination = true
                        }
                        .font(.caption)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Transfer queue takes remaining space
                    ScrollViewReader { proxy in
                        TransferQueueView(showSourceDestination: $showSourceDestination)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .onAppear {
                                proxy.scrollTo("top", anchor: .top)
                            }
                            .onChange(of: transferEngine.isTransferring) { isTransferring in
                                if isTransferring {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            }
                    }
                }
            } else {
                // Normal source/destination interface
                HStack(spacing: 0) {
                    SourceDrivesView()
                        .frame(minWidth: 250)
                    
                    Divider()
                    
                    DestinationDrivesView()
                        .frame(minWidth: 300)
                }
                .frame(maxHeight: .infinity)
                
                // Show "Back to Transfers" button if we have transfers
                if !transferEngine.transfers.isEmpty && showSourceDestination {
                    Divider()
                    
                    Button("← Back to Transfers") {
                        showSourceDestination = false
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Divider()
            
            ControlsView(showSourceDestination: $showSourceDestination)
                .padding()
        }
        .environmentObject(driveDetector)
        .environmentObject(transferEngine)
        .onAppear {
            driveDetector.startMonitoring()
        }
        .overlay(
            // Rush Mode Warning Popup
            Group {
                if showRushModeWarning {
                    VStack {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.orange)
                                Text("Rush Mode Enabled")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Faster transfers with lightweight verification. Still detects corruption but not cryptographically secure.")
                                    .font(.caption)
                                
                                Text("Use only for trusted environments.")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .frame(maxWidth: 300)
                        .padding()
                        
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        )
    }
    
    private var allSources: [DriveInfo] {
        driveDetector.manualSourceFolders.filter { !$0.isDisabled } + driveDetector.sourceCards
    }
    
    private var allDestinations: [DriveInfo] {
        driveDetector.manualDestinationFolders + driveDetector.destinationDrives
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Text("Maggy - Footage Dumper")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct ControlsView: View {
    @EnvironmentObject var transferEngine: TransferEngine
    @EnvironmentObject var driveDetector: DriveDetector
    @AppStorage("isRushModeEnabled") private var isRushModeEnabled = false
    @Binding var showSourceDestination: Bool
    @State private var showingSettings = false
    @State private var showRushModeWarning = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Only show Queue All button when in source/destination view (not in transfer monitoring mode)
            if transferEngine.transfers.isEmpty || showSourceDestination {
                // THE STAR BUTTON - Queue All gets its own prominent space
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 32)
                    
                    Button(action: {
                        transferEngine.queueAllSourcesAllDestinations(driveDetector: driveDetector)
                    }) {
                        Text("Queue All")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 480, height: 80)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(red: 0.3, green: 0.4, blue: 0.7), Color(red: 0.25, green: 0.35, blue: 0.6)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .disabled(allSources.isEmpty || allDestinations.isEmpty || transferEngine.isTransferring)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    if let message = transferEngine.queueFeedbackMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                        .frame(height: 16)
                }
                
                if !transferEngine.transfers.isEmpty {
                    HStack {
                        Spacer()
                        
                        Button("Clear Queue") {
                            transferEngine.clearAllTransfers()
                        }
                        .disabled(transferEngine.isTransferring)
                        .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
                
                Divider()
            }
            
            // Bottom Status Bar with Transfer Status and Rush Mode Toggle
            HStack(spacing: 16) {
                // Rush Mode Toggle (left side)
                Toggle(isOn: Binding(
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
                )) {
                    HStack(spacing: 4) {
                        Text("Rush Mode")
                            .font(.caption)
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                
                Spacer()
                
                // Transfer Status (right side)
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
                
                // Settings button (bottom right)
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var allSources: [DriveInfo] {
        driveDetector.manualSourceFolders.filter { !$0.isDisabled } + driveDetector.sourceCards
    }
    
    private var allDestinations: [DriveInfo] {
        driveDetector.manualDestinationFolders + driveDetector.destinationDrives
    }
}