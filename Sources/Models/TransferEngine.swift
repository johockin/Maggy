import Foundation
import Combine
import AppKit

@MainActor
class TransferEngine: ObservableObject {
    @Published var transfers: [TransferJob] = []
    @Published var currentTransfer: TransferJob?
    @Published var isTransferring = false
    
    private var fileOperations: FileOperations
    private var checksumManager: ChecksumManager
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.fileOperations = FileOperations()
        self.checksumManager = ChecksumManager()
    }
    
    func addTransfer(from source: DriveInfo, to destination: DriveInfo) {
        let destinationPath = destination.path.appendingPathComponent(source.name + "_" + Date().ISO8601Format())
        
        Task {
            do {
                let files = try await fileOperations.enumerateFiles(at: source.path)
                let totalSize = files.reduce(0) { $0 + $1.size }
                
                var job = TransferJob(
                    sourcePath: source.path,
                    destinationPath: destinationPath,
                    totalSize: totalSize
                )
                job.files = files.map { file in
                    FileTransfer(
                        sourcePath: file.path,
                        destinationPath: destinationPath.appendingPathComponent(file.relativePath),
                        size: file.size
                    )
                }
                
                transfers.append(job)
            } catch {
                print("Failed to enumerate files: \(error)")
            }
        }
    }
    
    func startTransfers() {
        guard !isTransferring, let nextTransfer = transfers.first(where: { $0.status == .queued }) else {
            return
        }
        
        isTransferring = true
        processTransfer(nextTransfer)
    }
    
    func pauseAll() {
        isTransferring = false
        if var current = currentTransfer {
            current.status = .paused
            updateTransfer(current)
        }
    }
    
    func clearCompleted() {
        transfers.removeAll { $0.status == .completed }
    }
    
    private func processTransfer(_ transfer: TransferJob) {
        Task {
            var job = transfer
            job.status = .preparing
            updateTransfer(job)
            currentTransfer = job
            
            do {
                try FileManager.default.createDirectory(at: job.destinationPath, withIntermediateDirectories: true)
                
                job.status = .transferring
                updateTransfer(job)
                
                for (index, file) in job.files.enumerated() {
                    guard isTransferring else {
                        job.status = .paused
                        updateTransfer(job)
                        return
                    }
                    
                    let fileDestination = file.destinationPath
                    try FileManager.default.createDirectory(at: fileDestination.deletingLastPathComponent(), withIntermediateDirectories: true)
                    
                    let checksum = try await fileOperations.copyFile(
                        from: file.sourcePath,
                        to: fileDestination,
                        progress: { bytesWritten in
                            Task { @MainActor in
                                job.copiedSize += Int64(bytesWritten)
                                self.updateTransfer(job)
                            }
                        }
                    )
                    
                    job.files[index].checksum = checksum
                    job.files[index].status = .completed
                }
                
                job.status = .verifying
                updateTransfer(job)
                
                let allChecksumsValid = job.files.allSatisfy { $0.checksum != nil }
                
                if allChecksumsValid {
                    job.status = .completed
                } else {
                    job.status = .failed
                    job.error = .checksumMismatch(expected: "valid", actual: "invalid")
                }
                
                updateTransfer(job)
                currentTransfer = nil
                
                if isTransferring {
                    startTransfers()
                }
                
            } catch {
                job.status = .failed
                job.error = .ioError(error.localizedDescription)
                updateTransfer(job)
                currentTransfer = nil
                
                await showErrorDialog(for: job, error: error)
            }
        }
    }
    
    private func updateTransfer(_ transfer: TransferJob) {
        if let index = transfers.firstIndex(where: { $0.id == transfer.id }) {
            transfers[index] = transfer
        }
    }
    
    private func showErrorDialog(for job: TransferJob, error: Error) async {
        let alert = NSAlert()
        alert.messageText = "Transfer Failed: \(job.sourceName)"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Skip")
        alert.addButton(withTitle: "Stop")
        
        let response = await MainActor.run {
            alert.runModal()
        }
        
        switch response {
        case .alertFirstButtonReturn:
            var retryJob = job
            retryJob.status = .queued
            retryJob.copiedSize = 0
            retryJob.error = nil
            updateTransfer(retryJob)
            if isTransferring {
                processTransfer(retryJob)
            }
            
        case .alertSecondButtonReturn:
            if isTransferring {
                startTransfers()
            }
            
        default:
            isTransferring = false
        }
    }
}