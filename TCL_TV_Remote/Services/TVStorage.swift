//
//  TVStorage.swift
//  TCL_TV_Remote
//

import Foundation

enum TVStorage {
    private static let hostKey = "savedTVHost"
    private static let nameKey = "savedTVName"
    private static let pairedKey = "isTVPaired"

    static var savedHost: String? {
        get { UserDefaults.standard.string(forKey: hostKey) }
        set { UserDefaults.standard.set(newValue, forKey: hostKey) }
    }

    static var savedName: String? {
        get { UserDefaults.standard.string(forKey: nameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static var isPaired: Bool {
        get { UserDefaults.standard.bool(forKey: pairedKey) }
        set { UserDefaults.standard.set(newValue, forKey: pairedKey) }
    }

    static var savedDevice: TVDevice? {
        guard let host = savedHost else { return nil }
        return TVDevice(name: savedName ?? "My Google TV", host: HostAddressNormalizer.clean(host))
    }

    static func save(device: TVDevice, paired: Bool) {
        savedHost = device.host
        savedName = device.name
        isPaired = paired
    }

    static func clear() {
        savedHost = nil
        savedName = nil
        isPaired = false
    }
}
