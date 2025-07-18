import SwiftUI
import UniformTypeIdentifiers

struct DestinationDrivesView: View {
    @EnvironmentObject var driveDetector: DriveDetector
    @EnvironmentObject var transferEngine: TransferEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DESTINATION DRIVES")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(driveDetector.destinationDrives) { drive in
                        DestinationDriveView(drive: drive)
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct DestinationDriveView: View {
    let drive: DriveInfo
    @EnvironmentObject var driveDetector: DriveDetector
    @EnvironmentObject var transferEngine: TransferEngine
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: drive.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(drive.name)
                        .font(.headline)
                    
                    Text("\(drive.formattedFreeSpace) free")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            ProgressView(value: Double(drive.totalSpace - drive.freeSpace), total: Double(drive.totalSpace))
                .progressViewStyle(.linear)
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isTargeted ? Color.green : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isTargeted ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
                guard let data = data as? Data,
                      let idString = String(data: data, encoding: .utf8),
                      let sourceID = UUID(uuidString: idString) else {
                    return
                }
                
                Task { @MainActor in
                    if let sourceCard = driveDetector.sourceCards.first(where: { $0.id == sourceID }) {
                        transferEngine.addTransfer(from: sourceCard, to: drive)
                    }
                }
            }
            
            return true
        }
    }
}