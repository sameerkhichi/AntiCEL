import Foundation

enum AnticelArchive {
    static let manifestPath = "manifest.json"
    static let vehiclePath = "vehicle.json"
    static let photosFolder = "photos/"

    struct PhotoSource: Sendable {
        var archivePath: String
        var fileURL: URL
    }

    static func write(
        manifestJSON: Data,
        vehicleJSON: Data,
        photos: [PhotoSource],
        to url: URL
    ) throws {
        let staging = url.appendingPathExtension("tmp")
        let manager = FileManager.default

        if manager.fileExists(atPath: staging.path) {
            try manager.removeItem(at: staging)
        }
        if manager.fileExists(atPath: url.path) {
            try manager.removeItem(at: url)
        }

        manager.createFile(atPath: staging.path, contents: nil)
        guard manager.fileExists(atPath: staging.path) else {
            throw VehicleShareError.writeFailed
        }

        let handle = try FileHandle(forWritingTo: staging)
        do {
            var writer = ZipStoreWriter(handle: handle)
            try writer.addFile(path: manifestPath, data: manifestJSON)
            try writer.addFile(path: vehiclePath, data: vehicleJSON)

            for photo in photos {
                let data = try Data(contentsOf: photo.fileURL)
                try writer.addFile(path: photo.archivePath, data: data)
            }

            try writer.finish()
            handle.synchronizeFile()
            try handle.close()
            try manager.moveItem(at: staging, to: url)
        } catch {
            try? handle.close()
            try? manager.removeItem(at: staging)
            throw error
        }
    }

    static func readFiles(_ names: Set<String>, from url: URL) throws -> [String: Data] {
        try ZipStoreReader.files(named: names, in: url)
    }

    static func readAll(from url: URL) throws -> [String: Data] {
        try ZipStoreReader.allFiles(in: url)
    }
}

private struct ZipStoreWriter {
    private let handle: FileHandle
    private var offset: UInt32 = 0
    private var centrals: [CentralRecord] = []
    private let dos = ZipStoreWriter.msdosDateTime(from: Date())

    init(handle: FileHandle) {
        self.handle = handle
    }

    mutating func addFile(path: String, data: Data) throws {
        let name = Array(path.utf8)
        guard name.count <= Int(UInt16.max) else {
            throw VehicleShareError.writeFailed
        }

        let crc = CRC32.hash(data)
        let size = UInt32(data.count)
        let localOffset = offset

        var header = Data()
        header.appendUInt32(0x04034b50)
        header.appendUInt16(20)
        header.appendUInt16(0x0800)
        header.appendUInt16(0)
        header.appendUInt16(dos.time)
        header.appendUInt16(dos.date)
        header.appendUInt32(crc)
        header.appendUInt32(size)
        header.appendUInt32(size)
        header.appendUInt16(UInt16(name.count))
        header.appendUInt16(0)
        header.append(contentsOf: name)

        try handle.write(contentsOf: header)
        try handle.write(contentsOf: data)

        offset += UInt32(header.count + data.count)
        centrals.append(
            CentralRecord(
                name: name,
                crc: crc,
                size: size,
                localOffset: localOffset
            )
        )
    }

    func finish() throws {
        let centralStart = offset
        var centralSize: UInt32 = 0

        for record in centrals {
            var header = Data()
            header.appendUInt32(0x02014b50)
            header.appendUInt16(0x031E)
            header.appendUInt16(20)
            header.appendUInt16(0x0800)
            header.appendUInt16(0)
            header.appendUInt16(dos.time)
            header.appendUInt16(dos.date)
            header.appendUInt32(record.crc)
            header.appendUInt32(record.size)
            header.appendUInt32(record.size)
            header.appendUInt16(UInt16(record.name.count))
            header.appendUInt16(0)
            header.appendUInt16(0)
            header.appendUInt16(0)
            header.appendUInt16(0)
            header.appendUInt32(0)
            header.appendUInt32(record.localOffset)
            header.append(contentsOf: record.name)

            try handle.write(contentsOf: header)
            centralSize += UInt32(header.count)
        }

        var eocd = Data()
        eocd.appendUInt32(0x06054b50)
        eocd.appendUInt16(0)
        eocd.appendUInt16(0)
        eocd.appendUInt16(UInt16(centrals.count))
        eocd.appendUInt16(UInt16(centrals.count))
        eocd.appendUInt32(centralSize)
        eocd.appendUInt32(centralStart)
        eocd.appendUInt16(0)
        try handle.write(contentsOf: eocd)
    }

    private struct CentralRecord {
        var name: [UInt8]
        var crc: UInt32
        var size: UInt32
        var localOffset: UInt32
    }

    private static func msdosDateTime(from date: Date) -> (time: UInt16, date: UInt16) {
        let components = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone.current,
            from: date
        )
        let year = UInt16(max(components.year ?? 1980, 1980))
        let month = UInt16(components.month ?? 1)
        let day = UInt16(components.day ?? 1)
        let hour = UInt16(components.hour ?? 0)
        let minute = UInt16(components.minute ?? 0)
        let second = UInt16(components.second ?? 0)
        let dosDate = ((year - 1980) << 9) | (month << 5) | day
        let dosTime = (hour << 11) | (minute << 5) | (second / 2)
        return (dosTime, dosDate)
    }
}

