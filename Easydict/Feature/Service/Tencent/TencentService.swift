//
//  TencentService.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Alamofire
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
    private var apiEndPoint = "https://tmt.tencentcloudapi.com"

//TODO: Implement user SecretId/SecretKey
//    private static let defaultSecretId = ""
//    private static let defaultSecretKey = ""
//
//    private var secretId: String {
//        let secretId = UserDefaults.standard.string(forKey: EZTencentSecretId)
//        if let secretId, !secretId.isEmpty {
//            return secretId
//        } else {
//            return TencentService.defaultSecretId
//        }
//    }
//
//    private var secretKey: String {
//        let secretKey = UserDefaults.standard.string(forKey: EZTencentSecretKey)
//        if let secretKey, !secretKey.isEmpty {
//            return secretKey
//        } else {
//            return TencentService.defaultSecretKey
//        }
//    }

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

        let parameters: [String: Any] = [
            "SourceText": text.split(separator: "\n"),
            "Source": transType.sourceLanguage,
            "Target": transType.targetLanguage,
            "ProjectId": "0",
        ]

//TODO: Adopt Signiture V3 https://cloud.tencent.com/document/api/551/30636(https://www.tencentcloud.com/document/product/1161/50430)
// SecretID & SecretKey
        let secretId = ""
        let secretKey = ""
// UTC date in yyyy-mm-dd
        let date = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        let utcDate = formatter.string(from: date)
// UNIX UTC Timestamp
        let requestTimestamp = String(Int(Date().timeIntervalSince1970))
// Calculate Signiture
        let HTTPRequestMethod = "POST"
        let CanonicalURI = "/"
        let CanonicalQueryString = "" // Leave empty for POST method
        let CanonicalHeaders = "content-type:application/json"
        let HashedRequestPayload = "" //这个常量需要对 HTTP 请求正文（parameters）做 SHA256 哈希，然后十六进制编码，最后编码串转换成小写字母
        
// Components of auth
        let authAlgorithm = "TC3-HMAC-SHA256"
        let authCredential = "Credential=\(secretId)/\(utcDate)/tmt/tc3_request"
        let authSignedHeaders = "content-type;host"
        let authSigniture = "Signature="
// Authentication header
        let auth = "\(authAlgorithm) \(authCredential), \(authSignedHeaders), \(authSigniture)"

        let headers: HTTPHeaders = [
            "Authorization": auth,
            "Content-Type": "application/json",
            "Host": "tmt.tencentcloudapi.com",
            "X-TC-Action": "TextTranslate",
            "X-TC-Timestamp": requestTimestamp,
            "X-TC-Version": "2018-03-21",
            "X-TC-Region": "ap-guangzhou",
        ]

        let request = AF.request(apiEndPoint,
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
                    result.translatedResults = value.TargetText
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
