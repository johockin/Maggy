import Foundation
import Combine
import AppKit

@MainActor
class DriveDetector: ObservableObject {
    @Published var sourceCards: [DriveInfo] = []
    @Published var destinationDrives: [DriveInfo] = []
    @Published var manualSourceFolders: [DriveInfo] = []
    @Published var manualDestinationFolders: [DriveInfo] = []
    @Published var autoDetectedDrives: [DriveInfo] = []
    
    private var workspace = NSWorkspace.shared
    private var cancellables = Set<AnyCancellable>()
    private let testDataManager = TestDataManager()
    
    func startMonitoring() {
        scanDrives()
        
        NotificationCenter.default.publisher(for: NSWorkspace.didMountNotification)
            .sink { _ in self.scanDrives() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSWorkspace.didUnmountNotification)
            .sink { _ in self.scanDrives() }
            .store(in: &cancellables)
    }
    
    func loadTestData() {
        Task {
            await testDataManager.createTestData()
            let testDrives = testDataManager.getTestDrives()
            
            sourceCards = testDrives.filter { $0.isRemovable }
            destinationDrives = testDrives.filter { !$0.isRemovable }
        }
    }
    
    private func scanDrives() {
        let fileManager = FileManager.default
        let volumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey
        ], options: [.skipHiddenVolumes]) ?? []
        
        var sources: [DriveInfo] = []
        var destinations: [DriveInfo] = []
        
        for volume in volumes {
            do {
                let values = try volume.resourceValues(forKeys: [
                    .volumeNameKey,
                    .volumeTotalCapacityKey,
                    .volumeAvailableCapacityKey,
                    .volumeIsRemovableKey
                ])
                
                guard let name = values.volumeName,
                      let totalSpace = values.volumeTotalCapacity,
                      let freeSpace = values.volumeAvailableCapacity else {
                    continue
                }
                
                let isRemovable = values.volumeIsRemovable ?? false
                let cameraType = CameraType.detect(from: volume)
                
                let drive = DriveInfo(
                    name: name,
                    path: volume,
                    totalSpace: Int64(totalSpace),
                    freeSpace: Int64(freeSpace),
                    isRemovable: isRemovable,
                    cameraType: cameraType,
                    mountPoint: volume.path
                )
                
                if isRemovable && totalSpace < 500_000_000_000 {
                    sources.append(drive)
                } else if !isRemovable || totalSpace > 500_000_000_000 {
                    destinations.append(drive)
                }
                
            } catch {
                print("Error reading volume info: \(error)")
            }
        }
        
        sourceCards = sources
        destinationDrives = destinations
        autoDetectedDrives = sources + destinations
    }
    
    func addSourceFolder(_ url: URL) {
        let folderInfo = DriveInfo(
            name: url.lastPathComponent,
            path: url,
            totalSpace: getFolderSize(url),
            freeSpace: getAvailableSpace(url),
            isRemovable: false,
            cameraType: nil,
            mountPoint: url.path
        )
        manualSourceFolders.append(folderInfo)
    }
    
    func addDestinationFolder(_ url: URL) {
        let folderInfo = DriveInfo(
            name: url.lastPathComponent,
            path: url,
            totalSpace: getFolderSize(url),
            freeSpace: getAvailableSpace(url),
            isRemovable: false,
            cameraType: nil,
            mountPoint: url.path
        )
        manualDestinationFolders.append(folderInfo)
    }
    
    func removeSourceFolder(at index: Int) {
        guard index < manualSourceFolders.count else { return }
        manualSourceFolders.remove(at: index)
    }
    
    func removeDestinationFolder(at index: Int) {
        guard index < manualDestinationFolders.count else { return }
        manualDestinationFolders.remove(at: index)
    }
    
    private func getFolderSize(_ url: URL) -> Int64 {
        do {
            let values = try url.resourceValues(forKeys: [.totalFileSizeKey])
            return Int64(values.totalFileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    private func getAvailableSpace(_ url: URL) -> Int64 {
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return Int64(values.volumeAvailableCapacity ?? 0)
        } catch {
            return 0
        }
    }
}