//
//  HostAddressNormalizer.swift
//  TCL_TV_Remote
//

import Foundation
import Network

enum HostAddressNormalizer {
    /// Strips zone identifiers (e.g. `%en0`) and whitespace from a host string.
    static func clean(_ host: String) -> String {
        var value = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if let zoneIndex = value.firstIndex(of: "%") {
            value = String(value[..<zoneIndex])
        }
        return value
    }

    /// Formats an IPv4 address without interface scope suffixes.
    static func ipv4String(from address: IPv4Address) -> String {
        let bytes = [UInt8](address.rawValue)
        guard bytes.count == 4 else {
            return clean("\(address)")
        }
        return bytes.map(String.init).joined(separator: ".")
    }
}
