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

public class AppleOCREngine {
    // MARK: Internal

    /// Main OCR method that processes image and returns complete OCR result
    func recognizeText(
        image: NSImage,
        language: Language,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        guard let cgImage = image.toCGImage() else {
            let error = QueryError.error(type: .parameter, message: "Failed to convert NSImage to CGImage")
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

    /// Recognize text from CGImage with callback
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

    /// Async version for Swift usage - returns observations
    func recognizeTextAsync(cgImage: CGImage, language: Language = .auto) async throws
        -> [VNRecognizedTextObservation] {
        try await performVisionOCRAsync(on: cgImage, language: language)
    }

    /// Async version for Swift usage - returns string
    func recognizeTextAsString(cgImage: CGImage, language: Language = .auto) async throws -> String {
        let observations = try await recognizeTextAsync(cgImage: cgImage, language: language)
        let recognizedTexts = observations.compactMap(\.firstText)
        return recognizedTexts.joined(separator: "\n")
    }

    /// Perform OCR using Vision framework - callback version
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
    private let textProcessor = AppleOCRTextProcessor()

    /// Perform OCR using Vision framework - async version
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
