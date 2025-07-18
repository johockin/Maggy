import SwiftUI
import AppKit

struct SourceDrivesView: View {
    @EnvironmentObject var driveDetector: DriveDetector
    @State private var showDetectedCards = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SOURCE")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Manual folder drop zone
                    if driveDetector.manualSourceFolders.isEmpty {
                        DropZoneView(
                            title: "📁 Drop a folder",
                            subtitle: "(click to browse)",
                            action: browseForSourceFolder
                        )
                    } else {
                        ForEach(Array(driveDetector.manualSourceFolders.enumerated()), id: \.element.id) { index, folder in
                            ManualFolderView(
                                drive: folder,
                                onRemove: { driveDetector.removeSourceFolder(at: index) }
                            )
                            .draggable(folder)
                        }
                        
                        Button("+ Add Another Folder") {
                            browseForSourceFolder()
                        }
                        .font(.caption)
                        .padding(.top, 8)
                    }
                    
                    // Auto-detected cards section
                    if !driveDetector.sourceCards.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Button(action: { showDetectedCards.toggle() }) {
                            HStack {
                                Image(systemName: showDetectedCards ? "chevron.down" : "chevron.right")
                                    .font(.caption)
                                Text("Detected Cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if showDetectedCards {
                            ForEach(driveDetector.sourceCards) { card in
                                SourceCardView(drive: card)
                                    .draggable(card)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func browseForSourceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "Select Source Folder"
        panel.message = "Select a source folder to transfer from"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                driveDetector.addSourceFolder(url)
            }
        }
    }
}

struct SourceCardView: View {
    let drive: DriveInfo
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: drive.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(drive.name)
                        .font(.headline)
                    
                    if let camera = drive.cameraType {
                        Text(camera.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text(drive.formattedTotalSpace)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "hand.draw")
                    .font(.caption2)
                Text("drag me")
                    .font(.caption2)
            }
            .foregroundColor(.secondary.opacity(0.6))
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDragging ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .onDrag {
            isDragging = true
            return NSItemProvider(object: drive.id.uuidString as NSString)
        } preview: {
            VStack {
                Image(systemName: drive.icon)
                    .font(.largeTitle)
                Text(drive.name)
                    .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct DropZoneView: View {
    let title: String
    let subtitle: String
    let action: () -> Void
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
                    .fill(Color(NSColor.controlColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
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
    }
}

struct ManualFolderView: View {
    let drive: DriveInfo
    let onRemove: () -> Void
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
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
                Image(systemName: "hand.draw")
                    .font(.caption2)
                Text("drag to destination")
                    .font(.caption2)
            }
            .foregroundColor(.secondary.opacity(0.6))
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDragging ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .onDrag {
            isDragging = true
            return NSItemProvider(object: drive.id.uuidString as NSString)
        } preview: {
            VStack {
                Image(systemName: "folder.fill")
                    .font(.largeTitle)
                Text(drive.name)
                    .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}