//
//  String+EncryptAES.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/4.
//  Copyright © 2023 izual. All rights reserved.
//

import CryptoSwift
import Foundation

extension String {
    private var aes: AES {
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let key = String(bundleName.sha256().prefix(16))
        let aes = try! AES(key: key, iv: key) // aes128
        return aes
    }

    public func encryptAES() -> String {
        let ciphertext = try? aes.encrypt(Array(utf8))
        let encryptedString = ciphertext?.toBase64()
        return encryptedString ?? ""
    }

    func decryptAES() -> String {
        let ciphertext = try? aes.decrypt(Array(base64: self))
        let decryptedString = String(bytes: ciphertext ?? [], encoding: .utf8)!
        return decryptedString
    }
}

@objc extension NSString {
    func encryptAES() -> NSString? {
        guard let str = self as String? else { return nil }
        return str.encryptAES() as NSString
    }

    func decryptAES() -> NSString? {
        guard let str = self as String? else { return nil }
        return str.decryptAES() as NSString
    }
}

@objc extension NSString {
    func encryptAES(keyData: Data, ivData: Data) -> NSString {
        guard let str = self as String? else { return "" }

        do {
            let aes = try AES(key: Array(keyData), blockMode: CBC(iv: Array(ivData)), padding: .pkcs7) // aes128
            let ciphertext = try aes.encrypt(Array(str.utf8))
            let encryptedString = ciphertext.toBase64()
            return encryptedString as NSString
        } catch {
            print("encryptAES error: \(error)")
            return ""
        }
    }

    func decryptAES(keyData: Data, ivData: Data) -> NSString {
        guard let str = self as String? else { return "" }

        do {
            let aes = try AES(key: Array(keyData), blockMode: CBC(iv: Array(ivData)), padding: .pkcs7) // aes128
            let ciphertext = try aes.decrypt(Array(base64: str))
            let decryptedString = String(bytes: ciphertext, encoding: .utf8)!
            return decryptedString as NSString
        } catch {
            print("decryptAES error: \(error)")
            return ""
        }
    }
}
