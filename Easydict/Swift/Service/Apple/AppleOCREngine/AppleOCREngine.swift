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
/// ocrEngine.recognizeText(image: image, language: .english) { result, error in
///     if let result = result {
///         print("Recognized text: \(result.mergedText)")
///     }
/// }
///
/// // Async/await API
/// let text = try await ocrEngine.recognizeTextAsString(cgImage: cgImage, language: .auto)
/// ```
public class AppleOCREngine {
    // MARK: Internal

    /// Main OCR method that processes image and returns complete OCR result
    ///
    /// This is the primary entry point for OCR functionality. It performs text recognition
    /// on the provided image and applies intelligent text processing to improve readability.
    ///
    /// - Parameters:
    ///   - image: The NSImage containing text to be recognized
    ///   - language: Target language for OCR recognition (use .auto for automatic detection)
    ///   - completion: Completion handler called with the OCR result or error
    ///     - result: Complete OCR result with merged text and individual text components
    ///     - error: Error that occurred during processing, if any
    ///
    /// - Note: The completion handler is always called on the main queue
    func recognizeText(
        image: NSImage,
        language: Language,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        guard let cgImage = image.toCGImage() else {
            let error = QueryError.error(
                type: .parameter, message: "Failed to convert NSImage to CGImage"
            )
            completion(nil, error)
            return
        }

        recognizeTextFromCGImage(cgImage: cgImage, language: language) { [weak self] observations, error in
            guard let self else { return }

            if let error {
                completion(nil, error)
                return
            }

            // Create OCR result from observations
            let ocrResult = EZOCRResult()
            ocrResult.from = language

            guard !observations.isEmpty else {
                let emptyError = QueryError.error(type: .noResult, message: "OCR result is empty")
                completion(ocrResult, emptyError)
                return
            }

            // Use OCR text processor for intelligent text merging
            textProcessor.setupOCRResult(
                ocrResult,
                observations: observations,
                ocrImage: image,
                intelligentJoined: true
            )
            completion(ocrResult, nil)
        }
    }

    /// Async version of recognizeText that returns complete OCR result
    ///
    /// Modern async/await API for complete OCR processing. This method performs text recognition
    /// and applies intelligent text processing to improve readability, same as the callback version
    /// but with Swift concurrency support.
    ///
    /// - Parameters:
    ///   - image: The NSImage containing text to be recognized
    ///   - language: Target language for OCR recognition (use .auto for automatic detection)
    /// - Returns: Complete OCR result with merged text and individual text components
    /// - Throws: QueryError if OCR processing fails or image conversion fails
    func recognizeTextAsync(
        image: NSImage,
        language: Language
    ) async throws
        -> EZOCRResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EZOCRResult, Error>) in
            recognizeText(image: image, language: language) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
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
    ///
    /// - Parameters:
    ///   - cgImage: The CGImage containing text to be recognized
    ///   - language: Target language for OCR recognition (defaults to .auto)
    ///   - completionHandler: Handler called with raw text observations or error
    ///     - observations: Array of VNRecognizedTextObservation from Vision framework
    ///     - error: Error that occurred during OCR processing, if any
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
    ///
    /// - Parameters:
    ///   - cgImage: The CGImage containing text to be recognized
    ///   - language: Target language for OCR recognition (defaults to .auto)
    /// - Returns: Array of VNRecognizedTextObservation containing recognized text and metadata
    /// - Throws: QueryError if OCR processing fails
    func recognizeTextAsync(cgImage: CGImage, language: Language = .auto) async throws
        -> [VNRecognizedTextObservation] {
        try await performVisionOCRAsync(on: cgImage, language: language)
    }

    /// Async version for Swift usage - returns plain text string
    ///
    /// Convenient async/await API that performs OCR and returns a simple string result.
    /// Text observations are joined with newlines for easy consumption.
    ///
    /// - Parameters:
    ///   - cgImage: The CGImage containing text to be recognized
    ///   - language: Target language for OCR recognition (defaults to .auto)
    /// - Returns: Recognized text as a single string with lines separated by newlines
    /// - Throws: QueryError if OCR processing fails
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
    /// - Disables language correction for automatic detection to improve accuracy
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

        // Determine if we should use automatic language detection
        let shouldAutoDetect = (language == .auto)

        // Configure OCR request based on language parameter
        request.automaticallyDetectsLanguage = shouldAutoDetect

        // When using automatic detection, disable language correction since we're uncertain about the language
        request.usesLanguageCorrection = !shouldAutoDetect
        request.recognitionLevel = .accurate

        let languageMapper = AppleLanguageMapper.shared
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

    /// Perform OCR using Vision framework with async/await API
    ///
    /// Internal async wrapper around the callback-based Vision OCR implementation.
    /// Converts callback-based API to modern Swift concurrency patterns.
    ///
    /// - Parameters:
    ///   - cgImage: The CGImage to perform OCR on
    ///   - language: Target language for recognition (defaults to .auto)
    /// - Returns: Array of text observations from Vision framework
    /// - Throws: QueryError if OCR processing fails
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
