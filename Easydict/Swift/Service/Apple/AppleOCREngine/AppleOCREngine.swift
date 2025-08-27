//
//  AppleOCREngine.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/21.
//  Copyright © 2025 izual. All rights reserved.
//

import CoreImage
import Foundation
@preconcurrency import Vision

// MARK: - AppleOCREngine

/// A wrapper around Apple's Vision framework to provide OCR (Optical Character Recognition) services.
///
/// This class simplifies the process of recognizing text from an image by encapsulating the setup
/// and execution of `VNRecognizeTextRequest`. It coordinates the entire OCR pipeline, from handling
/// the initial image to delegating the final text processing to `OCRTextProcessor`.
///
/// It supports both a traditional callback-based API and a modern async/await interface.
@objc
public class AppleOCREngine: NSObject {
    // MARK: Internal

    /// Performs text recognition on a given image using async/await.
    ///
    /// This method orchestrates a one-pass or two-pass OCR process:
    /// 1.  **First Pass**: Performs an initial recognition. If the language is set to `.auto`,
    ///     this pass also serves to detect the document's language.
    /// 2.  **Second Pass (Optional)**: If text is short and language is auto, runs multi-language
    ///     candidate selection for improved accuracy.
    ///
    /// - Parameters:
    ///   - image: The `NSImage` to recognize text from.
    ///   - language: The preferred `Language` for recognition. Defaults to `.auto`.
    /// - Returns: An `EZOCRResult` containing the recognized and processed text.
    func recognizeText(image: NSImage, language: Language = .auto) async throws -> EZOCRResult {
        log("Recognizing text in image with language: \(language), image size: \(image.size)")

        guard image.isValid else {
            throw QueryError.error(type: .parameter, message: "Invalid image provided for OCR")
        }

        image.mm_writeToFile(asPNG: OCRConstants.snipImageFileURL.path())

        // Convert NSImage to CGImage
        guard let cgImage = image.toCGImage() else {
            throw QueryError.error(
                type: .parameter, message: "Failed to convert NSImage to CGImage"
            )
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Perform Vision OCR using unified API
        let observations = try await performVisionOCR(on: cgImage, language: language)

        log("Recognize observations count: \(observations.count) (\(language))")
        log("Cost time: \(startTime.elapsedTimeString) seconds")

        let ocrResult = EZOCRResult()
        ocrResult.from = language

        let mergedText = observations.simpleMergedText
        let detectedLanguage = languageDetector.detectLanguage(text: mergedText)
        let rawProbabilities = languageDetector.rawProbabilities
        let textAnalysis = languageDetector.getTextAnalysis()
        log(
            "Detected language: \(detectedLanguage), probabilities: \(rawProbabilities.prettyPrinted)"
        )

        // If OCR text is long enough, consider its detected language confident.
        // If text is too short, we need to recognize it with all candidate languages.
        let hasEnoughLength = mergedText.count > 50
        let hasDesignatedLanguage = language != .auto
        let smartMerging =
            hasDesignatedLanguage || hasEnoughLength || hasDominantLanguage(in: rawProbabilities)
        log("Merged text char count: \(mergedText.count)")
        log("Performing OCR text processing, smart merging: \(smartMerging)")

        textProcessor.setupOCRResult(
            ocrResult,
            observations: observations,
            ocrImage: image,
            smartMerging: smartMerging,
            textAnalysis: textAnalysis
        )

        if language == .auto {
            ocrResult.from = detectedLanguage
        }

        if smartMerging {
            log("OCR completion (\(language)) cost time: \(startTime.elapsedTimeString) seconds")
            return ocrResult
        }

        // If we reach here, we need to run OCR for multiple candidate languages.

        let startSelectTime = CFAbsoluteTimeGetCurrent()

        let mostConfidentResult = try await selectBestOCRResult(
            from: image,
            candidates: rawProbabilities
        )

        log("Get most confident OCR cost time: \(startSelectTime.elapsedTimeString) seconds")
        log("Total OCR cost time: \(startTime.elapsedTimeString) seconds")

        return mostConfidentResult
    }

    func pasteboardOCR() {
        logInfo("Pasteboard OCR")
        if let image = NSPasteboard.general.readImage() {
            Task {
                try await showOCRWindow(image: image)
            }
        }
    }

    @objc
    func showOCRWindow(image: NSImage, language: Language = .auto) async throws {
        let result = try await recognizeText(image: image, language: language)
        let mergedText = result.mergedText

        Task { @MainActor in
            OCRWindowManager.shared.showWindow(
                image: image,
                bands: textProcessor.bands,
                mergedText: mergedText
            )
        }
    }

    /// Callback-based text recognition api
    func recognizeText(
        image: NSImage,
        language: Language = .auto,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        Task {
            do {
                let result = try await recognizeText(image: image, language: language)
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

    // MARK: Private

    /// The text processor responsible for sorting, merging, and normalizing the OCR results.
    private let textProcessor = OCRTextProcessor()

    /// A mapper to convert between Easydict's `Language` enum and Apple's language identifiers.
    private let languageMapper = AppleLanguageMapper.shared

    /// Language detector used for tie-breaking when confidences are equal.
    private let languageDetector = AppleLanguageDetector()

    /// The core async method that executes a `VNRecognizeTextRequest` on a given `CGImage`.
    ///
    /// This function configures the Vision request based on the specified language and accuracy level,
    /// and executes it asynchronously using modern Swift concurrency.
    ///
    /// - Parameters:
    ///   - cgImage: The `CGImage` to perform OCR on.
    ///   - language: The preferred `Language` for recognition. If not a valid OCR language, defaults to automatic detection.
    /// - Returns: Array of `VNRecognizedTextObservation` objects containing recognition results.
    ///
    /// - Warning: Call this function on macOS 15.0+ will crash https://github.com/tisfeng/Easydict/issues/915
    private func performLegacyVisionOCR(on cgImage: CGImage, language: Language = .auto)
        async throws
        -> [VNRecognizedTextObservation] {
        // Try primary OCR first
        let observations = try await performSingleLegacyVisionOCR(on: cgImage, language: language)

        /**
         Handle Japanese retry logic if needed.

         For some strange reasons, the following text cannot be recognized when using automatic language detection,
         but can be recognized when explicitly specifying Japanese.

         -----------------------------------------------------------
         ｜ アイス・スノーセーリング世界選手権大会                         ｜
         -----------------------------------------------------------
         */

        if observations.isEmpty, language == .auto {
            log("No text recognized with auto language, retrying with Japanese.")
            return try await performSingleLegacyVisionOCR(on: cgImage, language: .japanese)
        }

        return observations
    }

    /// Performs a single Vision OCR request without retry logic
    private func performSingleLegacyVisionOCR(on cgImage: CGImage, language: Language) async throws
        -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    let queryError = QueryError.queryError(from: error, type: .api)!
                    continuation.resume(throwing: queryError)
                    return
                }

                let results = request.results as! [VNRecognizedTextObservation]
                if results.isEmpty {
                    log("No text recognized in the image with language: \(language)")

                    // For empty results, don't throw error - let caller handle retry logic
                    if language == .auto {
                        // Return empty array, caller will handle Japanese retry
                        continuation.resume(returning: [])
                        return
                    } else {
                        // For specific language, throw error
                        let message = String(localized: "ocr_result_is_empty")
                        let error = QueryError.error(type: .noResult, message: message)
                        continuation.resume(throwing: error)
                        return
                    }
                }

                continuation.resume(returning: results)
            }

            let enableAutoDetect = !hasValidOCRLanguage(language)
            log("Performing Vision with language: \(language), auto detect: \(enableAutoDetect)")

            // Configure Vision request
            request.recognitionLevel = .accurate
            request.recognitionLanguages = languageMapper.ocrRecognitionLanguageStrings(
                for: language
            )
            // Correction is usually useful
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = enableAutoDetect

            let requestHandler = VNImageRequestHandler(cgImage: cgImage)

            // Perform request on background queue
            // Note: We use DispatchQueue instead of Task.detached to avoid potential issues
            DispatchQueue.global().async {
                do {
                    try requestHandler.perform([request])
                } catch {
                    let queryError = QueryError.queryError(from: error, type: .api)!
                    continuation.resume(throwing: queryError)
                }
            }
        }
    }

