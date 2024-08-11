//
//  VolcanoSigning.swift
//  Easydict
//
//  Created by Jerry on 2024-08-12.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import CryptoSwift
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
    service: String
)
    -> HTTPHeaders {
    let httpMethod = "POST"
    let algorithm = "HMAC-SHA256"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    let requestDate = dateFormatter.string(from: Date())
    let dateStamp = String(requestDate)

    // Step 1: Create a canonical request
    let canonicalHeaders = "host:\(host.replacingOccurrences(of: "https://", with: ""))\nx-date:\(requestDate)\n"
    let signedHeaders = "content-type;host;x-content-sha256;x-date"
    let payloadHash = Data().sha256().hexEncodedString()

    let canonicalRequest = [
        httpMethod,
        uri,
        queryString,
        canonicalHeaders,
        signedHeaders,
        payloadHash,
    ].joined(separator: "\n")

    // Step 2: Create string to sign
    let credentialScope = "\(dateStamp)/\(region)/\(service)/request"
    let stringToSign = [
        algorithm,
        requestDate,
        credentialScope,
        canonicalRequest.data(using: .utf8)!.sha256().hexEncodedString(),
    ].joined(separator: "\n")

    // Step 3: Calculate the signature
    func hmac(_ key: [UInt8], _ data: String) -> [UInt8] {
        try! HMAC(key: key, variant: .sha2(.sha256)).authenticate(data.bytes)
    }

    var signingKey = Array("AWS4\(secretAccessKey)".utf8)
    signingKey = hmac(signingKey, dateStamp)
    signingKey = hmac(signingKey, region)
    signingKey = hmac(signingKey, service)
    signingKey = hmac(signingKey, "request")

    let signature = Data(hmac(signingKey, stringToSign)).hexEncodedString()

    // Step 4: Add the signature to the request
    let authorizationHeader =
        "\(algorithm) Credential=\(accessKeyId), SignedHeaders=\(signedHeaders), Signature=\(signature)"

    // Create and return HTTPHeaders
    return [
        "Authorization": authorizationHeader,
        "X-Date": requestDate,
        "Host": host.replacingOccurrences(of: "https://", with: ""),
    ]
}

// swiftlint:enable function_parameter_count

extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
