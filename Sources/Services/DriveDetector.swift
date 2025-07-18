import Foundation
import Combine
import AppKit

@MainActor
class DriveDetector: ObservableObject {
    @Published var sourceCards: [DriveInfo] = []
    @Published var destinationDrives: [DriveInfo] = []
    
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
    }
}