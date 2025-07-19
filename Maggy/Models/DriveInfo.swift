import Foundation
import CoreTransferable

struct DriveInfo: Identifiable, Transferable {
    let id = UUID()
    let name: String
    let path: URL
    let totalSpace: Int64
    let freeSpace: Int64
    let isRemovable: Bool
    let cameraType: CameraType?
    let mountPoint: String
    var isDisabled: Bool = false
    var disabledReason: String?
    
    var formattedFreeSpace: String {
        ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }
    
    var formattedTotalSpace: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }
    
    var icon: String {
        if let camera = cameraType {
            return camera.icon
        }
        return isRemovable ? "sdcard.fill" : "externaldrive.fill"
    }
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.id.uuidString)
    }
}

enum CameraType {
    case fx6
    case a7s
    case redCamera
    case arri
    case generic
    
    var icon: String {
        switch self {
        case .fx6, .a7s: return "camera.fill"
        case .redCamera: return "video.fill"
        case .arri: return "film.fill"
        case .generic: return "camera"
        }
    }
    
    var displayName: String {
        switch self {
        case .fx6: return "FX6"
        case .a7s: return "A7S"
        case .redCamera: return "RED"
        case .arri: return "ARRI"
        case .generic: return "Camera"
        }
    }
    
    static func detect(from path: URL) -> CameraType? {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: path.appendingPathComponent("PRIVATE/M4ROOT").path) {
            return .fx6
        } else if fileManager.fileExists(atPath: path.appendingPathComponent("DCIM").path) {
            return .a7s
        }
        
        return nil
    }
}