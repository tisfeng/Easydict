//
//  BaiduService+OCR.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import AppKit
import Foundation

extension BaiduService {
    override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        guard let data = image.mm_PNGData else {
            completion(nil, QueryError.error(type: .parameter, message: "图片为空"))
            return
        }

        let fromLang = from == .auto ? languageCode(forLanguage: .english) : languageCode(forLanguage: from)
        let toLang: String?
        if to == .auto {
            let target = EZLanguageManager.shared().userTargetLanguage(withSourceLanguage: from)
            toLang = languageCode(forLanguage: target)
        } else {
            toLang = languageCode(forLanguage: to)
        }

        let url = "\(kBaiduTranslateURL)/getocr"
        AF.upload(
            multipartFormData: { formData in
                formData.append(data, withName: "image", fileName: "blob", mimeType: "image/png")
                formData.append(Data((fromLang ?? "").utf8), withName: "from")
                formData.append(Data((toLang ?? "").utf8), withName: "to")
            },
            to: url,
            method: .post
        )
        .validate()
        .responseDecodable(of: BaiduOcrResponse.self) { [weak self] response in
            guard let self else { return }
            switch response.result {
            case let .success(value):
                guard let data = value.data else {
                    completion(nil, QueryError.error(type: .api, message: "识别图片文本失败"))
                    return
                }

                let ocrResult = EZOCRResult()
                if let from = data.from {
                    ocrResult.from = languageEnum(fromCode: from)
                }
                if let to = data.to {
                    ocrResult.to = languageEnum(fromCode: to)
                }
                if let src = data.src {
                    let filtered = src.filter { !$0.isEmpty }
                    if !filtered.isEmpty {
                        let ocrTexts = filtered.map { text -> EZOCRText in
                            let ocrText = EZOCRText()
                            ocrText.text = text
                            return ocrText
                        }
                        ocrResult.ocrTextArray = ocrTexts
                        ocrResult.texts = filtered
                    }
                }
                ocrResult.raw = value

                let texts = ocrResult.texts
                if !texts.isEmpty {
                    let merged = texts.joined(separator: " ")
                    ocrResult.mergedText = merged
                    completion(ocrResult, nil)
                    return
                }

                completion(nil, QueryError.error(type: .api, message: "识别图片文本失败"))
            case .failure:
                completion(nil, QueryError.error(type: .api, message: "识别图片文本失败"))
            }
        }
    }

    override func ocrAndTranslate(
        _ image: NSImage,
        from: Language,
        to: Language,
        ocrSuccess: @escaping (EZOCRResult, Bool) -> (),
        completion: @escaping (EZOCRResult?, EZQueryResult?, Error?) -> ()
    ) {
        ocr(image, from: from, to: to) { [weak self] ocrResult, error in
            guard let self else { return }
            guard let ocrResult else {
                completion(nil, nil, error)
                return
            }

            ocrSuccess(ocrResult, true)
            translate(ocrResult.mergedText, from: from, to: to) { result, error in
                completion(ocrResult, result, error)
            }
        }
    }
}

// MARK: - BaiduOcrResponse

/// Response payload for Baidu OCR.
private struct BaiduOcrResponse: Decodable {
    let data: BaiduOcrData?
}

// MARK: - BaiduOcrData

/// Response data container for Baidu OCR.
private struct BaiduOcrData: Decodable {
    let from: String?
    let to: String?
    let src: [String]?
}
