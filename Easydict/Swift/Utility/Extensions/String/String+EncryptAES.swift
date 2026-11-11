//
//  String+EncryptAES.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/4.
//  Copyright © 2023 izual. All rights reserved.
//

import CryptoKit
import CryptoSwift
import Foundation

extension String {
    fileprivate func sha256() -> String {
        let data = Data(utf8)
        let digest = CryptoKit.SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension String {
    private var aes: CryptoSwift.AES {
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let key = String(bundleName.sha256().prefix(16))
        let aes = try! CryptoSwift.AES(key: key, iv: key) // aes128
        return aes
    }

    public func encryptAES() -> String {
        let ciphertext = try? aes.encrypt(Array(utf8))
        let encryptedString = ciphertext?.toBase64()
        return encryptedString ?? ""
    }

    public func decryptAES() -> String {
        let ciphertext = try? aes.decrypt(Array(base64: self))
        let decryptedString = String(bytes: ciphertext ?? [], encoding: .utf8)!
        return decryptedString
    }
}

@objc
extension NSString {
    func encryptAES() -> NSString? {
        guard let str = self as String? else { return nil }
        return str.encryptAES() as NSString
    }

    func decryptAES() -> NSString? {
        guard let str = self as String? else { return nil }
        return str.decryptAES() as NSString
    }
}

@objc
extension NSString {
    func encryptAES(keyData: Data, ivData: Data) -> NSString {
        guard let str = self as String? else { return "" }

        do {
            let aes = try CryptoSwift
                .AES(key: Array(keyData), blockMode: CBC(iv: Array(ivData)), padding: .pkcs7) // aes128
            let ciphertext = try aes.encrypt(Array(str.utf8))
            let encryptedString = ciphertext.toBase64()
            return encryptedString as NSString
        } catch {
            logError("encryptAES error: \(error)")
            return ""
        }
    }

    func decryptAES(keyData: Data, ivData: Data) -> NSString {
        guard let str = self as String? else { return "" }

        do {
            let aes = try CryptoSwift
                .AES(key: Array(keyData), blockMode: CBC(iv: Array(ivData)), padding: .pkcs7) // aes128
            let ciphertext = try aes.decrypt(Array(base64: str))
            let decryptedString = String(bytes: ciphertext, encoding: .utf8)!
            return decryptedString as NSString
        } catch {
            logError("decryptAES error: \(error)")
            return ""
        }
    }
}
