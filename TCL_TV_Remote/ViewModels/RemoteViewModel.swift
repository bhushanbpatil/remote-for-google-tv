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

    /// Non-zero only between an explicit Connect tap and stop/background/teardown.
    private(set) var activeConnectToken: UInt64 = 0

    var isConnected: Bool {
        activeConnectToken > 0 && (phase == .connected || phase == .paired)
    }

    var needsPairingCode: Bool {
        activeConnectToken > 0 && !TVStorage.isPaired && phase == .waitingForCode
    }

    /// Pairing/connect UI is shown only for a user-started Connect attempt.
    var isUserConnectInProgress: Bool {
        activeConnectToken > 0 && phase.isInFlight
    }

    var savedDevice: TVDevice? {
        TVStorage.savedDevice
    }

    init() {
        connection.onPhaseChange = { [weak self] phase in
            Task { @MainActor in
                guard let self, self.activeConnectToken > 0 else { return }
                self.phase = phase
            }
        }
        connection.onStatusMessage = { [weak self] message in
            Task { @MainActor in
                guard let self, self.activeConnectToken > 0 else { return }
                self.statusMessage = message
            }
        }
        connection.onCurrentApp = { [weak self] app in
            Task { @MainActor in
                guard let self, self.activeConnectToken > 0 else { return }
                self.currentApp = app
            }
        }

        if let device = TVStorage.savedDevice {
            manualIP = device.host
            statusMessage = "Tap Connect when you want to control your TV."
        }
    }

    func onEnterBackground() {
        stopAllTVActivity()
    }

    func onEnterInactive() {
        // App switcher often hits .inactive before .background — stop any live session
        // (including Connected) so the TV isn't contacted while the app isn't in use.
        if activeConnectToken > 0 {
            stopAllTVActivity()
        }
    }

    func onBecomeActive() {
        // Warm resume from the app drawer frequently skips .background entirely.
        // Always reset so a stale activeConnectToken can't resurrect Pairing UI.
        stopAllTVActivity()
        connection.teardownStaleConnections()
    }

    func ensureIdleOnLaunch() {
        activeConnectToken = 0
        connection.teardownStaleConnections()
        clearIdleUI()
    }

    private func clearIdleUI() {
        phase = .disconnected
        pairingCode = ""
        currentApp = nil
        if savedDevice != nil {
            statusMessage = "Tap Connect when you want to control your TV."
        }
    }

    private func stopAllTVActivity() {
        activeConnectToken = 0
        phase = .disconnected
        pairingCode = ""
        currentApp = nil
        connection.disconnect()
        statusMessage = "Tap Connect when you want to use the remote."
    }

    func startDiscovery() {
        discovery.startDiscovery()
    }

    func stopDiscovery() {
        discovery.stopDiscovery()
    }

    func connect(to device: TVDevice) {
        activeConnectToken &+= 1
        TVStorage.save(device: device, paired: TVStorage.isPaired)
        manualIP = device.host
        showSetup = false
        pairingCode = ""
        phase = .connecting
        statusMessage = "Connecting…"
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
        guard activeConnectToken > 0 else { return }
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
        activeConnectToken = 0
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
        guard isConnected else {
            statusMessage = "Not connected. Tap Connect first."
            return
        }
        connection.sendKey(key)
    }

    func launchApp(_ app: StreamingApp) {
        guard isConnected else {
            statusMessage = "Not connected. Tap Connect first."
            return
        }
        connection.launchApp(deepLink: app.deepLink)
    }
}
