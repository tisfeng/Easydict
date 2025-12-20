//
//  YoudaoService+OCR.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import AppKit
import Foundation

// MARK: - YoudaoService+OCR

extension YoudaoService {
    /// OCR image and get text recognition result
    /// - Parameters:
    ///   - image: Image to recognize
    ///   - from: Source language
    ///   - to: Target language
    func ocr(
        image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult {
        let imageData: Data
        if let pngData = image.pngData {
            imageData = pngData
        } else {
            throw QueryError(type: .parameter, message: "Failed to get PNG data from image")
        }

        let encodedImageStr = imageData.base64EncodedString()
        let imageBase = "data:image/png;base64,\(encodedImageStr)"

        let parameters = ["imgBase": imageBase]

        do {
            let response = try await AF.request(
                "https://aidemo.youdao.com/ocrtransapi1",
                method: .post,
                parameters: parameters,
                headers: headers
            )
            .serializingDecodable(YoudaoOCRResponse.self)
            .value

            let result = EZOCRResult()
            result.from = languageEnum(fromCode: response.lanFrom)
            result.to = languageEnum(fromCode: response.lanTo)

            let ocrTextArray = response.lines.map { line -> EZOCRText in
                let text = EZOCRText()
                text.text = line.context
                text.translatedText = line.tranContent
                return text
            }

            result.ocrTextArray = ocrTextArray

            if !ocrTextArray.isEmpty {
                let textArray = ocrTextArray.map { $0.text }
                result.texts = textArray
                result.mergedText = textArray.joined(separator: "\n")
                result.raw = response
                return result
            }

            throw QueryError(type: .api, message: "OCR failed")
        } catch {
            if let decodingError = error as? DecodingError {
                logError("Youdao OCR response parsing error: \(decodingError)")
                throw QueryError(type: .api, message: "Youdao OCR response parsing error")
            }

            throw QueryError(type: .api, message: "OCR failed")
        }
    }

    /// OCR image and translate the recognized text
    /// - Parameters:
    ///   - image: Image to recognize and translate
    ///   - from: Source language
    ///   - to: Target language
    ///   - ocrSuccess: Callback when OCR succeeds
    func ocrAndTranslate(
        image: NSImage,
        from: Language,
        to: Language,
        ocrSuccess: @escaping (EZOCRResult, Bool) -> ()
    ) async throws
        -> (ocrResult: EZOCRResult, queryResult: QueryResult?) {
        guard let result = result else { return (EZOCRResult(), nil) }

        let ocrResult = try await ocr(image: image, from: from, to: to)

        // Check if we need to translate
        if to == .auto || to == ocrResult.to {
            // Don't translate if it's Chinese/English lookup without spaces
            if !(
                (ocrResult.to == .simplifiedChinese || ocrResult.to == .english)
                    && !ocrResult.mergedText.contains(" ")
            ) {
                logInfo("Using OCR translation result directly")
                ocrSuccess(ocrResult, false)

                let queryResult = result
                queryResult.queryText = ocrResult.mergedText
                queryResult.from = ocrResult.from
                queryResult.to = ocrResult.to
                queryResult.translatedResults = ocrResult.ocrTextArray.compactMap { $0.translatedText }
                queryResult.raw = ocrResult.raw

                return (ocrResult, queryResult)
            }
        }

        // Need additional translation
        ocrSuccess(ocrResult, true)
        let queryResult = try await translate(ocrResult.mergedText, from: from, to: to, enablePrehandle: true)
        return (ocrResult, queryResult)
    }
}
