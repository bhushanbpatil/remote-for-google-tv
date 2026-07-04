//
//  ATVProtocolHelpers.swift
//  TCL_TV_Remote
//

import Foundation
import AndroidTVRemoteControl

enum CertificateHelper {
    static func loadIdentity(from url: URL, password: String) -> AndroidTVRemoteControl.Result<CFArray?> {
        let p12Data: Data
        do {
            p12Data = try Data(contentsOf: url)
        } catch {
            return .Error(.loadCertFromURLError(error))
        }

        let importOptions = [kSecImportExportPassphrase as String: password]
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, importOptions as CFDictionary, &rawItems)

        guard status == errSecSuccess else {
            return .Error(.secPKCS12ImportNotSuccess)
        }

        return .Result(rawItems)
    }

    static func loadPublicKey(from url: URL) -> AndroidTVRemoteControl.Result<SecKey> {
        guard let certificateData = NSData(contentsOf: url),
              let certificate = SecCertificateCreateWithData(nil, certificateData) else {
            return .Error(.createCertFromDataError)
        }

        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)

        guard status == errSecSuccess, let secTrust = trust else {
            return .Error(.createTrustObjectError)
        }

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

struct ATVKeyPress: RequestDataProtocol {
    let key: TVKey

    var data: Data {
        let encodedKey = encodeVarint(key.rawValue)
        var payload = Data()
        payload.append(contentsOf: [0x52, UInt8(3 + encodedKey.count), 0x08])
        payload.append(contentsOf: encodedKey)
        payload.append(contentsOf: [0x10, 0x03])
        return payload
    }

    var length: UInt8 {
        UInt8(data.count)
    }

    private func encodeVarint(_ value: UInt) -> [UInt8] {
        guard value > 127 else { return [UInt8(value)] }

        var encodedBytes: [UInt8] = []
        var val = value

        while val != 0 {
            var byte = UInt8(val & 0x7F)
            val >>= 7
            if val != 0 {
                byte |= 0x80
            }
            encodedBytes.append(byte)
        }

        return encodedBytes
    }
}

struct ATVDeepLink: RequestDataProtocol {
    let url: String

    var data: Data {
        var payload = Data([0xd2, 0x05, UInt8(2 + url.count), 0x0a, UInt8(url.count)])
        payload.append(contentsOf: url.utf8)
        return payload
    }

    var length: UInt8 {
        UInt8(data.count)
    }
}
