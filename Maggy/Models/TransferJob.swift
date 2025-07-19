import Foundation

struct TransferJob: Identifiable {
    let id = UUID()
    let sourcePath: URL
    var destinationPath: URL
    var totalSize: Int64
    var copiedSize: Int64 = 0
    var status: TransferStatus = .queued
    var checksum: String?
    var error: TransferError?
    var files: [FileTransfer] = []
    
    var progress: Double {
        guard totalSize > 0 else { return 0 }
        return Double(copiedSize) / Double(totalSize)
    }
    
    var formattedProgress: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: progress)) ?? "0%"
    }
    
    var sourceName: String {
        sourcePath.lastPathComponent
    }
    
    var destinationName: String {
        destinationPath.lastPathComponent
    }
}

enum TransferStatus {
    case queued
    case preparing
    case transferring
    case verifying
    case completed
    case failed
    case cancelled
    
    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .preparing: return "Preparing"
        case .transferring: return "Transferring"
        case .verifying: return "Verifying"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .queued: return "clock"
        case .preparing: return "gear"
        case .transferring: return "arrow.right.circle.fill"
        case .verifying: return "checkmark.shield"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

struct FileTransfer {
    let sourcePath: URL
    let destinationPath: URL
    let size: Int64
    var checksum: String?
    var status: TransferStatus = .queued
}

enum TransferError: LocalizedError {
    case diskFull
    case permissionDenied
    case sourceNotReadable
    case checksumMismatch(expected: String, actual: String)
    case ioError(String)
    
    var errorDescription: String? {
        switch self {
        case .diskFull:
            return "Destination disk is full"
        case .permissionDenied:
            return "Permission denied to write to destination"
        case .sourceNotReadable:
            return "Source file is not readable"
        case .checksumMismatch(let expected, let actual):
            return "Checksum mismatch - Expected: \(expected), Got: \(actual)"
        case .ioError(let message):
            return "I/O Error: \(message)"
        }
    }
}