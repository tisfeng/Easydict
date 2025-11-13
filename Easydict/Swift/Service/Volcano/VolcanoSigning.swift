//
//  VolcanoSigning.swift
//  Easydict
//
//  Created by Jerry on 2024-08-12.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import Foundation

// https://www.volcengine.com/docs/6369/67269#构建-authorization
// swiftlint:disable function_parameter_count
func volcanoSigning(
    accessKeyId: String,
    secretAccessKey: String,
    host: String,
    uri: String,
    queryString: String,
    region: String,
    service: String,
    parameters: Parameters
)
    -> HTTPHeaders {
    let httpMethod = "POST"
    let algorithm = "HMAC-SHA256"
    let date = getXDate()
    let contentHashed = hashSha256(content: String(
        data: try! JSONSerialization.data(
            withJSONObject: parameters,
            options: []
        ),
        encoding: .utf8
    )!)
    var headers = [
        "Content-Type": "application/json",
        "Host": host.replacingOccurrences(of: "https://", with: ""),
        "X-Date": date,
    ]

    // Step 1: Create a canonical request
    let canonicalHeaders = getCanonicalHeaders(headers: headers)
    let signedHeaders = getSignedHeaders(headers: headers)
    let canoicalRequest = [
        httpMethod,
        uri,
        queryString,
        canonicalHeaders,
        signedHeaders,
        contentHashed,
    ].joined(separator: "\n")

    // Step 2: Create string to sign
    let xDate = headers["X-Date"]!
    let shortDate = String(xDate.prefix(8))
    let credentialScope = [
        shortDate,
        region,
        service,
        "request",
    ].joined(separator: "/")
    let canonicalRequestHashed = hashSha256(content: canoicalRequest)
    let stringToSign = [algorithm, xDate, credentialScope, canonicalRequestHashed].joined(separator: "\n")

    // Step 3: Calculate the signature
    let kDate = hmacSha256(secretAccessKey.data(using: .utf8)!, shortDate)
    let kRegion = hmacSha256(kDate, region)
    let kService = hmacSha256(kRegion, service)
    let kSigning = hmacSha256(kService, "request")
    let signature = data2str(hmacSha256(kSigning, stringToSign))

    // Step 4: Add the signature to the request
    let authorizationHeader =
        "\(algorithm) Credential=\(accessKeyId)/\(credentialScope),  SignedHeaders=\(signedHeaders), Signature=\(signature)"

    // Create and return HTTPHeaders
    headers.updateValue(authorizationHeader, forKey: "Authorization")
    return dict2headers(headers)

    // Helpers
    func getSignedHeaders(headers: [String: String]) -> String {
        var result: [String] = []
        for (key, _) in headers {
            result.append(key.lowercased())
        }
        result = result.sorted { $0 < $1 }
        return result.joined(separator: ";")
    }

    func getCanonicalHeaders(headers: [String: String]) -> String {
        var result: [String] = []
        for (key, value) in headers {
            result.append("\(key.lowercased()):\(value.trimmingCharacters(in: .whitespaces))")
        }
        result = result.sorted { $0 < $1 }
        return result.joined(separator: "\n") + "\n"
    }

    func getXDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let xDate = dateFormatter.string(from: date)
        return xDate
    }

    func hmacSha256(_ key: Data, _ content: String) -> Data {
        let hmac = HMAC<SHA256>.authenticationCode(for: content.data(using: .utf8)!, using: SymmetricKey(data: key))
        return Data(hmac)
    }

    func hashSha256(content: String) -> String {
        let digest = SHA256.hash(data: content.data(using: .utf8)!)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    func data2str(_ data: Data) -> String {
        data.map { String(format: "%02hhx", $0) }.joined()
    }

    func dict2headers(_ dict: [String: String]) -> HTTPHeaders {
        var httpHeaders = HTTPHeaders()
        for (key, value) in dict {
            httpHeaders.add(name: key, value: value)
        }
        return httpHeaders
    }
}

// swiftlint:enable function_parameter_count
