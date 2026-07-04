//
//  ClientCertificateStore.swift
//  TCL_TV_Remote
//

import Foundation
import AndroidTVRemoteControl

enum ClientCertificateStore {
    /// Bump when replacing bundled certificates so existing installs pick up new files.
    private static let certVersion = 3
    private static let versionKey = "atvClientCertVersion"
    static let pkcs12Password = "androidtvremote"

    private static var storageDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("ATVCertificates", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static var derURL: URL {
        storageDirectory.appendingPathComponent("client.der")
    }

    static var p12URL: URL {
        storageDirectory.appendingPathComponent("client.p12")
    }

    static func prepareCertificates() {
        let savedVersion = UserDefaults.standard.integer(forKey: versionKey)
        let derExists = FileManager.default.fileExists(atPath: derURL.path)
        let p12Exists = FileManager.default.fileExists(atPath: p12URL.path)

        guard savedVersion != certVersion || !derExists || !p12Exists else { return }

        do {
            try installBundledCertificates()
            UserDefaults.standard.set(certVersion, forKey: versionKey)
        } catch {
            print("Failed to install client certificates: \(error)")
        }
    }

    static func resetCertificates() {
        try? FileManager.default.removeItem(at: derURL)
        try? FileManager.default.removeItem(at: p12URL)
        UserDefaults.standard.removeObject(forKey: versionKey)
        prepareCertificates()
    }

    static func validateCertificates() -> Bool {
        prepareCertificates()
        switch CertificateHelper.loadIdentity(from: p12URL, password: pkcs12Password) {
        case AndroidTVRemoteControl.Result.Result:
            if case AndroidTVRemoteControl.Result.Result = CertificateHelper.loadPublicKey(from: derURL) {
                return true
            }
            return false
        case AndroidTVRemoteControl.Result.Error:
            return false
        }
    }

    private static func installBundledCertificates() throws {
        guard let bundledDER = Bundle.main.url(forResource: "cert", withExtension: "der"),
              let bundledP12 = Bundle.main.url(forResource: "cert", withExtension: "p12") else {
            throw CertificateStoreError.bundleMissing
        }

        if FileManager.default.fileExists(atPath: derURL.path) {
            try FileManager.default.removeItem(at: derURL)
        }
        if FileManager.default.fileExists(atPath: p12URL.path) {
            try FileManager.default.removeItem(at: p12URL)
        }

        try FileManager.default.copyItem(at: bundledDER, to: derURL)
        try FileManager.default.copyItem(at: bundledP12, to: p12URL)
    }
}

enum CertificateStoreError: Error {
    case bundleMissing
}
