import Foundation
import CryptoKit

struct FileInfo {
    let path: URL
    let size: Int64
    let relativePath: String
}

class FileOperations {
    private let checksumManager = ChecksumManager()
    
    func enumerateFiles(at path: URL) async throws -> [FileInfo] {
        return try await Task.detached {
            var files: [FileInfo] = []
            let fileManager = FileManager.default
            
            guard let enumerator = fileManager.enumerator(
                at: path,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                throw CocoaError(.fileReadUnknown)
            }
            
            while let url = enumerator.nextObject() as? URL {
                do {
                    let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                    
                    if values.isRegularFile ?? false,
                       let size = values.fileSize {
                        let relativePath = url.path.replacingOccurrences(of: path.path + "/", with: "")
                        files.append(FileInfo(path: url, size: Int64(size), relativePath: relativePath))
                    }
                } catch {
                    print("Error reading file info: \(error)")
                }
            }
            
            return files
        }.value
    }
    
    func copyFile(from source: URL, to destination: URL, algorithm: ChecksumManager.Algorithm = .sha256, progress: @escaping (Int) -> Void) async throws -> String {
        return try await Task.detached {
            let bufferSize = 1024 * 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            
            guard let inputStream = InputStream(url: source),
                  let outputStream = OutputStream(url: destination, append: false) else {
                throw CocoaError(.fileReadUnknown)
            }
            
            inputStream.open()
            outputStream.open()
            
            defer {
                inputStream.close()
                outputStream.close()
            }
            
            // Initialize appropriate hasher based on algorithm
            var sha256Hasher: SHA256?
            var swiftHasher: Hasher?
            
            switch algorithm {
            case .sha256:
                sha256Hasher = SHA256()
            case .xxHash:
                swiftHasher = Hasher()
            }
            
            var totalBytesWritten = 0
            
            while inputStream.hasBytesAvailable {
                let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                
                if bytesRead < 0 {
                    throw inputStream.streamError ?? CocoaError(.fileReadUnknown)
                } else if bytesRead == 0 {
                    break
                }
                
                let dataChunk = Data(bytes: buffer, count: bytesRead)
                
                // Update appropriate hasher
                switch algorithm {
                case .sha256:
                    sha256Hasher?.update(data: dataChunk)
                case .xxHash:
                    dataChunk.withUnsafeBytes { buffer in
                        swiftHasher?.combine(bytes: buffer)
                    }
                }
                
                let bytesWritten = outputStream.write(buffer, maxLength: bytesRead)
                
                if bytesWritten < 0 {
                    throw outputStream.streamError ?? CocoaError(.fileWriteUnknown)
                }
                
                totalBytesWritten += bytesWritten
                
                await MainActor.run {
                    progress(bytesWritten)
                }
            }
            
            // Generate final hash based on algorithm
            switch algorithm {
            case .sha256:
                let digest = sha256Hasher!.finalize()
                return digest.map { String(format: "%02x", $0) }.joined()
            case .xxHash:
                let hashValue = swiftHasher!.finalize()
                return String(format: "%016x", UInt64(bitPattern: Int64(hashValue)))
            }
            
        }.value
    }
}