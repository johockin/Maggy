import Foundation
import CryptoKit
// import xxHash_Swift  // Will be available after adding SPM dependency

class ChecksumManager {
    enum Algorithm {
        case sha256
        case xxHash
    }
    
    func calculateChecksum(for url: URL, algorithm: Algorithm = .sha256) async throws -> String {
        return try await Task.detached {
            let bufferSize = 1024 * 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            
            guard let inputStream = InputStream(url: url) else {
                throw CocoaError(.fileReadUnknown)
            }
            
            inputStream.open()
            defer { inputStream.close() }
            
            switch algorithm {
            case .sha256:
                var hasher = SHA256()
                
                while inputStream.hasBytesAvailable {
                    let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                    
                    if bytesRead < 0 {
                        throw inputStream.streamError ?? CocoaError(.fileReadUnknown)
                    } else if bytesRead == 0 {
                        break
                    }
                    
                    let dataChunk = Data(bytes: buffer, count: bytesRead)
                    hasher.update(data: dataChunk)
                }
                
                let digest = hasher.finalize()
                return digest.map { String(format: "%02x", $0) }.joined()
                
            case .xxHash:
                // For now, use a fast native implementation as placeholder
                // This will be replaced with real xxHash once SPM dependency is added
                var hasher = Hasher()
                
                while inputStream.hasBytesAvailable {
                    let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                    
                    if bytesRead < 0 {
                        throw inputStream.streamError ?? CocoaError(.fileReadUnknown)
                    } else if bytesRead == 0 {
                        break
                    }
                    
                    let dataChunk = Data(bytes: buffer, count: bytesRead)
                    dataChunk.withUnsafeBytes { buffer in
                        hasher.combine(bytes: buffer)
                    }
                }
                
                let hashValue = hasher.finalize()
                return String(format: "%016x", UInt64(bitPattern: Int64(hashValue)))
            }
        }.value
    }
    
    func verifyChecksum(for url: URL, expectedChecksum: String, algorithm: Algorithm = .sha256) async throws -> Bool {
        let actualChecksum = try await calculateChecksum(for: url, algorithm: algorithm)
        return actualChecksum == expectedChecksum
    }
}