    /// Checks if a given language is a valid and supported language for Vision's OCR.
    private func hasValidOCRLanguage(_ language: Language, isModernOCR: Bool = false) -> Bool {
        languageMapper.isSupportedOCRLanguage(language, isModernOCR: isModernOCR)
    }

    /// Performs multi-language OCR and selects the best result using trusted candidate filtering.
    /// - Parameters:
    ///   - image: Source image for OCR
    ///   - languageProbabilities: Candidate languages with detection probabilities
    /// - Returns: Best OCR result based on language consistency and confidence
    private func selectBestOCRResult(
        from image: NSImage,
        candidates languageProbabilities: [NLLanguage: Double]
    ) async throws
        -> EZOCRResult {
        log("Selecting best OCR from candidates: \(languageProbabilities.prettyPrinted)")

        // Run concurrent OCR for all candidates
        let results = try await performConcurrentOCR(
            image: image, candidates: languageProbabilities
        )

        // Filter trusted results and select best
        return selectTrustedResult(from: results)
    }

    /// Runs OCR concurrently for all candidate languages
    private func performConcurrentOCR(image: NSImage, candidates: [NLLanguage: Double]) async throws
        -> [EZOCRResult] {
        let sortedLanguages = candidates.sorted { $0.value > $1.value }.map { $0.key }
        /**
         We don't nedd ChildTaskResult type annotation anymore with Swift 6.1+
         But we still keep it for compatibility with older Swift versions for now.
         We can remove it when we drop support for older Swift versions.

         Refer: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0442-allow-taskgroup-childtaskresult-type-to-be-inferred.md

         The same as `Trailing Comma in Function Call Argument Lists` proposal:
         https://github.com/swiftlang/swift-evolution/blob/main/proposals/0439-trailing-comma-lists.md
         */
        let results = await withTaskGroup(of: EZOCRResult?.self) { group in
            for nlLanguage in sortedLanguages {
                let language = languageMapper.languageEnum(from: nlLanguage)
                guard language != .auto else { continue }

                group.addTask { [weak self] in
                    try? await self?.recognizeText(image: image, language: language)
                }
            }

            var collected: [EZOCRResult] = []
            for await result in group {
                if let result {
                    collected.append(result)
                }
            }
            return collected
        }

        guard !results.isEmpty else {
            throw QueryError.error(
                type: .noResult, message: String(localized: "ocr_result_is_empty")
            )
        }

        return results
    }

