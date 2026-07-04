//
//  TVConnectionManager.swift
//  TCL_TV_Remote
//

import Foundation
import AndroidTVRemoteControl

final class TVConnectionManager: @unchecked Sendable {
    var onPhaseChange: (@Sendable (ConnectionPhase) -> Void)?
    var onStatusMessage: (@Sendable (String) -> Void)?
    var onCurrentApp: (@Sendable (String?) -> Void)?

    private let queue = DispatchQueue(label: "com.bhution.tcltvremote.connection")
    private let pairingManager: PairingManager
    private let remoteManager: RemoteManager
    private var currentHost: String?
    private var isPairingActive = false

    init() {
        ClientCertificateStore.prepareCertificates()

        let cryptoManager = CryptoManager()

        cryptoManager.clientPublicCertificate = {
            return CertificateHelper.loadPublicKey(from: ClientCertificateStore.derURL)
        }

        let tlsManager = TLSManager {
            return CertificateHelper.loadIdentity(
                from: ClientCertificateStore.p12URL,
                password: ClientCertificateStore.pkcs12Password
            )
        }

        tlsManager.secTrustClosure = { (secTrust: SecTrust) in
            cryptoManager.serverPublicCertificate = {
                if #available(iOS 14.0, *) {
                    guard let key = SecTrustCopyKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                } else {
                    guard let key = SecTrustCopyPublicKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                }
            }
        }

        pairingManager = PairingManager(tlsManager, cryptoManager)
        remoteManager = RemoteManager(
            tlsManager,
            CommandNetwork.DeviceInfo("client", "iPhone", "1.0", "Remote for Google TV", "1")
        )
    }

    func connect(to host: String) {
        queue.async { [self] in
            let normalizedHost = HostAddressNormalizer.clean(host)
            currentHost = normalizedHost
            isPairingActive = false

            guard ClientCertificateStore.validateCertificates() else {
                notifyPhase(.error("Client certificate is invalid. Tap Forget TV, then try again."))
                notifyStatus("Certificate error. Use Forget TV in the menu.")
                return
            }

            notifyStatus("Connecting to \(normalizedHost)…")
            notifyPhase(.connecting)

            if TVStorage.isPaired {
                connectRemote(host: normalizedHost)
            } else {
                beginPairing(host: normalizedHost)
            }
        }
    }

    func submitPairingCode(_ code: String) {
        queue.async { [self] in
            notifyStatus("Verifying pairing code…")
            pairingManager.sendSecret(code.uppercased())
        }
    }

    func sendKey(_ key: TVKey) {
        queue.async { [self] in
            remoteManager.send(ATVKeyPress(key: key))
        }
    }

    func launchApp(deepLink: String) {
        queue.async { [self] in
            remoteManager.send(ATVDeepLink(url: deepLink))
        }
    }

    func disconnect() {
        queue.async { [self] in
            currentHost = nil
            isPairingActive = false
            notifyPhase(.disconnected)
            notifyStatus("Disconnected")
        }
    }

    private func connectRemote(host: String) {
        remoteManager.disconnect()
        remoteManager.stateChanged = { [weak self] remoteState in
            self?.handleRemoteState(remoteState, host: host)
        }
        remoteManager.connect(host)
    }

    private func handleRemoteState(_ state: RemoteManager.RemoteState, host: String) {
        switch state {
        case .idle:
            notifyPhase(.disconnected)

        case .connectionSetUp, .connectionPrepairing:
            notifyPhase(.connecting)
            notifyStatus("Setting up connection…")

        case .connected, .firstConfigSent, .secondConfigSent:
            notifyPhase(.connected)
            notifyStatus("Connected")

        case .fisrtConfigMessageReceived(let info):
            notifyStatus("Connected to \(info.model.isEmpty ? "Google TV" : info.model)")

        case .paired(let runningApp):
            notifyPhase(.connected)
            onCurrentApp?(runningApp)
            notifyStatus(runningApp.map { "Running: \($0)" } ?? "Connected")

        case .error(.connectionWaitingError):
            beginPairing(host: host)

        case .error(.connectionFailed):
            if !isPairingActive {
                notifyStatus("Not paired yet — starting pairing…")
                beginPairing(host: host)
            } else {
                notifyPhase(.error("Connection failed"))
                notifyStatus("Connection failed. Check IP and Wi-Fi.")
            }

        case .error(let error):
            notifyPhase(.error(error.toString()))
            notifyStatus("Error: \(error.toString())")
        }
    }

    private func beginPairing(host: String) {
        guard !isPairingActive else { return }
        isPairingActive = true

        notifyPhase(.needsPairing)
        notifyStatus("Starting pairing — watch your TV for a code.")

        pairingManager.stateChanged = { [weak self] pairingState in
            self?.handlePairingState(pairingState, host: host)
        }

        pairingManager.connect(host, "client", "iPhone")
    }

    private func handlePairingState(_ state: PairingManager.PairingState, host: String) {
        switch state {
        case .waitingCode:
            notifyPhase(.waitingForCode)
            notifyStatus("Enter the 6-character code shown on your TV.")

        case .successPaired:
            TVStorage.save(device: TVDevice(name: TVStorage.savedName ?? "My Google TV", host: host), paired: true)
            isPairingActive = false
            notifyPhase(.paired)
            notifyStatus("Paired successfully. Connecting…")
            connectRemote(host: host)

        case .error(.wrongCode):
            notifyPhase(.waitingForCode)
            notifyStatus("Wrong code. Check your TV and try again.")

        case .error(let error):
            isPairingActive = false
            notifyPhase(.error(error.toString()))
            notifyStatus("Pairing error: \(error.toString())")

        default:
            break
        }
    }

    private func notifyPhase(_ phase: ConnectionPhase) {
        onPhaseChange?(phase)
    }

    private func notifyStatus(_ message: String) {
        onStatusMessage?(message)
    }
}

private extension AndroidTVRemoteControlError {
    func toString() -> String {
        switch self {
        case .wrongCode: return "Wrong pairing code"
        case .connectionWaitingError(let error): return error.localizedDescription
        case .connectionFailed(let error): return "Connection failed: \(error.localizedDescription)"
        case .pairingNotSuccess: return "Pairing was not successful"
        case .secretNotSuccess: return "Could not verify pairing code"
        case .invalidCode(let description): return description
        case .secPKCS12ImportNotSuccess: return "Could not load client certificate"
        case .loadCertFromURLError: return "Certificate file missing"
        default: return String(describing: self)
        }
    }
}
