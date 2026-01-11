//
//  DetectManager.swift
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SystemConfiguration

// MARK: - DetectManager

/// Manager for text detection and OCR functionality.
/// Coordinates multiple detection services (Apple, Google, Baidu, Youdao) to provide
/// accurate language detection and optical character recognition.
@objc(EZDetectManager)
@objcMembers
public final class DetectManager: NSObject {
    // MARK: Lifecycle

    /// Initializes a new detect manager with the specified query model.
    /// - Parameter model: The query model containing text and image data.
    public init(model: QueryModel) {
        self.queryModel = model

        self.ocrService = AppleService.shared

        super.init()
    }

    /// Initializes a new detect manager with an empty query model.
    public override convenience init() {
        self.init(model: QueryModel())
    }

    // MARK: Public

    /// The query model containing text and image data to be processed.
    public var queryModel: QueryModel

    /// The OCR service used for text recognition (defaults to AppleService).
    public private(set) var ocrService: QueryService

    // MARK: - Static Factory

    /// Creates a new detect manager with the specified query model.
    /// - Parameter model: The query model containing text and image data.
    /// - Returns: A new detect manager instance.
    @objc(managerWithModel:)
    public static func manager(with model: QueryModel) -> DetectManager {
        DetectManager(model: model)
    }

    // MARK: - Public Methods

    /// Performs OCR on the query model's image and then detects the language of the OCR result.
    /// - Parameter completion: Callback with the updated query model and optional error.
    public func ocrAndDetectText(completion: @escaping (QueryModel, Error?) -> ()) {
        ocr { [weak self] ocrResult, error in
            guard let self else {
                completion(QueryModel(), error)
                return
            }

            guard let ocrResult else {
                completion(queryModel, error)
                return
            }

            queryModel.inputText = ocrResult.mergedText
            let ocrLanguage = ocrResult.from
            if ocrLanguage != .auto {
                queryModel.detectedLanguage = ocrLanguage
            }

            completion(queryModel, error)
        }
    }

    /// Detects the language of the given text using Apple, Google, and/or Baidu services
    /// based on the configured language detection optimization setting.
    /// - Parameters:
    ///   - queryText: The text to detect the language of.
    ///   - completion: Callback with the updated query model and optional error.
    public func detectText(_ queryText: String, completion: @escaping (QueryModel, Error?) -> ()) {
        guard !queryText.isEmpty else {
            let errorMessage = "detectText cannot be nil"
            logError(errorMessage)
            completion(queryModel, QueryError.error(type: .parameter, message: errorMessage))
            return
        }

        appleService.detectText(queryText) { [weak self] appleDetectedLanguage, error in
            guard let self else {
                completion(QueryModel(), error)
                return
            }

            var preferredLanguages = EZLanguageManager.shared().preferredLanguages

            // Add English and Chinese to the preferred language list.
            // System detect for English and Chinese is relatively accurate,
            // so we don't need to use Google or Baidu to detect again.
            preferredLanguages.append(contentsOf: [
                .english,
                .simplifiedChinese,
                .traditionalChinese,
            ])

            let isPreferredLanguage = preferredLanguages.contains(appleDetectedLanguage)

            let languageDetectOptimize = MyConfiguration.shared.languageDetectOptimize

            // If the detected language is preferred or optimization is disabled, use Apple's result.
            if isPreferredLanguage || languageDetectOptimize == .none {
                handleDetectedLanguage(appleDetectedLanguage, error: error, completion: completion)
                return
            }

            // Otherwise, use configured optimization service (Baidu or Google).
            if languageDetectOptimize == .baidu {
                baiduDetect(
                    queryText: queryText,
                    fallbackLanguage: appleDetectedLanguage,
                    fallbackError: error,
                    completion: completion
                )
                return
            }

            if languageDetectOptimize == .google {
                googleDetect(
                    queryText: queryText,
                    fallbackLanguage: appleDetectedLanguage,
                    fallbackError: error,
                    completion: completion
                )
                return
            }
        }
    }

