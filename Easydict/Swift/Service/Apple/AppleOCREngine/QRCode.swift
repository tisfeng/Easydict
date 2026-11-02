//
//  QRCode.swift
//  Easydict
//
//  Created by tisfeng on 2026/11/2.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation
@preconcurrency import Vision

// MARK: - QRCode

/// Detects QR codes and combines their original content with OCR results.
final class QRCode {
    // MARK: Internal

    /// Treats QR detection failures as empty payloads while propagating task cancellation.
    func payloads(in cgImage: CGImage) async throws -> [String] {
        try Task.checkCancellation()

        let payloads: [String]
        do {
            if #available(macOS 15.0, *) {
                payloads = try await detectModern(in: cgImage)
            } else {
                payloads = try await detectLegacy(in: cgImage)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            logError("QR code detection failed: \(error.localizedDescription)")
            return []
        }

        // A cancelled caller must discard results even if Vision finishes normally.
        try Task.checkCancellation()
        var seenPayloads = Set<String>()
        return payloads.filter { payload in
            let normalizedPayload = normalize(payload)
            return !normalizedPayload.isEmpty
                && seenPayloads.insert(normalizedPayload).inserted
        }
    }

    /// Creates an OCR result when the image contains QR codes but no recognized text.
    func makeResult(payloads: [String], language: Language) -> EZOCRResult {
        let result = EZOCRResult()
        result.from = language
        result.texts = payloads
        result.mergedText = payloads.joined(separator: OCRConstants.paragraphSeparator)
        result.raw = payloads
        return result
    }

    /// Appends unique QR code payloads after the recognized document text.
    func append(_ payloads: [String], to result: EZOCRResult) {
        var existingTexts = Set(result.texts.map(normalize))
        let newPayloads = payloads.filter { payload in
            let normalizedPayload = normalize(payload)
            return !normalizedPayload.isEmpty && existingTexts.insert(normalizedPayload).inserted
        }
        guard !newPayloads.isEmpty else { return }

        result.texts = result.texts + newPayloads
        result.mergedText = result.texts.joined(separator: OCRConstants.paragraphSeparator)
    }

    // MARK: Private

    /// Uses Vision's native async API on systems that support it.
    @available(macOS 15.0, *)
    private func detectModern(in cgImage: CGImage) async throws -> [String] {
        var request = DetectBarcodesRequest()
        request.symbologies = [.qr]

        do {
            let observations = try await request.perform(on: cgImage)
            return observations.compactMap(\.payloadString)
        } catch VisionError.requestCancelled(_) {
            throw CancellationError()
        }
    }

    /// Keeps synchronous Vision work off the cooperative executor on older systems.
    private func detectLegacy(in cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            // Vision can synchronously wait for utility workers when acquiring image contexts.
            // Set the blocking work item's QoS explicitly while the caller remains suspended.
            DispatchQueue.global(qos: .utility).async(qos: .utility, flags: .enforceQoS) {
                do {
                    let request = VNDetectBarcodesRequest()
                    request.symbologies = [.qr]
                    try VNImageRequestHandler(cgImage: cgImage).perform([request])

                    let observations = request.results ?? []
                    continuation.resume(returning: observations.compactMap(\.payloadStringValue))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Normalizes QR payloads for comparison without altering their returned content.
    private func normalize(_ payload: String) -> String {
        payload
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
