import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct DestinationDrivesView: View {
    @EnvironmentObject var driveDetector: DriveDetector
    @EnvironmentObject var transferEngine: TransferEngine
    @State private var showDetectedDrives = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DESTINATIONS")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Manual destination folders (multiple slots)
                    ForEach(0..<3, id: \.self) { index in
                        if index < driveDetector.manualDestinationFolders.count {
                            let folder = driveDetector.manualDestinationFolders[index]
                            ManualDestinationView(
                                drive: folder,
                                onRemove: { driveDetector.removeDestinationFolder(at: index) }
                            )
                        } else {
                            DestinationDropZoneView(
                                title: "💾 Drop a folder",
                                subtitle: "(click to browse)",
                                action: browseForDestinationFolder
                            )
                        }
                    }
                    
                    // Auto-detected drives section
                    if !driveDetector.destinationDrives.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Button(action: { showDetectedDrives.toggle() }) {
                            HStack {
                                Image(systemName: showDetectedDrives ? "chevron.down" : "chevron.right")
                                    .font(.caption)
                                Text("Detected Drives")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if showDetectedDrives {
                            ForEach(driveDetector.destinationDrives) { drive in
                                DestinationDriveView(drive: drive)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func browseForDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "Select Destination Folder"
        panel.message = "Select a destination folder to transfer to"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                driveDetector.addDestinationFolder(url)
            }
        }
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
                    print("🎬 Drop received with sourceID: \(sourceID)")
                    print("🎬 Manual source folders: \(driveDetector.manualSourceFolders.count)")
                    print("🎬 Source cards: \(driveDetector.sourceCards.count)")
                    
                    // Check manual source folders first
                    if let sourceFolder = driveDetector.manualSourceFolders.first(where: { $0.id == sourceID }) {
                        print("🎬 Found manual source folder: \(sourceFolder.name)")
                        transferEngine.addTransfer(from: sourceFolder, to: drive)
                    } else if let sourceCard = driveDetector.sourceCards.first(where: { $0.id == sourceID }) {
                        transferEngine.addTransfer(from: sourceCard, to: drive)
                    } else {
                        print("❌ No matching source found for ID: \(sourceID)")
                    }
                }
            }
            
            return true
        }
    }
}

struct DestinationDropZoneView: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    @State private var isTargeted = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isTargeted ? Color.green.opacity(0.1) : Color(NSColor.controlColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isTargeted ? Color.green : 
                                isHovering ? Color.accentColor : Color.secondary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
            // Handle drop here if needed
            return false
        }
    }
}

struct ManualDestinationView: View {
    let drive: DriveInfo
    let onRemove: () -> Void
    @EnvironmentObject var driveDetector: DriveDetector
    @EnvironmentObject var transferEngine: TransferEngine
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(drive.name)
                        .font(.headline)
                    
                    Text(drive.path.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                Text("📥")
                    .font(.caption2)
                Text("drop sources here")
                    .font(.caption2)
            }
            .foregroundColor(.secondary.opacity(0.6))
        }
        .padding()
        .background(isTargeted ? Color.green.opacity(0.1) : Color(NSColor.controlColor))
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
                    print("🎬 Drop received with sourceID: \(sourceID)")
                    print("🎬 Manual source folders: \(driveDetector.manualSourceFolders.count)")
                    print("🎬 Source cards: \(driveDetector.sourceCards.count)")
                    
                    // Check manual source folders first
                    if let sourceFolder = driveDetector.manualSourceFolders.first(where: { $0.id == sourceID }) {
                        print("🎬 Found manual source folder: \(sourceFolder.name)")
                        transferEngine.addTransfer(from: sourceFolder, to: drive)
                    } else if let sourceCard = driveDetector.sourceCards.first(where: { $0.id == sourceID }) {
                        transferEngine.addTransfer(from: sourceCard, to: drive)
                    } else {
                        print("❌ No matching source found for ID: \(sourceID)")
                    }
                }
            }
            
            return true
        }
    }
}