    /// Performs OCR on the query model's image.
    /// - Parameter completion: Callback with the OCR result and optional error.
    public func ocr(completion: @escaping (EZOCRResult?, Error?) -> ()) {
        guard queryModel.ocrImage != nil else {
            let error = QueryError.error(type: .parameter, message: "ocr image cannot be nil")
            completion(nil, error)
            return
        }

        Task { [weak self] in
            guard let self else {
                completion(nil, nil)
                return
            }

            do {
                let result = try await ocrService.ocr(queryModel)
                await MainActor.run {
                    completion(result, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    /// Checks if a system proxy is configured.
    /// - Returns: `true` if an HTTP proxy is enabled, `false` otherwise.
    @objc(checkIfHasProxy)
    public func checkIfHasProxy() -> Bool {
        guard let proxies = SCDynamicStoreCopyProxies(nil) as? [String: Any] else {
            return false
        }

        let httpProxy = proxies[kSCPropNetProxiesHTTPEnable as String] as? Bool
        let httpEnable = proxies[kSCPropNetProxiesHTTPEnable as String] as? Int

        return (httpProxy == true) || (httpEnable == 1)
    }

    // MARK: Private

    // MARK: - Private Properties

    private lazy var appleService: AppleService = .shared

    private lazy var googleService: GoogleService = .init()

    private lazy var baiduService: BaiduService = .init()

    private lazy var youdaoService: YoudaoService = .init()

    // MARK: - Private Methods

    /// Performs deep OCR: first OCRs with auto-detect, then re-OCRs with the detected language
    /// if a specific language wasn't already set. This improves accuracy for languages
    /// where auto-detection may be suboptimal.
    /// - Parameter completion: Callback with the OCR result and optional error.
    private func deepOCR(completion: @escaping (EZOCRResult?, Error?) -> ()) {
        /**
         System OCR result may be inaccurate when using auto-detect language, such as:

         今日は国際ホッキョクグマの日

         But if we use Japanese to OCR again, the result will be more accurate.

         TODO: If OCR text is too long, maybe we could OCR only part of the image.
         TODO: If OCR large PDF file, we should alert user to select detected language.
         */
        ocr { [weak self] ocrResult, ocrError in
            guard let self else {
                completion(nil, ocrError)
                return
            }

            guard ocrError == nil else {
                handleOCRResult(ocrResult, error: ocrError, completion: completion)
                return
            }

            // If user has specified OCR language, we don't need to detect and OCR again.
            guard !queryModel.hasQueryFromLanguage else {
                handleOCRResult(ocrResult, error: ocrError, completion: completion)
                return
            }

            /**
             Even when confidence is high (e.g., 1.0), that just means the OCR result
             text is accurate. However, the detected language from OCR may not be accurate,
             such as 'heel' which may be detected as 'Dutch'. So we need to detect
             the text language again.
             */
            let ocrText = ocrResult?.mergedText ?? ""
            detectText(ocrText) { [weak self] queryModel, detectError in
                guard let self else {
                    completion(ocrResult, detectError)
                    return
                }

                guard let ocrResult = ocrResult, detectError == nil else {
                    completion(ocrResult, detectError)
                    return
                }

                let isConfidentLanguage = ocrResult.confidence == 1.0
                    && ocrResult.from == queryModel.detectedLanguage

                if isConfidentLanguage {
                    completion(ocrResult, nil)
                    return
                }

                Task {
                    do {
                        let result = try await self.ocrService.ocr(self.queryModel)
                        await MainActor.run {
                            self.handleOCRResult(result, error: nil, completion: completion)
                        }
                    } catch {
                        await MainActor.run {
                            self.handleOCRResult(ocrResult, error: error, completion: completion)
                        }
                    }
                }
            }
        }
    }

    /// Handles the detected language by updating the query model and calling the completion handler.
    /// - Parameters:
    ///   - language: The detected language.
    ///   - error: Optional error from detection.
    ///   - completion: Callback to invoke with the updated query model and error.
    private func handleDetectedLanguage(
        _ language: Language,
        error: Error?,
        completion: @escaping (QueryModel, Error?) -> ()
    ) {
        queryModel.detectedLanguage = language

        // If detection succeeded, we don't need to detect again temporarily.
        queryModel.needDetectLanguage = (error != nil)

        completion(queryModel, error)
    }

    /// Handles the OCR result, falling back to Youdao OCR if Apple OCR fails and
    /// Youdao OCR is enabled in settings.
    /// - Parameters:
    ///   - ocrResult: The OCR result from the primary service.
    ///   - error: Optional error from the primary OCR service.
    ///   - completion: Callback to invoke with the final OCR result and error.
    private func handleOCRResult(
        _ ocrResult: EZOCRResult?,
        error: Error?,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        guard let error = error else {
            completion(ocrResult, nil)
            return
        }

        /**
         Sometimes Apple OCR may fail, such as with Japanese text.
         If we have set Japanese as the preferred language and OCR again when the
         OCR result is empty, it seems to work currently, but we don't guarantee
         it will always work in other languages.
         */

        guard MyConfiguration.shared.enableYoudaoOCR else {
            completion(ocrResult, error)
            return
        }

        Task {
            do {
                let result = try await youdaoService.ocr(queryModel)
                await MainActor.run {
                    completion(result, nil)
                }
            } catch {
                await MainActor.run {
                    completion(ocrResult, error)
                }
            }
        }
    }

    /// Detects language using Baidu's service as a fallback.
    /// - Parameters:
    ///   - queryText: The text to detect.
    ///   - fallbackLanguage: The language to use if Baidu detection fails.
    ///   - fallbackError: The error from the previous detection attempt.
    ///   - completion: Callback to invoke with the updated query model and error.
    private func baiduDetect(
        queryText: String,
        fallbackLanguage: Language,
        fallbackError: Error?,
        completion: @escaping (QueryModel, Error?) -> ()
    ) {
        baiduService.detectText(queryText) { [weak self] language, error in
            guard let self else {
                completion(QueryModel(), error)
                return
            }

            let detectedLanguage = error == nil ? language : fallbackLanguage

            if error == nil {
                logInfo("Baidu detected: \(language)")
            } else {
                logError("Baidu detect error: \(error?.localizedDescription ?? "unknown")")
            }

            handleDetectedLanguage(detectedLanguage, error: error ?? fallbackError, completion: completion)
        }
    }

    /// Detects language using Google's service as a primary fallback,
    /// then Baidu's service if Google fails.
    /// - Parameters:
    ///   - queryText: The text to detect.
    ///   - fallbackLanguage: The language to use if all detection attempts fail.
    ///   - fallbackError: The error from the previous detection attempt.
    ///   - completion: Callback to invoke with the updated query model and error.
    private func googleDetect(
        queryText: String,
        fallbackLanguage: Language,
        fallbackError: Error?,
        completion: @escaping (QueryModel, Error?) -> ()
    ) {
        googleService.detectText(queryText) { [weak self] language, error in
            guard let self else {
                completion(QueryModel(), error)
                return
            }

            if error == nil {
                logInfo("Google detected: \(language)")
                handleDetectedLanguage(language, error: nil, completion: completion)
                return
            }

            logError("Google detect error: \(error?.localizedDescription ?? "unknown")")

            // If Google detection failed, use Baidu detection.
            baiduDetect(
                queryText: queryText,
                fallbackLanguage: fallbackLanguage,
                fallbackError: fallbackError,
                completion: completion
            )
        }
    }
}

// MARK: - DetectManager + Async

extension DetectManager {
    /// Asynchronously detects the language of the given text.
    /// - Parameter text: The text to detect language of.
    /// - Returns: The query model with detected language set.
    @nonobjc
    public func detectText(_ text: String) async throws -> QueryModel {
        try await withCheckedThrowingContinuation { continuation in
            detectText(text) { queryModel, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: queryModel)
                }
            }
        }
    }

    /// Asynchronously performs OCR on the query model's image.
    /// - Returns: The OCR result with recognized text.
    @nonobjc
    public func ocr() async throws -> EZOCRResult {
        try await withCheckedThrowingContinuation { continuation in
            ocr { ocrResult, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let ocrResult {
                    continuation.resume(returning: ocrResult)
                } else {
                    continuation.resume(throwing: QueryError.error(type: .api, message: "OCR failed"))
                }
            }
        }
    }
}
