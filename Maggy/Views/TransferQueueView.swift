import SwiftUI

struct TransferQueueView: View {
    @EnvironmentObject var transferEngine: TransferEngine
    @AppStorage("isRushModeEnabled") private var isRushModeEnabled = false
    @Binding var showSourceDestination: Bool
    
    var hasQueuedTransfers: Bool {
        !transferEngine.transfers.isEmpty && 
        !transferEngine.isTransferring && 
        transferEngine.transfers.contains(where: { $0.status == .queued })
    }
    
    var allTransfersComplete: Bool {
        !transferEngine.transfers.isEmpty &&
        !transferEngine.isTransferring &&
        transferEngine.transfers.allSatisfy { $0.status == .completed || $0.status == .failed || $0.status == .cancelled }
    }
    
    var queuedTransferCount: Int {
        transferEngine.transfers.filter { $0.status == .queued }.count
    }
    
    var currentTransferIndex: Int {
        if let currentTransfer = transferEngine.currentTransfer,
           let index = transferEngine.transfers.firstIndex(where: { $0.id == currentTransfer.id }) {
            return index + 1
        }
        return 0
    }
    
    var totalTransferCount: Int {
        transferEngine.transfers.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRANSFER QUEUE")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if transferEngine.isTransferring && currentTransferIndex > 0 {
                        Text("Transfer \(currentTransferIndex) of \(totalTransferCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !transferEngine.transfers.isEmpty {
                    Button("Clear Completed") {
                        transferEngine.clearCompleted()
                    }
                    .font(.caption)
                    .disabled(transferEngine.isTransferring)
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Top anchor for scroll positioning
                    HStack {
                        Spacer()
                    }
                    .frame(height: 1)
                    .id("top")
                    
                    ForEach(transferEngine.transfers) { transfer in
                        TransferItemView(transfer: transfer)
                    }
                    
                    // Large Start Transfers button at bottom - only show when transfers are ready and not all complete
                    if hasQueuedTransfers {
                        Spacer()
                            .frame(height: 24) // Reduced spacing
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                transferEngine.startTransfers()
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.title2)
                                    Text("Start Transfers (\(queuedTransferCount))")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(minWidth: 320) // Wider, more commanding
                                .padding(.vertical, 20) // More substantial
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            Spacer()
                        }
                        
                        // Clear Queue button below Start Transfers (destructive action at bottom)
                        if !transferEngine.transfers.isEmpty {
                            Button("Clear Queue") {
                                transferEngine.clearAllTransfers()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .disabled(transferEngine.isTransferring)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                            .frame(height: 16) // Reduced bottom spacing
                    }
                    
                    // Add More Transfers button when all complete (secondary styling, less emphatic)
                    if allTransfersComplete {
                        Spacer()
                            .frame(height: 24)
                        
                        HStack {
                            Spacer()
                            
                            Button("Add More Transfers") {
                                showSourceDestination = true
                            }
                            .buttonStyle(.bordered) // Secondary styling, not prominent
                            .controlSize(.large)
                            .font(.title3)
                            .frame(minWidth: 280)
                            
                            Spacer()
                        }
                        
                        Spacer()
                            .frame(height: 16)
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct TransferItemView: View {
    let transfer: TransferJob
    @EnvironmentObject var transferEngine: TransferEngine
    @AppStorage("isRushModeEnabled") private var isRushModeEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Image(systemName: transfer.status.icon)
                        .foregroundColor(statusColor)
                        .font(.title3)
                    
                    // Subtle overlay for active transfer
                    if transfer.id == transferEngine.currentTransfer?.id {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 1)
                            .frame(width: 32, height: 32)
                            .opacity(0.5)
                            .scaleEffect(1.1)
                    }
                }
                .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(transfer.sourceName)
                            .font(.headline)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(transfer.destinationName)
                            .font(.headline)
                    }
                    
                    if let error = transfer.error {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if transfer.status == .verifying {
                        Text(isRushModeEnabled ? "Quick verification in progress..." : "Verifying bit-perfect accuracy...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if transfer.status != .completed {
                        Text(transfer.status.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if transfer.status == .transferring || transfer.status == .verifying {
                    Text(transfer.formattedProgress)
                        .font(.caption)
                        .monospacedDigit()
                }
                
                // Individual cancel button for each transfer
                Button(action: {
                    transferEngine.cancelTransfer(transferId: transfer.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .opacity(transfer.status == .transferring || transfer.status == .queued ? 1.0 : 0.0)
            }
            
            if transfer.status == .transferring || transfer.status == .verifying || transfer.status == .completed {
                VStack(alignment: .trailing, spacing: 2) {
                    ProgressView(value: transfer.status == .completed || transfer.status == .verifying ? 1.0 : transfer.progress)
                        .progressViewStyle(.linear)
                        .tint(transfer.status == .completed ? Color(.systemGreen).opacity(0.7) : 
                              transfer.status == .verifying ? .blue : .secondary)
                    
                    // Show verification status or confirmation
                    if transfer.status == .verifying {
                        Text(isRushModeEnabled ? "Quick verification in progress..." : "Verifying bit-perfect accuracy...")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .italic()
                    } else if transfer.status == .completed {
                        Text(isRushModeEnabled ? 
                             "✓ Transfer verified - High-speed integrity check passed" :
                             "✓ Bit-perfect copy verified - SHA-256 match")
                            .font(.caption2)
                            .foregroundColor(Color(.systemGreen).opacity(0.8))
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(6)
    }
    
    var statusColor: Color {
        switch transfer.status {
        case .completed: return .green
        case .failed: return .red
        case .transferring, .verifying: return .blue
        case .cancelled: return .orange
        default: return .secondary
        }
    }
}