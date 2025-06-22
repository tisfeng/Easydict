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
            let error = NSError(
                domain: "AppleOCRService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert NSImage to CGImage"]
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
                let emptyError = NSError(
                    domain: "AppleOCRService",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "OCR result is empty"]
                )
                completion(ocrResult, emptyError)
                return
            }

            // Process observations into OCR result
            setupOCRResult(ocrResult, observations: observations, intelligentJoined: true)
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
            observation.topCandidates(1).first?.string
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

    /// Process observations into structured OCR result
    func setupOCRResult(
        _ ocrResult: EZOCRResult,
        observations: [VNRecognizedTextObservation],
        intelligentJoined: Bool
    ) {
        let recognizedTexts = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        ocrResult.texts = recognizedTexts
        ocrResult.mergedText = recognizedTexts.joined(separator: "\n")
        ocrResult.raw = recognizedTexts

        // Calculate confidence
        if !observations.isEmpty {
            let totalConfidence = observations.compactMap { observation in
                observation.topCandidates(1).first?.confidence
            }.reduce(0, +)

            ocrResult.confidence = CGFloat(Float(totalConfidence) / Float(observations.count))
        } else {
            ocrResult.confidence = 0.0
        }
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
                    let error = NSError(
                        domain: "AppleOCRService",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "No text observations found"]
                    )
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
                completionHandler([], error)
            }
        }
    }

    // MARK: Private

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
