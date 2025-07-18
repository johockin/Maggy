import SwiftUI

struct TransferQueueView: View {
    @EnvironmentObject var transferEngine: TransferEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TRANSFER QUEUE")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
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
                VStack(spacing: 8) {
                    ForEach(transferEngine.transfers) { transfer in
                        TransferItemView(transfer: transfer)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: transfer.status.icon)
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
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
                    } else {
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
            }
            
            if transfer.status == .transferring || transfer.status == .verifying {
                ProgressView(value: transfer.progress)
                    .progressViewStyle(.linear)
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
        case .paused: return .orange
        default: return .secondary
        }
    }
}