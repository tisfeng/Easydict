//
//  String+EncryptAES.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/4.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation
import CryptoSwift

extension String {
    private var aes: AES {
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        let key = String(bundleName.sha256().prefix(16))
        let aes = try! AES(key: key, iv: key) // aes128
        return aes
    }
    
    func encryptAES() -> String {
        let ciphertext = try! aes.encrypt(Array(self.utf8))
        let encryptedString = ciphertext.toBase64()
        return encryptedString
    }
    
    func decryptAES() -> String {
        let ciphertext = try! aes.decrypt(Data(base64Encoded: self)!.bytes)
        let decryptedString = String(bytes: ciphertext, encoding: .utf8)!
        return decryptedString
    }
}