    /// Selects the best result using trusted candidate filtering
    private func selectTrustedResult(from results: [EZOCRResult]) -> EZOCRResult {
        // Build trusted results (language detection matches OCR language)
        let trusted = results.compactMap { candidate -> EZOCRResult? in
            let detected = languageDetector.detectLanguage(text: candidate.mergedText)
            guard detected == candidate.from else { return nil }

            // Boost confidence for high language detection confidence
            let nlLanguage = languageMapper.appleLanguagesDictionary[detected] ?? .undetermined
            let languageConfidence = languageDetector.rawProbabilities[nlLanguage] ?? 0.0

            if languageConfidence >= 0.9 {
                candidate.confidence += languageConfidence
            }

            return candidate
        }

        // Return best trusted result, or fallback to highest confidence
        let candidates = trusted.isEmpty ? results : trusted
        return candidates.max { $0.confidence < $1.confidence }!
    }

    /// Determines if there is a dominant language in the raw probabilities.
    ///
    /// A language is considered dominant if:
    /// 1. Its probability is greater than 0.95
    /// 2. The difference between the highest and second highest probability is greater than 0.9
    ///
    /// - Parameter rawProbabilities: Dictionary of language probabilities from language detection
    /// - Returns: True if there is a dominant language, false otherwise
    private func hasDominantLanguage(in rawProbabilities: [NLLanguage: Double]) -> Bool {
        let minDominantProbability = 0.95
        let minProbabilityGap = 0.9

        guard rawProbabilities.count >= 2 else {
            // If there's only one language or none, check if it's above the dominant threshold
            return rawProbabilities.values.first ?? 0 > minDominantProbability
        }

        // Sort probabilities in descending order
        let sortedProbabilities = rawProbabilities.values.sorted(by: >)

        let highest = sortedProbabilities[0]
        let secondHighest = sortedProbabilities[1]

        // Check both conditions for dominant language
        let hasDominant =
            highest > minDominantProbability && (highest - secondHighest) > minProbabilityGap
        log(
            "Has dominant language: \(hasDominant), highest: \(highest.string2f), second highest: \(secondHighest.string2f)"
        )

        return hasDominant
    }