private enum ZipStoreReader {
    static func allFiles(in url: URL) throws -> [String: Data] {
        try files(named: nil, in: url)
    }

    static func files(named names: Set<String>?, in url: URL) throws -> [String: Data] {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let entries = try index(in: data)
        var result: [String: Data] = [:]

        for entry in entries {
            if let names, !names.contains(entry.name) {
                continue
            }
            guard entry.method == 0 else {
                throw VehicleShareError.unsupportedCompression
            }
            let end = entry.dataOffset + Int(entry.size)
            guard entry.dataOffset >= 0, end <= data.count else {
                throw VehicleShareError.invalidPackage
            }
            result[entry.name] = data.subdata(in: entry.dataOffset..<end)
        }

        return result
    }

    private struct Entry {
        var name: String
        var method: UInt16
        var size: UInt32
        var dataOffset: Int
    }

    private static func index(in data: Data) throws -> [Entry] {
        let eocd = try endOfCentralDirectory(in: data)
        let count = Int(data.u16(eocd + 10))
        let centralSize = Int(data.u32(eocd + 12))
        let centralOffset = Int(data.u32(eocd + 16))
        let centralEnd = centralOffset + centralSize

        guard centralOffset >= 0, centralEnd <= data.count, count >= 0 else {
            throw VehicleShareError.invalidPackage
        }

        var offset = centralOffset
        var entries: [Entry] = []
        entries.reserveCapacity(count)

        for _ in 0..<count {
            guard offset + 46 <= data.count, data.u32(offset) == 0x02014b50 else {
                throw VehicleShareError.invalidPackage
            }

            let flags = data.u16(offset + 8)
            if flags & 0x0008 != 0 {
                throw VehicleShareError.unsupportedCompression
            }

            let method = data.u16(offset + 10)
            let size = data.u32(offset + 20)
            let nameLength = Int(data.u16(offset + 28))
            let extraLength = Int(data.u16(offset + 30))
            let commentLength = Int(data.u16(offset + 32))
            let localOffset = Int(data.u32(offset + 42))
            let nameStart = offset + 46
            let nameEnd = nameStart + nameLength

            guard nameEnd <= data.count else {
                throw VehicleShareError.invalidPackage
            }

            let rawName = String(data: data.subdata(in: nameStart..<nameEnd), encoding: .utf8) ?? ""
            guard let name = sanitizedPath(rawName) else {
                throw VehicleShareError.invalidPackage
            }

            let dataOffset = try localDataOffset(
                in: data,
                localHeaderOffset: localOffset
            )

            entries.append(Entry(name: name, method: method, size: size, dataOffset: dataOffset))
            offset = nameEnd + extraLength + commentLength
        }

        return entries
    }

    private static func localDataOffset(in data: Data, localHeaderOffset: Int) throws -> Int {
        guard localHeaderOffset + 30 <= data.count, data.u32(localHeaderOffset) == 0x04034b50 else {
            throw VehicleShareError.invalidPackage
        }
        let nameLength = Int(data.u16(localHeaderOffset + 26))
        let extraLength = Int(data.u16(localHeaderOffset + 28))
        let start = localHeaderOffset + 30 + nameLength + extraLength
        guard start <= data.count else {
            throw VehicleShareError.invalidPackage
        }
        return start
    }

    private static func endOfCentralDirectory(in data: Data) throws -> Int {
        let minLength = 22
        guard data.count >= minLength else {
            throw VehicleShareError.invalidPackage
        }

        let maxComment = 65535
        let start = max(0, data.count - minLength - maxComment)
        var index = data.count - minLength

        while index >= start {
            if data.u32(index) == 0x06054b50 {
                return index
            }
            index -= 1
        }

        throw VehicleShareError.invalidPackage
    }

    private static func sanitizedPath(_ name: String) -> String? {
        let trimmed = name.replacingOccurrences(of: "\\", with: "/")
        guard !trimmed.isEmpty, !trimmed.hasPrefix("/"), !trimmed.contains("..") else {
            return nil
        }
        return trimmed
    }
}

private enum CRC32 {
    static func hash(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        return crc ^ 0xFFFFFFFF
    }

    private static let table: [UInt32] = {
        (0..<256).map { i in
            var crc = UInt32(i)
            for _ in 0..<8 {
                if crc & 1 != 0 {
                    crc = 0xEDB88320 ^ (crc >> 1)
                } else {
                    crc >>= 1
                }
            }
            return crc
        }
    }()
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { append(contentsOf: $0) }
    }

    mutating func appendUInt32(_ value: UInt32) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { append(contentsOf: $0) }
    }

    func u16(_ offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func u32(_ offset: Int) -> UInt32 {
        UInt32(self[offset])
            | UInt32(self[offset + 1]) << 8
            | UInt32(self[offset + 2]) << 16
            | UInt32(self[offset + 3]) << 24
    }
}
