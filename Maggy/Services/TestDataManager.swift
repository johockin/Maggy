import Foundation

class TestDataManager {
    private let testDataPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/MaggyTestData")
    private let testDestinationPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/MaggyDestination")
    
    func createTestData() async {
        let fileManager = FileManager.default
        
        do {
            try fileManager.createDirectory(at: testDataPath, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: testDestinationPath, withIntermediateDirectories: true)
            
            try await createFX6Card()
            try await createA7SCard()
            
        } catch {
            print("Failed to create test data: \(error)")
        }
    }
    
    private func createFX6Card() async throws {
        let cardPath = testDataPath.appendingPathComponent("FakeSDCard_FX6")
        let fileManager = FileManager.default
        
        let clipPath = cardPath.appendingPathComponent("PRIVATE/M4ROOT/CLIP")
        let thumbnailPath = cardPath.appendingPathComponent("PRIVATE/M4ROOT/THMBNL")
        
        try fileManager.createDirectory(at: clipPath, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnailPath, withIntermediateDirectories: true)
        
        try createDummyFile(at: clipPath.appendingPathComponent("C0001.MP4"), size: 50 * 1024 * 1024)
        try createDummyFile(at: clipPath.appendingPathComponent("C0002.MP4"), size: 100 * 1024 * 1024)
        try createDummyFile(at: clipPath.appendingPathComponent("C0003.MP4"), size: 25 * 1024 * 1024)
        
        try createDummyFile(at: thumbnailPath.appendingPathComponent("C0001.JPG"), size: 100 * 1024)
        try createDummyFile(at: thumbnailPath.appendingPathComponent("C0002.JPG"), size: 100 * 1024)
        try createDummyFile(at: thumbnailPath.appendingPathComponent("C0003.JPG"), size: 100 * 1024)
    }
    
    private func createA7SCard() async throws {
        let cardPath = testDataPath.appendingPathComponent("FakeSDCard_A7S")
        let fileManager = FileManager.default
        
        let dcimPath1 = cardPath.appendingPathComponent("DCIM/100MSDCF")
        let dcimPath2 = cardPath.appendingPathComponent("DCIM/101MSDCF")
        
        try fileManager.createDirectory(at: dcimPath1, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: dcimPath2, withIntermediateDirectories: true)
        
        try createDummyFile(at: dcimPath1.appendingPathComponent("DSC_0001.JPG"), size: 5 * 1024 * 1024)
        try createDummyFile(at: dcimPath1.appendingPathComponent("DSC_0002.JPG"), size: 5 * 1024 * 1024)
        try createDummyFile(at: dcimPath2.appendingPathComponent("DSC_0003.JPG"), size: 5 * 1024 * 1024)
    }
    
    private func createDummyFile(at url: URL, size: Int) throws {
        let data = Data(repeating: 0, count: size)
        try data.write(to: url)
    }
    
    func getTestDrives() -> [DriveInfo] {
        var drives: [DriveInfo] = []
        
        let fx6Card = DriveInfo(
            name: "FX6_Card",
            path: testDataPath.appendingPathComponent("FakeSDCard_FX6"),
            totalSpace: 128 * 1024 * 1024 * 1024,
            freeSpace: 50 * 1024 * 1024 * 1024,
            isRemovable: true,
            cameraType: .fx6,
            mountPoint: testDataPath.appendingPathComponent("FakeSDCard_FX6").path
        )
        
        let a7sCard = DriveInfo(
            name: "A7S_Card",
            path: testDataPath.appendingPathComponent("FakeSDCard_A7S"),
            totalSpace: 64 * 1024 * 1024 * 1024,
            freeSpace: 30 * 1024 * 1024 * 1024,
            isRemovable: true,
            cameraType: .a7s,
            mountPoint: testDataPath.appendingPathComponent("FakeSDCard_A7S").path
        )
        
        let raidDrive = DriveInfo(
            name: "RAID Drive",
            path: testDestinationPath.appendingPathComponent("RAID"),
            totalSpace: 2 * 1024 * 1024 * 1024 * 1024,
            freeSpace: 1 * 1024 * 1024 * 1024 * 1024,
            isRemovable: false,
            cameraType: nil,
            mountPoint: testDestinationPath.appendingPathComponent("RAID").path
        )
        
        let archiveDrive = DriveInfo(
            name: "Archive Drive",
            path: testDestinationPath.appendingPathComponent("Archive"),
            totalSpace: 8 * 1024 * 1024 * 1024 * 1024,
            freeSpace: 6 * 1024 * 1024 * 1024 * 1024,
            isRemovable: false,
            cameraType: nil,
            mountPoint: testDestinationPath.appendingPathComponent("Archive").path
        )
        
        drives.append(fx6Card)
        drives.append(a7sCard)
        drives.append(raidDrive)
        drives.append(archiveDrive)
        
        return drives
    }
}