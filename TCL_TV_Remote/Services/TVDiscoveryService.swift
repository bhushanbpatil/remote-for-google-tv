//
//  TVDiscoveryService.swift
//  TCL_TV_Remote
//

import Foundation
import Network

@MainActor
@Observable
final class TVDiscoveryService {
    private(set) var devices: [TVDevice] = []
    private(set) var isSearching = false
    private(set) var statusMessage = "Search for your Google TV on the local network."

    private var worker: BonjourDiscoveryWorker?
    private var seenDeviceIDs: Set<String> = []

    func startDiscovery() {
        stopDiscovery()
        isSearching = true
        seenDeviceIDs.removeAll()
        devices.removeAll()
        statusMessage = "Searching for Google TV devices…"

        let worker = BonjourDiscoveryWorker()
        worker.onDeviceFound = { [weak self] name, host in
            Task { @MainActor in
                self?.addDevice(name: name, host: host)
            }
        }
        worker.onStatusUpdate = { [weak self] message in
            Task { @MainActor in
                self?.statusMessage = message
            }
        }
        worker.onSearchFinished = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.isSearching = false
                if self.devices.isEmpty {
                    self.statusMessage = """
                    No TVs found automatically. Use Manual IP below \
                    (Settings → Network on your TV). Make sure Local Network access is allowed for this app in iPhone Settings.
                    """
                }
            }
        }
        self.worker = worker
        worker.start()
    }

    func stopDiscovery() {
        worker?.stop()
        worker = nil
        isSearching = false
    }

    private func addDevice(name: String, host: String) {
        let normalizedHost = HostAddressNormalizer.clean(host)
        guard !normalizedHost.isEmpty else { return }

        let displayName = name.replacingOccurrences(of: "._androidtvremote2._tcp.local.", with: "")
            .replacingOccurrences(of: "._androidtvremote._tcp.local.", with: "")

        let device = TVDevice(name: displayName, host: normalizedHost)
        guard !seenDeviceIDs.contains(device.id) else { return }

        seenDeviceIDs.insert(device.id)
        devices.append(device)
        statusMessage = "Found \(devices.count) device(s)."
        isSearching = false
    }
}

// MARK: - Bonjour worker

private final class BonjourDiscoveryWorker: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    var onDeviceFound: ((String, String) -> Void)?
    var onStatusUpdate: ((String) -> Void)?
    var onSearchFinished: (() -> Void)?

    private let browsers: [NetServiceBrowser] = [NetServiceBrowser(), NetServiceBrowser()]
    private var activeSearches = 0
    private var pendingServices: [NetService] = []
    private var finishTimer: Timer?

    private let serviceTypes = [
        "_androidtvremote2._tcp.",
        "_androidtvremote._tcp."
    ]

    func start() {
        activeSearches = serviceTypes.count

        for (index, serviceType) in serviceTypes.enumerated() {
            let browser = browsers[index]
            browser.delegate = self
            browser.searchForServices(ofType: serviceType, inDomain: "local.")
        }

        finishTimer?.invalidate()
        finishTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: false) { [weak self] _ in
            self?.finishSearching()
        }
    }

    func stop() {
        finishTimer?.invalidate()
        finishTimer = nil
        browsers.forEach { $0.stop() }
        pendingServices.forEach { $0.stop() }
        pendingServices.removeAll()
        activeSearches = 0
    }

    private func finishSearching() {
        guard activeSearches > 0 else { return }
        activeSearches = 0
        browsers.forEach { $0.stop() }
        onSearchFinished?()
    }

    private func markSearchEnded(for browser: NetServiceBrowser) {
        guard activeSearches > 0 else { return }
        activeSearches -= 1
        if activeSearches == 0 {
            finishTimer?.invalidate()
            finishTimer = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.onSearchFinished?()
            }
        }
    }

    // MARK: NetServiceBrowserDelegate

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        pendingServices.append(service)
        service.resolve(withTimeout: 10)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch error: Error) {
        onStatusUpdate?("Discovery error: \(error.localizedDescription)")
        markSearchEnded(for: browser)
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        markSearchEnded(for: browser)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        // No-op
    }

    // MARK: NetServiceDelegate

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let host = Self.ipv4Address(from: sender) else { return }
        onDeviceFound?(sender.name, host)
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        onStatusUpdate?("Could not resolve \(sender.name). Try Manual IP instead.")
    }

    private static func ipv4Address(from service: NetService) -> String? {
        guard let addresses = service.addresses else { return nil }

        for addressData in addresses {
            let host = addressData.withUnsafeBytes { pointer -> String? in
                guard let base = pointer.baseAddress else { return nil }
                let storage = base.assumingMemoryBound(to: sockaddr.self)
                guard storage.pointee.sa_family == UInt8(AF_INET) else { return nil }

                let ipv4 = storage.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                var address = ipv4.sin_addr
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                guard inet_ntop(AF_INET, &address, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else {
                    return nil
                }
                return String(cString: buffer)
            }

            if let host {
                return HostAddressNormalizer.clean(host)
            }
        }

        if let hostName = service.hostName {
            return HostAddressNormalizer.clean(hostName)
        }

        return nil
    }
}
