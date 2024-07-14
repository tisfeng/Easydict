//
//  EZBaiduApiTranslate.swift
//  Easydict
//
//  Created by karl on 2024/7/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

@objc(EZBaiduApiTranslate)
@objcMembers
class BaiduApiTranslate: NSObject {
    // MARK: Lifecycle

    required public init(queryModel: EZQueryModel) {
        self.queryModel = queryModel
        super.init()
    }

    // MARK: Internal

    var result: EZQueryResult?

    var isEnable: Bool {
        !appId.isEmpty && !secretKey.isEmpty
    }

    func translate(_ text: String, from: Language, to: Language, completion: @escaping (EZQueryResult?, Error?) -> ()) {
        if !isEnable {
            assert(false, "API key is not enable")
            completion(result, EZError(type: EZErrorType.API, description: "API key is not enable"))
            return
        }

        guard let utf8Data = text.data(using: .utf8),
              let q = String(data: utf8Data, encoding: .utf8) else {
            logError("Failed to convert text to UTF8")
            completion(result, EZError(type: EZErrorType.API, description: "Failed to convert text to UTF8"))
            return
        }
        let salt = UUID().uuidString
        let sign = appId + q + salt + secretKey
        let signMd5 = sign.md5()

        let param: [String: Any] = [
            "q": q,
            "from": from.rawValue,
            "to": to.rawValue,
            "appid": appId,
            "salt": salt,
            "sign": signMd5,
        ]

        let request = AF.request(
            "https://fanyi-api.baidu.com/api/trans/vip/translate",
            method: .post,
            parameters: param,
            headers: [
                "Content-Type": "application/x-www-form-urlencoded",
            ]
        )
        .validate()
        .responseDecodable(of: BaiduApiResponse.self) { [weak self] response in
            guard let self else { return }
            let result = result ?? EZQueryResult()
            result.from = from
            result.to = to
            result.queryText = text

            switch response.result {
            case let .success(value):
                result.translatedResults = value.transResult.map { $0.dst }
                completion(result, nil)
            case let .failure(error):
                logError("Tencent lookup error \(error)")
                let ezError = EZError(nsError: error)
                if let data = response.data {
                    do {
                        let errorResponse = try JSONDecoder().decode(BaiduApiErrorResponse.self, from: data)
                        ezError?.errorDataMessage = "code:\(errorResponse.errorCode), msg:\(errorResponse.errorMsg)"
                    } catch {
                        logError("Failed to decode error response: \(error)")
                    }
                }
                completion(result, ezError)
            }
        }
        queryModel.setStop({
            request.cancel()
        }, serviceType: ServiceType.baidu.rawValue)
    }

    // MARK: Private

    private let queryModel: EZQueryModel

    private var appId: String {
        let appId = Defaults[.baiduAppId]

        return appId
    }

    private var secretKey: String {
        let secretKey = Defaults[.baiduSecretKey]
        return secretKey
    }
}
