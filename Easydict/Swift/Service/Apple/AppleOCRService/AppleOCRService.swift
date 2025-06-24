//
//  AppleOCRService.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/21.
//  Copyright © 2025 izual. All rights reserved.
//

import CoreImage
import Foundation
import Vision

// MARK: - AppleOCRService

@objc
public class AppleOCRService: NSObject {
    // MARK: Public

    /// Main OCR method that processes image and returns complete OCR result
    @objc
    public func performOCR(
        image: NSImage,
        language: Language,
        autoDetect: Bool,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        guard let cgImage = image.toCGImage() else {
            let error = QueryError.error(
                type: .parameter, message: "Failed to convert NSImage to CGImage"
            )
            completion(nil, error)
            return
        }

        ocr(cgImage: cgImage) { [weak self] observations, error in
            guard let self = self else { return }

            if let error = error {
                completion(nil, error)
                return
            }

            // Create OCR result from observations
            let ocrResult = EZOCRResult()
            ocrResult.from = language

            if observations.isEmpty {
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

    /// Use Vision to perform OCR on the CGImage.
    @objc
    public func ocr(
        cgImage: CGImage,
        completionHandler: @escaping ([VNRecognizedTextObservation], Error?) -> ()
    ) {
        performOCR(on: cgImage, completionHandler: completionHandler)
    }

    /// Async version for Swift usage - returns string
    @objc
    public func ocrAsync(cgImage: CGImage) async throws -> String {
        let observations = try await ocr(cgImage: cgImage)
        let recognizedTexts = observations.compactMap { observation in
            observation.text
        }
        return recognizedTexts.joined(separator: "\n")
    }

    /// Async version for Swift usage - returns observations
    public func ocr(cgImage: CGImage) async throws -> [VNRecognizedTextObservation] {
        try await performOCRAsync(on: cgImage)
    }

    // MARK: Internal

    /// Create CGImage from image data
    func createCGImage(from imageData: Data) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }
        return cgImage
    }

    /// Perform OCR using Vision framework - callback version
    func performOCR(
        on cgImage: CGImage,
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

        // Configure OCR request for better accuracy
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        request.recognitionLevel = .accurate

        // Get supported OCR languages
        if let supportedLanguages = try? request.supportedRecognitionLanguages() {
            request.recognitionLanguages = supportedLanguages
        }

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
    private func performOCRAsync(on cgImage: CGImage) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            performOCR(on: cgImage) { observations, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: observations)
                }
            }
        }
    }
}
