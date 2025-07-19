import Foundation
import Combine
import AppKit

@MainActor
class TransferEngine: ObservableObject {
    @Published var transfers: [TransferJob] = []
    @Published var currentTransfer: TransferJob?
    @Published var isTransferring = false
    @Published var queueFeedbackMessage: String?
    
    private var fileOperations: FileOperations
    private var checksumManager: ChecksumManager
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.fileOperations = FileOperations()
        self.checksumManager = ChecksumManager()
    }
    
    func addTransfer(from source: DriveInfo, to destination: DriveInfo) {
        print("🎬 Adding transfer from \(source.name) to \(destination.name)")
        
        // Create safe timestamp format without slashes
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let destinationPath = destination.path.appendingPathComponent("\(source.name)_MAG_\(timestamp)")
        
        // Check if transfer already exists to prevent duplicates
        let isDuplicate = transfers.contains { transfer in
            transfer.sourcePath == source.path && 
            transfer.destinationPath.deletingLastPathComponent() == destination.path
        }
        
        if isDuplicate {
            print("⚠️ Duplicate transfer detected - adding anyway: \(source.name) → \(destination.name)")
            queueFeedbackMessage = "Added \(source.name) → \(destination.name) (duplicate)"
            
            // Clear message after delay
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                await MainActor.run {
                    if queueFeedbackMessage?.contains("duplicate") == true {
                        queueFeedbackMessage = nil
                    }
                }
            }
        } else {
            queueFeedbackMessage = "Added \(source.name) → \(destination.name)"
            
            // Clear message after delay
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    if queueFeedbackMessage?.contains("Added") == true {
                        queueFeedbackMessage = nil
                    }
                }
            }
        }
        
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
        print("🎬 ===== STARTING BATCH QUEUE =====")
        
        let allSources = driveDetector.manualSourceFolders.filter { !$0.isDisabled } + driveDetector.sourceCards
        let allDestinations = driveDetector.manualDestinationFolders + driveDetector.destinationDrives
        
        print("🎬 Manual Source Folders: \(driveDetector.manualSourceFolders.count)")
        for (i, source) in driveDetector.manualSourceFolders.enumerated() {
            print("🎬   [\(i)] \(source.name) at \(source.path.path)")
        }
        
        print("🎬 Source Cards: \(driveDetector.sourceCards.count)")
        for (i, source) in driveDetector.sourceCards.enumerated() {
            print("🎬   [\(i)] \(source.name) at \(source.path.path)")
        }
        
        print("🎬 Manual Destination Folders: \(driveDetector.manualDestinationFolders.count)")
        for (i, dest) in driveDetector.manualDestinationFolders.enumerated() {
            print("🎬   [\(i)] \(dest.name) at \(dest.path.path)")
        }
        
        print("🎬 Destination Drives: \(driveDetector.destinationDrives.count)")
        for (i, dest) in driveDetector.destinationDrives.enumerated() {
            print("🎬   [\(i)] \(dest.name) at \(dest.path.path)")
        }
        
        print("🎬 Total Sources: \(allSources.count), Total Destinations: \(allDestinations.count)")
        print("🎬 Expected transfers: \(allSources.count * allDestinations.count)")
        
        var transferCount = 0
        for (sourceIndex, source) in allSources.enumerated() {
            for (destIndex, destination) in allDestinations.enumerated() {
                transferCount += 1
                print("🎬 Creating transfer #\(transferCount): Source[\(sourceIndex)] \(source.name) → Dest[\(destIndex)] \(destination.name)")
                addTransfer(from: source, to: destination)
            }
        }
        
        print("🎬 ===== BATCH QUEUE COMPLETE! =====")
        print("🎬 Created \(transferCount) transfer calls, actual transfers in queue: \(transfers.count)")
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
        Task { @MainActor in
            var job = transfer
            job.status = .preparing
            updateTransfer(job)
            currentTransfer = job
            
            do {
                // Check if destination already exists BEFORE starting transfer
                print("🎬 Checking if destination exists: \(job.destinationPath.path)")
                
                if FileManager.default.fileExists(atPath: job.destinationPath.path) {
                    print("⚠️ CONFLICT DETECTED: Destination already exists")
                    let resolution = await handleExistingDestination(job: job)
                    
                    switch resolution {
                    case .replace:
                        print("🎬 User chose REPLACE - removing existing folder")
                        try FileManager.default.removeItem(at: job.destinationPath)
                        try FileManager.default.createDirectory(at: job.destinationPath, withIntermediateDirectories: true)
                    case .keepBoth(let newPath):
                        print("🎬 User chose KEEP BOTH - using new path: \(newPath.path)")
                        job.destinationPath = newPath
                        updateTransfer(job)
                        try FileManager.default.createDirectory(at: job.destinationPath, withIntermediateDirectories: true)
                    case .skip:
                        print("🎬 User chose SKIP - cancelling transfer")
                        job.status = .cancelled
                        updateTransfer(job)
                        currentTransfer = nil
                        if isTransferring {
                            processNextTransfer()
                        }
                        return
                    }
                } else {
                    print("🎬 Destination clear - creating directory")
                    try FileManager.default.createDirectory(at: job.destinationPath, withIntermediateDirectories: true)
                }
                
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
                
                // Small delay to ensure UI updates to show verification phase
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms
                
                // Actually verify checksums by comparing source and destination
                var allChecksumsValid = true
                var verificationError: String?
                
                for (_, file) in job.files.enumerated() {
                    guard let originalChecksum = file.checksum else {
                        allChecksumsValid = false
                        verificationError = "Missing checksum for \(file.sourcePath.lastPathComponent)"
                        break
                    }
                    
                    // Verify the copied file has the same checksum
                    do {
                        let verificationChecksum = try await checksumManager.calculateChecksum(for: file.destinationPath)
                        if originalChecksum != verificationChecksum {
                            allChecksumsValid = false
                            verificationError = "Checksum mismatch for \(file.sourcePath.lastPathComponent)"
                            break
                        }
                        print("🎬 ✓ Verified: \(file.sourcePath.lastPathComponent) - SHA-256: \(originalChecksum)")
                    } catch {
                        allChecksumsValid = false
                        verificationError = "Could not verify \(file.sourcePath.lastPathComponent): \(error.localizedDescription)"
                        break
                    }
                }
                
                if allChecksumsValid {
                    job.status = .completed
                    print("🎬 ✅ All files verified with SHA-256 checksums")
                } else {
                    job.status = .failed
                    job.error = .ioError(verificationError ?? "Checksum verification failed")
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
    
    enum ConflictResolution {
        case replace
        case keepBoth(newPath: URL)
        case skip
    }
    
    private func handleExistingDestination(job: TransferJob) async -> ConflictResolution {
        return await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "Folder Already Exists"
            alert.informativeText = "A folder named '\(job.destinationPath.lastPathComponent)' already exists at this location."
            alert.alertStyle = .warning
            
            // Add buttons
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Keep Both")
            alert.addButton(withTitle: "Skip")
            
            // Add accessory view with "Show in Finder" button
            let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
            let showInFinderButton = NSButton(frame: NSRect(x: 0, y: 0, width: 120, height: 30))
            showInFinderButton.title = "Show in Finder"
            showInFinderButton.bezelStyle = .rounded
            showInFinderButton.target = self
            showInFinderButton.action = #selector(showInFinder(_:))
            showInFinderButton.tag = 0 // We'll use representedObject instead
            accessoryView.addSubview(showInFinderButton)
            alert.accessoryView = accessoryView
            
            // Store the path for the button
            conflictPath = job.destinationPath
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn: // Replace
                return .replace
                
            case .alertSecondButtonReturn: // Keep Both
                // Generate new name with number suffix
                let newPath = generateUniqueDestinationPath(basePath: job.destinationPath)
                return .keepBoth(newPath: newPath)
                
            default: // Skip
                return .skip
            }
        }
    }
    
    private var conflictPath: URL?
    
    @objc private func showInFinder(_ sender: NSButton) {
        guard let path = conflictPath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([path])
    }
    
    private func generateUniqueDestinationPath(basePath: URL) -> URL {
        let parentDirectory = basePath.deletingLastPathComponent()
        let baseName = basePath.lastPathComponent
        var counter = 2
        var newPath = parentDirectory.appendingPathComponent("\(baseName)_\(counter)")
        
        while FileManager.default.fileExists(atPath: newPath.path) {
            counter += 1
            newPath = parentDirectory.appendingPathComponent("\(baseName)_\(counter)")
        }
        
        return newPath
    }
}