    // MARK: - Unified API Implementation

    /// Performs text recognition using the best available API and returns unified results.
    ///
    /// This method automatically chooses between the modern RecognizeTextRequest API (macOS 15.0+)
    /// and the legacy VNRecognizeTextRequest API, then converts the results to a unified
    /// `EZRecognizedTextObservation` format for consistent processing.
    ///
    /// - Parameters:
    ///   - cgImage: The `CGImage` to perform OCR on.
    ///   - language: The preferred `Language` for recognition. Defaults to `.auto`.
    /// - Returns: Array of `EZRecognizedTextObservation` objects containing unified recognition results.
    private func performVisionOCR(on cgImage: CGImage, language: Language = .auto) async throws
        -> [EZRecognizedTextObservation] {
        // `performModernVisionOCR` is supported on macOS 15.0+, but it seems not working in actual tests.
        // So we only use it on macOS 26.0+ for now.
        // Fix https://github.com/tisfeng/Easydict/pull/950#issuecomment-3222553146
        if #available(macOS 26.0, *) {
            log("Using modern RecognizeTextRequest API")
            let modernObservations = try await performModernVisionOCR(
                on: cgImage, language: language
            )
            return modernObservations.toEZRecognizedTextObservations()
        } else {
            log("Using legacy VNRecognizeTextRequest API")
            let legacyObservations = try await performLegacyVisionOCR(
                on: cgImage, language: language
            )
            return legacyObservations.toEZRecognizedTextObservations()
        }
    }

    // MARK: - Modern API Implementation (macOS 15.0+)

    @available(macOS 15.0, *)
    private func performModernVisionOCR(on cgImage: CGImage, language: Language = .auto)
        async throws
        -> [RecognizedTextObservation] {
        // Try primary OCR first
        let observations = try await performSingleModernVisionOCR(on: cgImage, language: language)

        if observations.isEmpty, language == .auto {
            log("No text recognized with auto language, retrying with Japanese.")
            return try await performSingleModernVisionOCR(on: cgImage, language: .japanese)
        }

        return observations
    }

    /// Performs a single Vision OCR request using the modern async API (macOS 15.0+)
    @available(macOS 15.0, *)
    private func performSingleModernVisionOCR(on cgImage: CGImage, language: Language = .auto)
        async throws
        -> [RecognizedTextObservation] {
        let enableAutoDetect = !hasValidOCRLanguage(language, isModernOCR: true)
        log(
            "Performing modern Vision OCR with language: \(language), auto detect: \(enableAutoDetect)"
        )

        // Create the modern RecognizeTextRequest
        var request = RecognizeTextRequest()

        // Configure recognition settings
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languageMapper.ocrRecognitionLocaleLanguages(
            for: language, isModernOCR: true
        )
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = enableAutoDetect

        do {
            // Perform OCR using the new async API - returns [RecognizedText]
            let recognizedTexts = try await request.perform(on: cgImage)

            if recognizedTexts.isEmpty {
                log("No text recognized in the image with language: \(language)")

                // For empty results, don't throw error - let caller handle retry logic
                if language == .auto {
                    // Return empty array, caller will handle Japanese retry
                    return []
                } else {
                    // For specific language, throw error
                    let message = String(localized: "ocr_result_is_empty")
                    throw QueryError.error(type: .noResult, message: message)
                }
            }

            return recognizedTexts

        } catch {
            throw QueryError.queryError(from: error, type: .api)
                ?? QueryError.error(
                    type: .api, message: "Vision OCR request failed: \(error.localizedDescription)"
                )
        }
    }
}
