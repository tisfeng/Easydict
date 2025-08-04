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

/**
 * A wrapper around Apple's Vision framework to provide OCR (Optical Character Recognition) services.
 *
 * This class simplifies the process of recognizing text from an image by encapsulating the setup
 * and execution of `VNRecognizeTextRequest`. It coordinates the entire OCR pipeline, from handling
 * the initial image to delegating the final text processing to `OCRTextProcessor`.
 *
 * It supports both a traditional callback-based API and a modern async/await interface.
 */
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
        refineWithDetectedLanguage: Bool = true,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        log("Recognizing text in image with language: \(language)")
        guard let cgImage = image.toCGImage() else {
            let error = QueryError.error(
                type: .parameter, message: "Failed to convert NSImage to CGImage"
            )
            completion(nil, error)
            return
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Perform the first OCR pass. If language is .auto, this pass will detect the language.
        recognizeTextFromCGImage(cgImage: cgImage, language: language) { [weak self] textObservations, error in
            guard let self else { return }

            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log("OCR cost time: \(elapsedTime.string2f) seconds")

            if let error {
                completion(nil, error)
                return
            }

            let ocrResult = EZOCRResult()
            ocrResult.from = language

            let smartMerging = !refineWithDetectedLanguage || hasValidOCRLanguage(language)
            log("Performing OCR text processing, intelligent: \(smartMerging)")

            // The text processor analyzes the first pass and determines the detected language.
            // It will try to detect the `ocrResult.from` language if it is set to .auto.
            textProcessor.setupOCRResult(
                ocrResult,
                observations: textObservations,
                ocrImage: image,
                smartMerging: smartMerging
            )

            let detectedLanguage = ocrResult.from

            // Check if a second, more precise OCR pass is needed.
            // If detectedLanguage is NOT a valid OCR language, like Portuguese, we don't need a second pass.
            let needsSecondPass = !smartMerging && hasValidOCRLanguage(detectedLanguage)

            log("Detected language: \(detectedLanguage), needs second pass: \(needsSecondPass)")

            if needsSecondPass {
                // Perform the second pass with the detected language for better accuracy.
                recognizeText(
                    image: image,
                    language: detectedLanguage,
                    refineWithDetectedLanguage: false,
                    completion: completion
                )
            } else {
                // If no second pass is needed, complete with the first result.
                completion(ocrResult, nil)
            }
        }
    }

    /// Checks if a given language is a valid and supported language for Vision's OCR.
    /// - Parameter language: The language to check.
    /// - Returns: `true` if the language is valid and supported, `false` otherwise.
    func hasValidOCRLanguage(_ language: Language) -> Bool {
        language != .auto && languageMapper.isSupportedOCRLanguage(language)
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
        refineWithDetectedLanguage: Bool = true
    ) async throws
        -> EZOCRResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EZOCRResult, Error>) in
            recognizeText(
                image: image,
                language: language,
                refineWithDetectedLanguage: refineWithDetectedLanguage
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
        let request = VNRecognizeTextRequest { request, error in
            if let error {
                DispatchQueue.main.async {
                    completionHandler([], error)
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty
            else {
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
}
