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
public class AppleOCREngine {
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
    func recognizeText(
        image: NSImage,
        language: Language = .auto
    ) async throws
        -> EZOCRResult {
        log("Recognizing text in image with language: \(language), image size: \(image.size)")

        var startTime = CFAbsoluteTimeGetCurrent()

        // Convert NSImage to CGImage
        guard let cgImage = image.toCGImage() else {
            throw QueryError.error(
                type: .parameter, message: "Failed to convert NSImage to CGImage"
            )
        }

        var elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        log("Image converted to CGImage, cost time: \(elapsedTime.string2f) seconds")

        startTime = CFAbsoluteTimeGetCurrent()

        // Perform Vision OCR
        let observations = try await performVisionOCRAsync(on: cgImage, language: language)

        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        log(
            "Recognize count \(observations.count) \(language), cost time: \(elapsedTime.string2f) seconds"
        )

        let ocrResult = EZOCRResult()
        ocrResult.from = language

        let mergedText = observations.mergedText
        let detectedLanguage = languageDetector.detectLanguage(text: mergedText)
        let rawLanguageProbabilities = languageDetector.rawLanguageProbabilities
        let textAnalysis = languageDetector.getTextAnalysis()

        if language == .auto {
            ocrResult.from = detectedLanguage
        }

        // If OCR text is long enough, consider its detected language confident.
        // If text is too short, we need to recognize it with all candidate languages.
        let confidentOCRTextLanguage = mergedText.count > 50
        let hasDesignatedLanguage = language != .auto

        let smartMerging = hasDesignatedLanguage || confidentOCRTextLanguage
        log("Performing OCR text processing, intelligent: \(smartMerging)")

        textProcessor.setupOCRResult(
            ocrResult,
            observations: observations,
            ocrImage: image,
            smartMerging: smartMerging,
            textAnalysis: textAnalysis
        )

        log("Detected languages: \(rawLanguageProbabilities.prettyPrinted)")

        if smartMerging {
            elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log("OCR completion (\(language)) cost time: \(elapsedTime.string2f) seconds")
            return ocrResult
        }

        // Check if image cropping optimization would improve accuracy
        let croppedImage = textProcessor.getCroppedImageIfNeeded(
            observations: observations,
            ocrImage: image
        )

        if let croppedImage {
            log("Attempting OCR optimization with cropped image")
            let croppedImagePath = OCRConstants.ocrImageDirectoryURL.appending(
                path: "ocr_cropped_image.png"
            )
            croppedImage.mm_writeToFile(asPNG: croppedImagePath.path())
        }

        // If we reach here, we need to run OCR for multiple candidate languages.
        let ocrImage = croppedImage ?? image

        startTime = CFAbsoluteTimeGetCurrent()

        let mostConfidentResult = try await selectBestOCRResult(
            from: ocrImage,
            candidates: rawLanguageProbabilities
        )

        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        log("Get most confident OCR cost time: \(elapsedTime.string2f) seconds")

        return mostConfidentResult
    }

    /// Callback-based text recognition for backward compatibility.
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
    private func performVisionOCRAsync(on cgImage: CGImage, language: Language = .auto) async throws
        -> [VNRecognizedTextObservation] {
        // Try primary OCR first
        let observations = try await performSingleVisionOCR(on: cgImage, language: language)

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
            return try await performSingleVisionOCR(on: cgImage, language: .japanese)
        }

        return observations
    }

    /// Performs a single Vision OCR request without retry logic
    private func performSingleVisionOCR(on cgImage: CGImage, language: Language) async throws
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

            // Configure Vision request
            request.automaticallyDetectsLanguage = !hasValidOCRLanguage(language)
            request.usesLanguageCorrection = true
            request.recognitionLevel = .accurate
            request.recognitionLanguages = languageMapper.ocrRecognitionLanguages(for: language)

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
    private func hasValidOCRLanguage(_ language: Language) -> Bool {
        language != .auto && languageMapper.isSupportedOCRLanguage(language)
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
            throw QueryError.error(type: .noResult, message: String(localized: "ocr_result_is_empty"))
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
            let languageConfidence = languageDetector.rawLanguageProbabilities[nlLanguage] ?? 0.0

            if languageConfidence >= 0.9 {
                candidate.confidence += languageConfidence
            }

            return candidate
        }

        // Return best trusted result, or fallback to highest confidence
        let candidates = trusted.isEmpty ? results : trusted
        return candidates.max { $0.confidence < $1.confidence }!
    }
}
