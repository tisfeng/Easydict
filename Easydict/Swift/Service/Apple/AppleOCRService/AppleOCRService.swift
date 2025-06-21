//
//  AppleOCRService.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/21.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

// MARK: - AppleOCRService

@objc
public class AppleOCRService: NSObject {
    // MARK: Public

    /// Use Vision to perform OCR on the image data.
    @objc
    public func ocr(
        cgImage: CGImage,
        completionHandler: @escaping ([VNRecognizedTextObservation], Error?) -> ()
    ) {
        performOCR(on: cgImage, completionHandler: completionHandler)
    }

    /// Async version for Swift usage
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

    /// Perform OCR using Vision framework - callback version
    func performOCR(
        on cgImage: CGImage,
        completionHandler: @escaping ([VNRecognizedTextObservation], Error?) -> ()
    ) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completionHandler([], error)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completionHandler([], nil)
                return
            }

            completionHandler(observations, nil)
        }

        // Configure OCR request for better accuracy
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        request.recognitionLevel = .accurate

        // Get supported OCR languages
        if let supportedLanguages = try? request.supportedRecognitionLanguages() {
            request.recognitionLanguages = supportedLanguages
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

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
