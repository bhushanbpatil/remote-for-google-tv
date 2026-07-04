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
    private let tlsManager: TLSManager
    private let cryptoManager: CryptoManager
    private let deviceInfo: CommandNetwork.DeviceInfo

    private var pairingManager: PairingManager?
    private var remoteManager: RemoteManager?
    private var currentHost: String?
    private var isPairingActive = false
    private var isRemoteReady = false
    private var sessionID: UInt64 = 0
    /// Set by the view model when the user explicitly taps Connect / pair.
    private var userInitiatedSessionID: UInt64 = 0

    private static let tvUnavailableMessage = "Can't reach the TV. It may be fully off — turn it on once with the TV remote. On TCL Google TV, enable Settings → System → Power and energy → Screenless service to control it while the screen is off."

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

        self.cryptoManager = cryptoManager
        self.tlsManager = tlsManager
        self.deviceInfo = CommandNetwork.DeviceInfo("client", "iPhone", "1.0", "Remote for Google TV", "1")
    }

    /// User tapped Connect — the only path that may open ports 6466/6467 on the TV.
    func connect(to host: String) {
        queue.async { [self] in
            sessionID &+= 1
            userInitiatedSessionID = sessionID
            let session = sessionID

            stopNetworkActivity()

            let normalizedHost = HostAddressNormalizer.clean(host)
            currentHost = normalizedHost
            isPairingActive = false
            isRemoteReady = false

            guard session == sessionID, session == userInitiatedSessionID else { return }

            guard ClientCertificateStore.validateCertificates() else {
                notifyPhase(.error("Client certificate is invalid. Tap Forget TV, then try again."))
                notifyStatus("Certificate error. Use Forget TV in the menu.")
                return
            }

            notifyStatus("Connecting to \(normalizedHost)…")
            notifyPhase(.connecting)

            if TVStorage.isPaired {
                connectRemote(host: normalizedHost, session: session)
            } else {
                beginPairing(host: normalizedHost, session: session)
            }
        }
    }

    func submitPairingCode(_ code: String) {
        queue.async { [self] in
            guard isPairingActive, sessionID == userInitiatedSessionID else { return }
            notifyStatus("Verifying pairing code…")
            pairingManager?.sendSecret(code.uppercased())
        }
    }

    func sendKey(_ key: TVKey) {
        queue.async { [self] in
            guard isRemoteReady else {
                notifyStatus("Not connected. Tap Connect first.")
                return
            }
            remoteManager?.send(ATVKeyPress(key: key))
        }
    }

    func launchApp(deepLink: String) {
        queue.async { [self] in
            guard isRemoteReady else {
                notifyStatus("Not connected. Tap Connect first.")
                return
            }
            remoteManager?.send(ATVDeepLink(url: deepLink))
        }
    }

    func disconnect() {
        queue.async { [self] in
            userInitiatedSessionID = 0
            sessionID &+= 1
            stopNetworkActivity()
            notifyPhase(.disconnected)
            notifyStatus("Disconnected")
        }
    }

    /// Kill any live NWConnection without changing UI — used when the app resumes and
    /// must not talk to the TV unless the user taps Connect again.
    /// (Apple TN2277: treat NWConnection as short-lived; don't reuse across suspend.)
    func teardownStaleConnections() {
        queue.async { [self] in
            userInitiatedSessionID = 0
            sessionID &+= 1
            stopNetworkActivity()
        }
    }

    private func stopNetworkActivity() {
        pairingManager?.stateChanged = nil
        remoteManager?.stateChanged = nil
        pairingManager?.disconnect()
        remoteManager?.disconnect()
        pairingManager = nil
        remoteManager = nil
        currentHost = nil
        isPairingActive = false
        isRemoteReady = false
    }

    private func connectRemote(host: String, session: UInt64) {
        guard session == sessionID, session == userInitiatedSessionID else { return }

        isRemoteReady = false
        let remote = RemoteManager(tlsManager, deviceInfo)
        remoteManager = remote
        remote.stateChanged = { [weak self] remoteState in
            self?.handleRemoteState(remoteState, host: host, session: session)
        }
        remote.connect(host)
    }

    private func markRemoteReady(session: UInt64, phase: ConnectionPhase = .connected, status: String = "Connected") {
        guard session == sessionID, session == userInitiatedSessionID else { return }
        isRemoteReady = true
        isPairingActive = false
        notifyPhase(phase)
        notifyStatus(status)
    }

    private func handleRemoteState(_ state: RemoteManager.RemoteState, host: String, session: UInt64) {
        guard session == sessionID, session == userInitiatedSessionID else { return }

        switch state {
        case .idle:
            isRemoteReady = false

        case .connectionSetUp, .connectionPrepairing:
            notifyPhase(.connecting)
            notifyStatus("Setting up connection…")

        case .connected, .firstConfigSent, .secondConfigSent:
            markRemoteReady(session: session)

        case .fisrtConfigMessageReceived(let info):
            markRemoteReady(
                session: session,
                status: "Connected to \(info.model.isEmpty ? "Google TV" : info.model)"
            )

        case .paired(let runningApp):
            guard session == sessionID, session == userInitiatedSessionID else { return }
            isRemoteReady = true
            isPairingActive = false
            notifyPhase(.connected)
            onCurrentApp?(runningApp)
            notifyStatus(runningApp.map { "Running: \($0)" } ?? "Connected")

        case .error(.connectionWaitingError):
            // Library demo auto-starts pairing here — that causes surprise codes on the TV.
            // Never auto-pair; user must tap Forget TV then Connect to re-pair explicitly.
            isRemoteReady = false
            notifyPhase(.disconnected)
            if TVStorage.isPaired {
                notifyStatus("Your TV no longer recognizes this phone. Tap ⋯ → Forget TV, then pair again.")
            } else {
                notifyStatus("Could not reach the TV for pairing. Check IP and Wi-Fi.")
            }

        case .error(.connectionFailed):
            isRemoteReady = false
            notifyPhase(.disconnected)
            notifyStatus(Self.tvUnavailableMessage)

        case .error(let error):
            isRemoteReady = false
            notifyPhase(.error(error.toString()))
            notifyStatus("Error: \(error.toString())")
        }
    }

    private func beginPairing(host: String, session: UInt64) {
        guard session == sessionID, session == userInitiatedSessionID else { return }
        guard !TVStorage.isPaired else {
            notifyPhase(.disconnected)
            notifyStatus(Self.tvUnavailableMessage)
            return
        }
        guard !isPairingActive else { return }
        isPairingActive = true

        notifyPhase(.needsPairing)
        notifyStatus("Starting pairing — watch your TV for a code.")

        let pairing = PairingManager(tlsManager, cryptoManager)
        pairingManager = pairing
        pairing.stateChanged = { [weak self] pairingState in
            self?.handlePairingState(pairingState, host: host, session: session)
        }

        pairing.connect(host, "client", "iPhone")
    }

    private func handlePairingState(_ state: PairingManager.PairingState, host: String, session: UInt64) {
        guard session == sessionID, session == userInitiatedSessionID else { return }

        switch state {
        case .waitingCode:
            notifyPhase(.waitingForCode)
            notifyStatus("Enter the 6-character code shown on your TV.")

        case .successPaired:
            TVStorage.save(device: TVDevice(name: TVStorage.savedName ?? "My Google TV", host: host), paired: true)
            isPairingActive = false
            notifyPhase(.paired)
            notifyStatus("Paired successfully. Connecting…")
            connectRemote(host: host, session: session)

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
