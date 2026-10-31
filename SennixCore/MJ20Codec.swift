import Foundation

enum MJ20Codec {
    static let downSOF: UInt8 = 0xA5
    static let upSOF: UInt8 = 0xB5
    static let eof: UInt8 = 0x5E
    static let device: UInt8 = 0x01

    static func build(command: UInt8, payload: [UInt8] = []) -> Data {
        var bytes = [downSOF, downSOF, device, command, UInt8(payload.count)] + payload
        bytes.append(checksum(Array(bytes.dropFirst(2))))
        bytes.append(eof)
        return Data(bytes)
    }

    static func checksum(_ bytes: [UInt8]) -> UInt8 {
        bytes.reduce(0) { UInt8((UInt16($0) + UInt16($1)) & 0xFF) }
    }

    static func parse(_ data: Data) -> (command: UInt8, payload: [UInt8])? {
        let b = [UInt8](data)
        guard b.count >= 7, b[0] == upSOF, b[1] == upSOF, b.last == eof else { return nil }
        let count = Int(b[4])
        guard b.count == 7 + count else { return nil }
        let expected = b[b.count - 2]
        let standard = checksum(Array(b[2..<(5 + count)]))
        let legacy = checksum(Array(b[2..<(4 + count)]))
        guard expected == standard || expected == legacy else { return nil }
        return (b[3], count == 0 ? [] : Array(b[5..<(5 + count)]))
    }

    static func hex(_ data: Data) -> String { data.map { String(format: "%02X", $0) }.joined(separator: " ") }
}

