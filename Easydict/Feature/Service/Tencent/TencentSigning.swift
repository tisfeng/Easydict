//
//  TencentSigning.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/2.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import Foundation

// Tencent sigh header, Ref: https://github.com/TencentCloud/signature-process-demo/blob/main/signature-v3/swift/signv3.swift
func tencentSignHeader(service: String, action: String, version: String, parameters: [String: Any], secretId: String, secretKey: String) -> HTTPHeaders {
    let service = service
    let host = "\(service).tencentcloudapi.com"
    let region = "ap-guangzhou"
    let action = action
    let version = version
    let algorithm = "TC3-HMAC-SHA256"
    let timestamp = Int(Date().timeIntervalSince1970)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    let date = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))

    // ************* 步骤 1：拼接规范请求串 *************
    let httpRequestMethod = "POST"
    let canonicalUri = "/"
    let canonicalQuerystring = ""
    let ct = "application/json; charset=utf-8"
    let payload = try! JSONSerialization.data(withJSONObject: parameters)
    let payloadString = String(data: payload, encoding: .utf8)!
    let canonicalHeaders = "content-type:\(ct)\nhost:\(host)\nx-tc-action:\(action.lowercased())\n"
    let signedHeaders = "content-type;host;x-tc-action"
    let hashedRequestPayload = payloadString.sha256()
    let canonicalRequest = """
    \(httpRequestMethod)
    \(canonicalUri)
    \(canonicalQuerystring)
    \(canonicalHeaders)
    \(signedHeaders)
    \(hashedRequestPayload)
    """

    // ************* 步骤 2：拼接待签名字符串 *************
    let credentialScope = "\(date)/\(service)/tc3_request"
    let hashedCanonicalRequest = canonicalRequest.sha256()
    let stringToSign = """
    \(algorithm)
    \(timestamp)
    \(credentialScope)
    \(hashedCanonicalRequest)
    """

    // ************* 步骤 3：计算签名 *************
    let secretDate = date.hmac(key: Data("TC3\(secretKey)".utf8))
    let secretService = service.hmac(key: secretDate)
    let secretSigning = "tc3_request".hmac(key: secretService)
    let signature = stringToSign.hmac(key: secretSigning).map { String(format: "%02hhx", $0) }.joined()

    // ************* 步骤 4：拼接 Authorization *************
    let authorization = """
    \(algorithm) Credential=\(secretId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)
    """

    let headers: HTTPHeaders = [
        "Authorization": authorization,
        "Content-Type": ct,
        "Host": host,
        "X-TC-Action": action,
        "X-TC-Timestamp": "\(timestamp)",
        "X-TC-Version": version,
        "X-TC-Region": region,
    ]

    return headers
}

extension String {
    // sha256
    func sha256() -> String {
        let data = Data(utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // hmac
    func hmac(key: Data) -> Data {
        let data = Data(utf8)
        let symmetricKey = SymmetricKey(data: key)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(hmac)
    }
}
