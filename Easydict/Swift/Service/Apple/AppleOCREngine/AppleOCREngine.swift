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

/// Apple's Vision framework-based OCR engine for text recognition
///
/// This class provides a complete OCR solution using Apple's Vision framework,
/// offering both simple text recognition and intelligent text processing capabilities.
/// It supports multiple languages and provides both callback-based and async/await APIs.
///
/// **Key Features:**
/// - Multi-language text recognition using Vision framework
/// - Intelligent text merging and formatting
/// - Both synchronous and asynchronous APIs
/// - Automatic language detection support
/// - High-accuracy text recognition
///
/// **Usage Example:**
/// ```swift
/// let ocrEngine = AppleOCREngine()
///
/// // Callback-based API
/// ocrEngine.recognizeText(image: image) { result, error in
///     if let result = result {
///         print("Recognized text: \(result.mergedText)")
///     }
/// }
///
/// // Async/await API
/// let text = try await ocrEngine.recognizeTextAsString(cgImage: cgImage)
/// ```
public class AppleOCREngine {
    // MARK: Internal

    /// Main OCR method that processes image and returns complete OCR result
    ///
    /// This is the primary entry point for OCR functionality. It performs text recognition
    /// on the provided image and applies intelligent text processing to improve readability.
    /// When language is .auto and shouldRefineWithDetectedLanguage is true, it performs a
    /// two-pass OCR process for enhanced accuracy.
    ///
    /// - Parameters:
    ///   - image: The NSImage containing text to be recognized
    ///   - language: Target language for OCR recognition (use .auto for automatic detection)
    ///   - shouldRefineWithDetectedLanguage: When true and language is .auto, performs a second
    ///     OCR pass using the detected language for improved accuracy. Defaults to true.
    ///   - completion: Completion handler called with the OCR result or error
    ///     - result: Complete OCR result with merged text and individual text components
    ///     - error: Error that occurred during processing, if any
    ///
    /// - Note: The completion handler is always called on the main queue
    func recognizeText(
        image: NSImage,
        language: Language = .auto,
        shouldRefineWithDetectedLanguage: Bool = true,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        print("Recognizing text in image with language: \(language)")
        guard let cgImage = image.toCGImage() else {
            let error = QueryError.error(
                type: .parameter, message: "Failed to convert NSImage to CGImage"
            )
            completion(nil, error)
            return
        }

        // Perform the first OCR pass. If language is .auto, this pass will detect the language.
        recognizeTextFromCGImage(cgImage: cgImage, language: language) { [weak self] textObservations, error in
            guard let self else { return }

            if let error {
                completion(nil, error)
                return
            }

            let ocrResult = EZOCRResult()
            ocrResult.from = language

            guard !textObservations.isEmpty else {
                let emptyError = QueryError.error(type: .noResult, message: "OCR result is empty")
                completion(ocrResult, emptyError)
                return
            }

            let needIntelligentTextProcessing = !shouldRefineWithDetectedLanguage || hasValidOCRLanguage(language)
            print("Performing OCR text processing, intelligent: \(needIntelligentTextProcessing)")

            // The text processor analyzes the first pass and determines the detected language.
            // It will try to detect the `ocrResult.from` language if it is set to .auto.
            textProcessor.setupOCRResult(
                ocrResult,
                observations: textObservations,
                ocrImage: image,
                intelligentJoined: needIntelligentTextProcessing
            )

            let detectedLanguage = ocrResult.from

            // Check if a second, more precise OCR pass is needed.
            let needsSecondPass = shouldRefineWithDetectedLanguage && hasValidOCRLanguage(detectedLanguage)
            print("Detected language: \(detectedLanguage), needs second pass: \(needsSecondPass)")

            if needsSecondPass {
                // Perform the second pass with the detected language for better accuracy.
                recognizeText(
                    image: image,
                    language: detectedLanguage,
                    shouldRefineWithDetectedLanguage: false,
                    completion: completion
                )
            } else {
                // If no second pass is needed, complete with the first result.
                completion(ocrResult, nil)
            }
        }
    }

    /// Check if the provided language is supported by Vision framework
    func hasValidOCRLanguage(_ language: Language) -> Bool {
        language != .auto && languageMapper.isSupportedOCRLanguage(language)
    }

    /// Async version of recognizeText that returns complete OCR result
    ///
    /// Modern async/await API for complete OCR processing. This method performs text recognition
    /// and applies intelligent text processing to improve readability, same as the callback version
    /// but with Swift concurrency support. Supports two-pass OCR for enhanced accuracy when
    /// automatic language detection is enabled.
    func recognizeTextAsync(
        image: NSImage,
        language: Language = .auto,
        shouldRefineWithDetectedLanguage: Bool = true
    ) async throws
        -> EZOCRResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EZOCRResult, Error>) in
            recognizeText(
                image: image,
                language: language,
                shouldRefineWithDetectedLanguage: shouldRefineWithDetectedLanguage
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

    /// Recognize text from CGImage with raw Vision observations
    ///
    /// This method provides direct access to Vision framework text observations
    /// without additional text processing. Useful when you need raw OCR data.
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

    /// Async version for Swift usage - returns raw text observations
    ///
    /// Modern async/await API for text recognition that returns raw Vision observations.
    /// This method is ideal for Swift concurrency patterns and provides fine-grained
    /// control over OCR results.
    func recognizeTextAsync(cgImage: CGImage, language: Language = .auto) async throws
        -> [VNRecognizedTextObservation] {
        try await performVisionOCRAsync(on: cgImage, language: language)
    }

    /// Async version for Swift usage - returns plain text string
    ///
    /// Convenient async/await API that performs OCR and returns a simple string result.
    /// Text observations are joined with newlines for easy consumption.
    func recognizeTextAsString(cgImage: CGImage, language: Language = .auto) async throws -> String {
        let observations = try await recognizeTextAsync(cgImage: cgImage, language: language)
        let recognizedTexts = observations.compactMap(\.firstText)
        return recognizedTexts.joined(separator: "\n")
    }

    /// Perform OCR using Vision framework with callback-based API
    ///
    /// Core OCR implementation using Apple's Vision framework. Configures recognition
    /// parameters based on the target language and performs text recognition on a
    /// background queue to avoid blocking the main thread.
    ///
    /// **Configuration Details:**
    /// - Uses automatic language detection when language is .auto
    /// - Sets recognition level to .accurate for best quality results
    /// - Maps input language to Vision framework's language codes
    ///
    /// - Parameters:
    ///   - cgImage: The CGImage to perform OCR on
    ///   - language: Target language for recognition (defaults to .auto)
    ///   - completionHandler: Handler called with results on main queue
    ///     - observations: Array of text observations from Vision framework
    ///     - error: Error that occurred during processing, if any
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

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    let error = QueryError.error(type: .noResult, message: "OCR result is empty")
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

    // OCR text processor for intelligent text merging
    private let textProcessor = OCRTextProcessor()

    private let languageMapper = AppleLanguageMapper.shared

    /// Perform OCR using Vision framework with async/await API
    ///
    /// Internal async wrapper around the callback-based Vision OCR implementation.
    /// Converts callback-based API to modern Swift concurrency patterns.
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
