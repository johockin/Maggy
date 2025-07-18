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
        print("🎬 Adding transfer from \(source.name) to \(destination.name)")
        let destinationPath = destination.path.appendingPathComponent(source.name + "_" + Date().ISO8601Format())
        
        // Add a placeholder transfer immediately for UI responsiveness
        let placeholderJob = TransferJob(
            sourcePath: source.path,
            destinationPath: destinationPath,
            totalSize: 0
        )
        transfers.append(placeholderJob)
        print("🎬 Placeholder transfer added. Total transfers: \(transfers.count)")
        
        Task {
            do {
                let files = try await fileOperations.enumerateFiles(at: source.path)
                let totalSize = files.reduce(0) { $0 + $1.size }
                
                await MainActor.run {
                    // Update the placeholder with real data
                    if let index = transfers.firstIndex(where: { $0.id == placeholderJob.id }) {
                        var job = transfers[index]
                        job.totalSize = totalSize
                        job.files = files.map { file in
                            FileTransfer(
                                sourcePath: file.path,
                                destinationPath: destinationPath.appendingPathComponent(file.relativePath),
                                size: file.size
                            )
                        }
                        transfers[index] = job
                        print("🎬 Transfer updated with \(files.count) files, total size: \(totalSize)")
                    }
                }
            } catch {
                await MainActor.run {
                    // Remove the placeholder on error
                    transfers.removeAll { $0.id == placeholderJob.id }
                    print("❌ Failed to enumerate files: \(error)")
                }
            }
        }
    }
    
    func queueAllSources(to destination: DriveInfo, driveDetector: DriveDetector) {
        print("🎬 Queuing all sources to \(destination.name)")
        
        // Queue all manual source folders
        for source in driveDetector.manualSourceFolders {
            addTransfer(from: source, to: destination)
        }
        
        // Queue all auto-detected source cards
        for source in driveDetector.sourceCards {
            addTransfer(from: source, to: destination)
        }
        
        print("🎬 Queued to \(destination.name). Total transfers: \(transfers.count)")
    }
    
    func queueAllSourcesAllDestinations(driveDetector: DriveDetector) {
        print("🎬 Queuing ALL sources to ALL destinations - BATCH MODE!")
        
        let allSources = driveDetector.manualSourceFolders + driveDetector.sourceCards
        let allDestinations = driveDetector.manualDestinationFolders + driveDetector.destinationDrives
        
        print("🎬 Sources: \(allSources.count), Destinations: \(allDestinations.count)")
        print("🎬 Will create \(allSources.count * allDestinations.count) transfers")
        
        for source in allSources {
            for destination in allDestinations {
                addTransfer(from: source, to: destination)
            }
        }
        
        print("🎬 BATCH QUEUE COMPLETE! Total transfers: \(transfers.count)")
    }
    
    func startTransfers() {
        guard !isTransferring, let nextTransfer = transfers.first(where: { $0.status == .queued }) else {
            return
        }
        
        isTransferring = true
        processTransfer(nextTransfer)
    }
    
    private func processNextTransfer() {
        print("🎬 Looking for next transfer...")
        
        guard let nextTransfer = transfers.first(where: { $0.status == .queued }) else {
            print("🎬 No more queued transfers - ALL COMPLETE!")
            isTransferring = false
            currentTransfer = nil
            return
        }
        
        print("🎬 Found next transfer: \(nextTransfer.sourceName) → \(nextTransfer.destinationName)")
        processTransfer(nextTransfer)
    }
    
    func cancelTransfer(transferId: UUID) {
        guard let index = transfers.firstIndex(where: { $0.id == transferId }) else { return }
        
        var transfer = transfers[index]
        
        // If it's the current transfer, stop the operation
        if currentTransfer?.id == transferId {
            isTransferring = false
            currentTransfer = nil
        }
        
        // Mark as cancelled
        transfer.status = .cancelled
        updateTransfer(transfer)
        
        // Continue with next transfer if any
        if !transfers.contains(where: { $0.status == .queued }) {
            isTransferring = false
        } else if currentTransfer?.id == transferId {
            startTransfers()
        }
    }
    
    func clearCompleted() {
        transfers.removeAll { $0.status == .completed || $0.status == .cancelled }
    }
    
    func clearAllTransfers() {
        guard !isTransferring else { return }
        transfers.removeAll()
        print("🎬 All transfers cleared")
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
                    guard isTransferring, job.status != .cancelled else {
                        job.status = .cancelled
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
                    processNextTransfer()
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
                processNextTransfer()
            }
            
        default:
            isTransferring = false
        }
    }
}