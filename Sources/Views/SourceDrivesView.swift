import SwiftUI

struct SourceDrivesView: View {
    @EnvironmentObject var driveDetector: DriveDetector
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SOURCE CARDS")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(driveDetector.sourceCards) { card in
                        SourceCardView(drive: card)
                            .draggable(card)
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
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