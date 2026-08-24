import Foundation

enum ELM327Codec {

    static func payload(from raw: String) -> String {
        var text = raw
            .replacingOccurrences(of: "SEARCHING...", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "BUS INIT: OK", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "BUS INIT:ERROR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "\r", with: "\n")

        let ignored = ["OK", "ATZ", "ATE0", "ATL0", "ATS0", "ATH0", "ATSP0", "ATI"]
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { line -> String in
                var value = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
                if let colon = value.firstIndex(of: ":") {
                    let prefix = value[value.startIndex..<colon]
                    if prefix.count <= 2, prefix.allSatisfy(\.isHexDigit) {
                        value = String(value[value.index(after: colon)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                return value
            }
            .filter { line in
                guard !line.isEmpty else { return false }
                let upper = line.uppercased()
                if ignored.contains(upper) { return false }
                if upper.hasPrefix("AT") { return false }
                return true
            }

        return lines.joined(separator: " ")
    }

    static func isNoData(_ raw: String) -> Bool {
        let upper = raw.uppercased()
        return upper.contains("NO DATA")
            || upper.contains("UNABLE TO CONNECT")
            || upper.contains("CAN ERROR")
            || upper.contains("STOPPED")
            || upper.contains("?")
            || upper.contains("ERROR")
    }

    static func looksLikeAdapter(_ raw: String) -> Bool {
        let upper = raw.uppercased()
        if upper.contains("ELM") { return true }
        if upper.contains("STN") { return true }
        if upper.contains("OBD") { return true }
        if upper.contains("VEEPEAK") { return true }
        let payload = payload(from: raw)
        return !payload.isEmpty && !isNoData(raw)
    }

    static func bytes(from raw: String) -> [UInt8] {
        let payload = payload(from: raw)
        var hex = ""
        for character in payload.uppercased() {
            if character.isHexDigit {
                hex.append(character)
            }
        }

        if hex.count % 2 != 0 {
            hex = String(hex.dropLast())
        }

        var bytes: [UInt8] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            if let value = UInt8(hex[index..<next], radix: 16) {
                bytes.append(value)
            }
            index = next
        }
        return bytes
    }

    static func decodePID(_ raw: String, expectedMode: UInt8, pid: UInt8) -> [UInt8]? {
        let bytes = bytes(from: raw)
        guard let start = bytes.firstIndex(where: { $0 == expectedMode }) else {
            return nil
        }
        let slice = Array(bytes[start...])
        guard slice.count >= 2, slice[1] == pid else {
            return nil
        }
        return Array(slice.dropFirst(2))
    }

    static func rpm(from raw: String) -> Double? {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: 0x0C), data.count >= 2 else {
            return nil
        }
        return (Double(data[0]) * 256 + Double(data[1])) / 4
    }

    static func speedKmh(from raw: String) -> Double? {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: 0x0D), data.count >= 1 else {
            return nil
        }
        return Double(data[0])
    }

    static func fuelPercent(from raw: String) -> Double? {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: 0x2F), data.count >= 1 else {
            return nil
        }
        return Double(data[0]) * 100 / 255
    }

    static func coolantTempC(from raw: String) -> Double? {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: 0x05), data.count >= 1 else {
            return nil
        }
        return Double(data[0]) - 40
    }

    static func oilTempC(from raw: String) -> Double? {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: 0x5C), data.count >= 1 else {
            return nil
        }
        return Double(data[0]) - 40
    }

    static func odometerKm(from raw: String) -> Double? {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: 0xA6), data.count >= 4 else {
            return nil
        }
        let tenths = (Int(data[0]) << 24) | (Int(data[1]) << 16) | (Int(data[2]) << 8) | Int(data[3])
        return Double(tenths) / 10
    }

    static func monitorStatus(from raw: String) -> (milOn: Bool, dtcCount: Int)? {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: 0x01), data.count >= 1 else {
            return nil
        }
        let value = data[0]
        return ((value & 0x80) != 0, Int(value & 0x7F))
    }

    static func supportedPIDs(from raw: String, pid: UInt8) -> Set<UInt8> {
        guard let data = decodePID(raw, expectedMode: 0x41, pid: pid), data.count >= 4 else {
            return []
        }
        var result: Set<UInt8> = []
        let base = pid
        for byteIndex in 0..<4 {
            let byte = data[byteIndex]
            for bit in 0..<8 {
                if byte & (0x80 >> bit) != 0 {
                    result.insert(base + 1 + UInt8(byteIndex * 8 + bit))
                }
            }
        }
        return result
    }

    static func vin(from raw: String) -> String? {
        let bytes = bytes(from: raw)
        guard let start = bytes.firstIndex(of: 0x49) else {
            return nil
        }
        let ascii = bytes[(start + 1)...].filter { $0 >= 32 && $0 < 127 }
        let text = String(bytes: ascii, encoding: .ascii)?
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, text.count >= 11 else {
            return nil
        }
        let cleaned = text.filter { $0.isLetter || $0.isNumber }
        return cleaned.isEmpty ? nil : String(cleaned.suffix(17))
    }

    static func diagnosticCodes(from raw: String, status: DiagnosticFaultStatus) -> [OBDFaultReading] {
        let bytes = bytes(from: raw)
        let echo: UInt8
        switch status {
        case .stored: echo = 0x43
        case .pending: echo = 0x47
        case .permanent: echo = 0x4A
        }

        guard let start = bytes.firstIndex(of: echo) else {
            return []
        }

        var payload = Array(bytes[(start + 1)...])
        if let first = payload.first, first <= 0x28, payload.count % 2 == 1 {
            payload.removeFirst()
        }

        var readings: [OBDFaultReading] = []
        var index = 0
        while index + 1 < payload.count {
            let first = payload[index]
            let second = payload[index + 1]
            index += 2
            if first == 0 && second == 0 {
                continue
            }
            readings.append(OBDFaultReading(code: decodeDTC(first, second), status: status))
        }
        return readings
    }

    static func decodeDTC(_ first: UInt8, _ second: UInt8) -> String {
        let letters = ["P", "C", "B", "U"]
        let letter = letters[Int((first & 0xC0) >> 6)]
        let d1 = (first & 0x30) >> 4
        let d2 = first & 0x0F
        let d3 = (second & 0xF0) >> 4
        let d4 = second & 0x0F
        return String(format: "%@%X%X%X%X", letter, d1, d2, d3, d4)
    }
}
