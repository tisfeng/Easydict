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
    /// Perform OCR using Baidu web endpoint.
    func performBaiduOCR(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        guard let data = image.mm_PNGData else {
            throw QueryError.error(type: .parameter, message: "图片为空")
        }

        let fromLang = from == .auto ? languageCode(forLanguage: .english) : languageCode(forLanguage: from)
        let toLang: String?
        if to == .auto {
            let target = EZLanguageManager.shared().userTargetLanguage(withSourceLanguage: from)
            toLang = languageCode(forLanguage: target)
        } else {
            toLang = languageCode(forLanguage: to)
        }

        do {
            return try await requestOcrResult(
                imageData: data,
                fromLang: fromLang,
                toLang: toLang
            )
        } catch {
            throw error as? QueryError
                ?? QueryError.error(type: .api, message: "识别图片文本失败")
        }
    }

    /// Requests OCR result for the given image data.
    private func requestOcrResult(
        imageData: Data,
        fromLang: String?,
        toLang: String?
    ) async throws
        -> EZOCRResult {
        let url = "\(kBaiduTranslateURL)/getocr"

        do {
            let response = try await AF.upload(
                multipartFormData: { formData in
                    formData.append(imageData, withName: "image", fileName: "blob", mimeType: "image/png")
                    formData.append(Data((fromLang ?? "").utf8), withName: "from")
                    formData.append(Data((toLang ?? "").utf8), withName: "to")
                },
                to: url,
                method: .post
            )
            .validate()
            .serializingDecodable(BaiduOcrResponse.self)
            .value

            guard let data = response.data else {
                throw QueryError.error(type: .api, message: "识别图片文本失败")
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
            ocrResult.raw = response

            let texts = ocrResult.texts
            if !texts.isEmpty {
                let merged = texts.joined(separator: " ")
                ocrResult.mergedText = merged
                return ocrResult
            }

            throw QueryError.error(type: .api, message: "识别图片文本失败")
        } catch let decodingError as DecodingError {
            logError("Baidu OCR response parsing error: \(decodingError)")
            throw QueryError.error(type: .api, message: "识别图片文本失败")
        } catch let queryError as QueryError {
            throw queryError
        } catch {
            throw QueryError.error(type: .api, message: "识别图片文本失败")
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
