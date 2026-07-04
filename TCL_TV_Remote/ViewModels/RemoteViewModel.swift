//
//  RemoteViewModel.swift
//  TCL_TV_Remote
//

import Foundation

@MainActor
@Observable
final class RemoteViewModel {
    var phase: ConnectionPhase = .disconnected
    var statusMessage = "Connect to your Google TV to get started."
    var currentApp: String?
    var pairingCode = ""
    var manualIP = ""
    var showSetup = false

    let discovery = TVDiscoveryService()
    private let connection = TVConnectionManager()

    var isConnected: Bool {
        phase == .connected || phase == .paired
    }

    var needsPairingCode: Bool {
        phase == .waitingForCode
    }

    var savedDevice: TVDevice? {
        TVStorage.savedDevice
    }

    init() {
        connection.onPhaseChange = { [weak self] phase in
            Task { @MainActor in
                self?.phase = phase
            }
        }
        connection.onStatusMessage = { [weak self] message in
            Task { @MainActor in
                self?.statusMessage = message
            }
        }
        connection.onCurrentApp = { [weak self] app in
            Task { @MainActor in
                self?.currentApp = app
            }
        }

        if let device = TVStorage.savedDevice {
            manualIP = device.host
        }
    }

    func onAppear() {
        if let device = TVStorage.savedDevice, TVStorage.isPaired {
            connect(to: device)
        }
    }

    func onReturnToForeground() {
        guard let device = TVStorage.savedDevice, TVStorage.isPaired else { return }
        switch phase {
        case .connected, .paired, .connecting, .needsPairing, .waitingForCode:
            return
        case .disconnected, .error:
            connect(to: device)
        }
    }

    func startDiscovery() {
        discovery.startDiscovery()
    }

    func stopDiscovery() {
        discovery.stopDiscovery()
    }

    func connect(to device: TVDevice) {
        TVStorage.save(device: device, paired: TVStorage.isPaired)
        manualIP = device.host
        showSetup = false
        pairingCode = ""
        connection.connect(to: device.host)
    }

    func connectManualIP() {
        let trimmed = HostAddressNormalizer.clean(manualIP)
        guard !trimmed.isEmpty else {
            statusMessage = "Enter your TV's IP address."
            return
        }
        manualIP = trimmed
        connect(to: TVDevice(name: "Google TV", host: trimmed))
    }

    func submitPairingCode() {
        let code = pairingCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6 else {
            statusMessage = "Enter the 6-character code from your TV."
            return
        }
        connection.submitPairingCode(code)
    }

    func reconnect() {
        guard let device = TVStorage.savedDevice else {
            showSetup = true
            return
        }
        connect(to: device)
    }

    func forgetTV() {
        connection.disconnect()
        ClientCertificateStore.resetCertificates()
        TVStorage.clear()
        phase = .disconnected
        manualIP = HostAddressNormalizer.clean(manualIP)
        pairingCode = ""
        currentApp = nil
        statusMessage = "Reset complete. Connect with your TV IP and enter the new pairing code."
        showSetup = true
    }

    func sendKey(_ key: TVKey) {
        connection.sendKey(key)
    }

    func launchApp(_ app: StreamingApp) {
        connection.launchApp(deepLink: app.deepLink)
    }
}
