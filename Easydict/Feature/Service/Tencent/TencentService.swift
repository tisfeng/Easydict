//
//  TencentService.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
import CryptoKit
import Foundation

@objc(EZTencentService)
public final class TencentService: QueryService {
    override public func serviceType() -> ServiceType {
        .tencent
    }

    override public func link() -> String? {
        "https://fanyi.qq.com"
    }

    override public func name() -> String {
        NSLocalizedString("tencent_translate", comment: "The name of Tencent Translate")
    }

    override public func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        // TODO: Replace MMOrderedDictionary in the API
        let orderedDict = MMOrderedDictionary<AnyObject, AnyObject>()
        TencentTranslateType.supportLanguagesDictionary.forEach { key, value in
            orderedDict.setObject(value as NSString, forKey: key.rawValue as NSString)
        }
        return orderedDict
    }

    override public func ocr(_: EZQueryModel) async throws -> EZOCRResult {
        NSLog("Tencent Translate currently does not support OCR")
        throw QueryServiceError.notSupported
    }

//MARK: API Request

    private static let defaultSecretId = ""
    private static let defaultSecretKey = ""

    // easydict://writeKeyValue?EZTencentSecretId=xxx
    private var secretId: String {
        let secretId = UserDefaults.standard.string(forKey: EZTencentSecretId)
        if let secretId, !secretId.isEmpty {
            return secretId
        } else {
            return TencentService.defaultSecretId
        }
    }

    // easydict://writeKeyValue?EZTencentSecretKey=xxx
    private var secretKey: String {
        let secretKey = UserDefaults.standard.string(forKey: EZTencentSecretKey)
        if let secretKey, !secretKey.isEmpty {
            return secretKey
        } else {
            return TencentService.defaultSecretKey
        }
    }

    public override func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult, Error?) -> Void) {
        if prehandleQueryTextLanguage(text, autoConvertChineseText: false, from: from, to: to, completion: completion) {
            return
        }
        let transType = TencentTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            result.errorType = .unsupportedLanguage
            let unsupportedType = NSLocalizedString("unsupported_translation_type", comment: "")
            result.errorMessage = "\(unsupportedType): \(from.rawValue) --> \(to.rawValue)"
            completion(result, nil)
            return
        }

        let projectId: Int64 = 0

        let parameters: [String: Any] = [
            "SourceText": text,
            "Source": transType.sourceLanguage,
            "Target": transType.targetLanguage,
            "ProjectId": projectId,
        ]

        func sha256(msg: String) -> String {
            let data = msg.data(using: .utf8)!
            let digest = SHA256.hash(data: data)
            return digest.compactMap{String(format: "%02x", $0)}.joined()
        }

        let service = "tmt"
        let host = "tmt.tencentcloudapi.com"
        let endpoint = "https://\(host)"
        let region = "ap-guangzhou"
        let action = "TextTranslate"
        let version = "2018-03-21"
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
        let hashedRequestPayload = sha256(msg: payloadString)
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
        let hashedCanonicalRequest = sha256(msg: canonicalRequest)
        let stringToSign = """
        \(algorithm)
        \(timestamp)
        \(credentialScope)
        \(hashedCanonicalRequest)
        """

        // ************* 步骤 3：计算签名 *************
        let keyData = Data("TC3\(secretKey)".utf8)
        let dateData = Data(date.utf8)
        var symmetricKey = SymmetricKey(data: keyData)
        let secretDate = HMAC<SHA256>.authenticationCode(for: dateData, using: symmetricKey)
        _ = Data(secretDate).map{String(format: "%02hhx", $0)}.joined()

        let serviceData = Data(service.utf8)
        symmetricKey = SymmetricKey(data: Data(secretDate))
        let secretService = HMAC<SHA256>.authenticationCode(for: serviceData, using: symmetricKey)
        _ = Data(secretService).map{String(format: "%02hhx", $0)}.joined()

        let signingData = Data("tc3_request".utf8)
        symmetricKey = SymmetricKey(data: secretService)
        let secretSigning = HMAC<SHA256>.authenticationCode(for: signingData, using: symmetricKey)
        _ = Data(secretSigning).map{String(format: "%02hhx", $0)}.joined()

        let stringToSignData = Data(stringToSign.utf8)
        symmetricKey = SymmetricKey(data: secretSigning)
        let signature = HMAC<SHA256>.authenticationCode(for: stringToSignData, using: symmetricKey).map{String(format: "%02hhx", $0)}.joined()

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

        let request = AF.request(endpoint,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers)
            .validate()
            .responseDecodable(of: TencentResponse.self) { [weak self] response in
                guard let self else { return }
                let result = self.result
                switch response.result {
                case let .success(value):
                    result.from = from
                    result.to = to
                    result.queryText = text
                    result.translatedResults = value.Response.TargetText.components(separatedBy: "\n")
                    completion(result, nil)
                case let .failure(error):
                    NSLog("Tencent lookup error \(error)")
                    completion(result, error)
                }
            }
        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }
}
