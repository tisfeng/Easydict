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
        Defaults[.baiduServiceApiTypeKey] == ServiceAPIType.secretKey
    }

    func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult?, Error?) -> ()
    ) {
        if appId.isEmpty || secretKey.isEmpty {
            let message =
                String(localized: "service.configuration.api_missing.tips \(String(localized: "baidu_translate"))")
            completion(result, QueryError(type: .missingSecretKey, message: message))
            return
        }

        guard let utf8Data = text.data(using: .utf8),
              let utf8String = String(data: utf8Data, encoding: .utf8)
        else {
            logError("Failed to convert text to UTF8")
            completion(result, QueryError(type: .api, message: "Failed to convert text to UTF8"))
            return
        }
        let salt = UUID().uuidString
        let sign = appId + utf8String + salt + secretKey
        let signMd5 = sign.md5()

        let param: [String: Any] = [
            "q": utf8String,
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
        let task = Task { [weak self] in
            guard let self else { return }
            let result = result ?? EZQueryResult()
            result.from = from
            result.to = to
            result.queryText = text

            let dataTask = request
                .validate()
                .serializingDecodable(BaiduApiResponse.self)

            do {
                let value = try await dataTask.value
                result.translatedResults = value.transResult.map { $0.dst }
                await MainActor.run {
                    completion(result, nil)
                }
            } catch {
                logError("Baidu official API error \(error)")
                let queryError = QueryError(type: .api, message: error.localizedDescription)
                let response = await dataTask.response
                if let data = response.data {
                    do {
                        let errorResponse = try JSONDecoder().decode(
                            BaiduApiErrorResponse.self, from: data
                        )
                        queryError.errorDataMessage =
                            "code:\(errorResponse.errorCode), msg:\(errorResponse.errorMsg)"
                    } catch {
                        logError("Failed to decode error response: \(error)")
                    }
                }
                await MainActor.run {
                    completion(result, queryError)
                }
            }
        }

        queryModel.setStop({
            request.cancel()
            task.cancel()
        }, serviceType: ServiceType.baidu.rawValue)
    }

    // MARK: Private

    private let queryModel: EZQueryModel

    private var appId: String {
        Defaults[.baiduAppId]
    }

    private var secretKey: String {
        Defaults[.baiduSecretKey]
    }
}
