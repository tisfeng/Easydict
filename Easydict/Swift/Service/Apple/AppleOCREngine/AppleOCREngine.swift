//
//  AppleOCREngine.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/21.
//  Copyright © 2025 izual. All rights reserved.
//

import CoreImage
import Foundation
import Vision

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

    /// Performs text recognition on a given image with a completion handler.
    ///
    /// This method orchestrates a one-pass or two-pass OCR process:
    /// 1.  **First Pass**: Performs an initial recognition. If the language is set to `.auto`,
    ///     this pass also serves to detect the document's language.
    /// 2.  **Second Pass (Optional)**: If `shouldRefineWithDetectedLanguage` is true and a specific
    ///     language was detected, a second, more accurate pass is performed using the detected language.
    ///
    /// - Parameters:
    ///   - image: The `NSImage` to recognize text from.
    ///   - language: The preferred `Language` for recognition. Defaults to `.auto`.
    ///   - refineWithDetectedLang: If true, triggers a second pass with the detected language for improved accuracy.
    ///   - completion: A closure that is called on the main queue with the `EZOCRResult` or an error.
    func recognizeText(
        image: NSImage,
        language: Language = .auto,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        log("Recognizing text in image with language: \(language), image size: \(image.size)")

        var startTime = CFAbsoluteTimeGetCurrent()
        // cost time: ~0.02 seconds
        guard let cgImage = image.toCGImage() else {
            let error = QueryError.error(
                type: .parameter, message: "Failed to convert NSImage to CGImage"
            )
            completion(nil, error)
            return
        }
        var elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        log("Image converted to CGImage, cost time: \(elapsedTime.string2f) seconds")

        startTime = CFAbsoluteTimeGetCurrent()

        recognizeTextFromCGImage(cgImage: cgImage, language: language) { [weak self] observations, error in
            guard let self else { return }

            elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log("Recognize count \(observations.count) \(language), cost time: \(elapsedTime.string2f) seconds")

            if let error {
                completion(nil, error)
                return
            }

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
            // If text is too short, we need to recognize it with the all candidate languages.
            let confidentOCRTextLanguage = mergedText.count > 50 ? true : false
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

                DispatchQueue.main.async {
                    completion(ocrResult, nil)
                }
                return
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
            Task { [weak self] in
                guard let self else { return }

                let ocrImage = croppedImage ?? image

                startTime = CFAbsoluteTimeGetCurrent()

                let mostConfidentResult = try await selectBestOCRResult(
                    from: ocrImage,
                    candidates: rawLanguageProbabilities
                )

                elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                log("Get most confident OCR cost time: \(elapsedTime.string2f) seconds")

                await MainActor.run {
                    completion(mostConfidentResult, nil)
                }
            }
        }
    }

    /// An async/await variant of `recognizeText` that returns a structured `EZOCRResult`.
    /// - Parameters:
    ///   - image: The `NSImage` to recognize text from.
    ///   - language: The preferred `Language` for recognition. Defaults to `.auto`.
    ///   - refineWithDetectedLanguage: If true, triggers a second pass with the detected language for improved accuracy.
    /// - Returns: An `EZOCRResult` containing the recognized and processed text.
    func recognizeTextAsync(
        image: NSImage,
        language: Language = .auto,
    ) async throws
        -> EZOCRResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EZOCRResult, Error>) in
            recognizeText(
                image: image,
                language: language,
            ) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(
                        throwing: QueryError.error(type: .noResult, message: "No OCR result")
                    )
                }
            }
        }
    }

    /// Performs raw text recognition on a `CGImage` and returns the observations via a completion handler.
    /// - Parameters:
    ///   - cgImage: The `CGImage` to perform OCR on.
    ///   - language: The preferred `Language` for recognition. Defaults to `.auto`.
    ///   - completionHandler: A closure that is called with the recognized text observations or an error.
    func recognizeTextFromCGImage(
        cgImage: CGImage,
        language: Language = .auto,
        completionHandler: @escaping ([VNRecognizedTextObservation], Error?) -> ()
    ) {
        performVisionOCR(
            on: cgImage,
            language: language,
            completionHandler: completionHandler
        )
    }

    /// An async/await variant of `recognizeTextFromCGImage` that returns an array of raw `VNRecognizedTextObservation` objects.
    func recognizeTextAsync(cgImage: CGImage, language: Language = .auto) async throws
        -> [VNRecognizedTextObservation] {
        try await performVisionOCRAsync(on: cgImage, language: language)
    }

    /// A convenience async/await method that returns the recognized text as a single formatted string.
    func recognizeTextAsString(cgImage: CGImage, language: Language = .auto) async throws -> String {
        let observations = try await recognizeTextAsync(cgImage: cgImage, language: language)
        let recognizedTexts = observations.compactMap(\.firstText)
        return recognizedTexts.joined(separator: "\n")
    }

    /// The core method that executes a `VNRecognizeTextRequest` on a given `CGImage`.
    ///
    /// This function configures the Vision request based on the specified language and accuracy level,
    /// and executes it. The results are returned via a completion handler on the main queue.
    ///
    /// - Parameters:
    ///   - cgImage: The `CGImage` to perform OCR on.
    ///   - language: The preferred `Language` for recognition. If not a valid OCR language, it defaults to automatic detection.
    ///   - completionHandler: A closure called on the main queue with the recognition results or an error.
    func performVisionOCR(
        on cgImage: CGImage,
        language: Language = .auto,
        completionHandler: @escaping ([VNRecognizedTextObservation], Error?) -> ()
    ) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error {
                DispatchQueue.main.async {
                    completionHandler([], error)
                }
                return
            }

            let observations = request.results as! [VNRecognizedTextObservation]
            if observations.isEmpty {
                log("No text recognized in the image.")

                /**
                 For some strange reasons, the following text cannot be recognized when using automatic language detection,
                 but can be recognized when explicitly specifying Japanese.

                  -----------------------------------------------------------
                 ｜ アイス・スノーセーリング世界選手権大会                         ｜
                  -----------------------------------------------------------
                 */
                if language == .auto {
                    log("Retrying OCR with Japanese language.")
                    performVisionOCR(
                        on: cgImage, language: .japanese, completionHandler: completionHandler
                    )
                    return
                }

                DispatchQueue.main.async {
                    let message = String(localized: "ocr_result_is_empty")
                    let error = QueryError.error(type: .noResult, message: message)
                    completionHandler([], error)
                }
                return
            }

            // Complete in the main thread
            DispatchQueue.main.async {
                completionHandler(observations, nil)
            }
        }

        // If language is NOT a valid Apple OCR language, means we should use automatic detection.
        request.automaticallyDetectsLanguage = !hasValidOCRLanguage(language)

        // Set it to true, correction is useful for some cases.
        request.usesLanguageCorrection = true
        request.recognitionLevel = .accurate

        request.recognitionLanguages = languageMapper.ocrRecognitionLanguages(for: language)

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // Perform request on background queue to avoid blocking
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    let queryError = QueryError.queryError(from: error, type: .api)
                    completionHandler([], queryError)
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

    /// An internal async wrapper around the callback-based `performVisionOCR` method.
    private func performVisionOCRAsync(on cgImage: CGImage, language: Language = .auto) async throws
        -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            performVisionOCR(on: cgImage, language: language) { observations, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: observations)
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
    private func performConcurrentOCR(image: NSImage, candidates: [NLLanguage: Double]) async throws -> [EZOCRResult] {
        let sortedLanguages = candidates.sorted { $0.value > $1.value }.map { $0.key }

        let results = await withTaskGroup(of: EZOCRResult?.self) { group in
            for nlLanguage in sortedLanguages {
                let language = languageMapper.languageEnum(from: nlLanguage)
                guard language != .auto else { continue }

                group.addTask { [weak self] in
                    try? await self?.recognizeTextAsync(image: image, language: language)
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
                type: .noResult, message: "No OCR results for candidate languages"
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
