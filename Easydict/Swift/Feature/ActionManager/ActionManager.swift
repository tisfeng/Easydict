//
//  ActionManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/29.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import AXSwift
import Foundation

// MARK: - ActionManager

/// Singleton class responsible for handling various application actions
@objc(EZActionManager)
class ActionManager: NSObject {
    // MARK: Internal

    // MARK: - Singleton

    @objc static let shared = ActionManager()

    var translateService = BuiltInAIService()
    var polishService = PolishingService()

    // MARK: - Text Field Detection and Access

    // MARK: - Public Methods

    /// Translate selected text and replace it with the translation result
    func translateAndReplace() async {
        logInfo("Translate and Replace")
        await executeTextReplacementAction(.translate)
    }

    /// Polish selected text and replace it with the polished result
    func polishAndReplace() async {
        logInfo("Polish and Replace")
        await executeTextReplacementAction(.polish)
    }

    // MARK: Private

    /// Type of text processing action
    private enum ProcessingType {
        case translate
        case polish
    }

    private let systemUtility = SystemUtility.shared

    /// Common method to execute text replacement actions
    private func executeTextReplacementAction(_ type: ProcessingType) async {
        guard let textFieldInfo = await systemUtility.getFocusedTextFieldInfo() else {
            return
        }

        logInfo("Focused Text Field Info: \(textFieldInfo)")

        let queryText = textFieldInfo.focusedText
        let queryModel = try? await EZDetectManager().detectText(queryText)
        guard let detectedLanguage = queryModel?.detectedLanguage,
              let targetLanguage = queryModel?.queryTargetLanguage
        else {
            logError("Failed to detect target language, skipping \(type) and replace")
            return
        }

        var request = TranslationRequest(
            text: queryText,
            sourceLanguage: detectedLanguage.code,
            targetLanguage: targetLanguage.code,
            serviceType: ""
        )

        switch type {
        case .translate:
            request.serviceType = translateService.serviceType().rawValue

            await performStreamingService(
                request: request,
                textFieldInfo: textFieldInfo
            )
        case .polish:
            request.serviceType = polishService.serviceType().rawValue
            await performStreamingService(
                request: request,
                textFieldInfo: textFieldInfo
            )
        }
    }

    /// Perform translation or polishing using a streaming service
    private func performStreamingService(
        request: TranslationRequest,
        textFieldInfo: TextFieldInfo
    ) async {
        guard let service = ServiceTypes.shared().service(withTypeId: request.serviceType) else {
            logError("Service type \(request.serviceType) not found")
            return
        }

        guard let streamService = service as? StreamService else {
            logError("\(service.name()) does not support streaming")
            return
        }

        do {
            let contentStream = try await streamService.contentStreamTranslate(request: request)
            await replaceTextWithStream(contentStream, textFieldInfo: textFieldInfo)
        } catch {
            logError("stream failed: \(error.localizedDescription)")
        }
    }

    /// Replace text with streaming data
    /// - Parameters:
    ///   - contentStream: AsyncThrowingStream of text content
    ///   - textFieldInfo: Information about the text field
    private func replaceTextWithStream(
        _ contentStream: AsyncThrowingStream<String, Error>,
        textFieldInfo: TextFieldInfo
    ) async {
        logInfo("Starting streaming text replacement with: \(textFieldInfo)")

        if textFieldInfo.isSupportedAXElement {
            // Streaming replacement for supported text fields
            await performStreamingReplacement(contentStream, textFieldInfo: textFieldInfo)
        } else {
            // Animated copy-paste replacement for non-AX supported fields
            await performAnimatedCopyPasteReplacement(contentStream, textFieldInfo: textFieldInfo)
        }
    }

    /// Perform streaming replacement for supported text fields
    private func performStreamingReplacement(
        _ contentStream: AsyncThrowingStream<String, Error>,
        textFieldInfo: TextFieldInfo
    ) async {
        do {
            var currentRange = textFieldInfo.selectedRange
            for try await content in contentStream {
                if let range = currentRange {
                    // Replace at the specific range
                    systemUtility.replaceFocusedTextFieldText(
                        with: content, range: range
                    )
                    // Update range for next replacement (cursor position)
                    currentRange = CFRange(location: range.location, length: 0)
                }
            }
        } catch {
            logError("Streaming replacement failed: \(error.localizedDescription)")
        }
    }

    /// Perform animated copy-paste replacement for non-AX supported text fields
    private func performAnimatedCopyPasteReplacement(
        _ contentStream: AsyncThrowingStream<String, Error>,
        textFieldInfo: TextFieldInfo
    ) async {
        // Make sure there is selected text to replace
        guard let selectedText = textFieldInfo.selectedText, !selectedText.isEmpty else {
            logInfo("No selected text, skipping animated copy-paste replacement")
            return
        }

        do {
            // Stream content and perform animated replacement in real-time
            for try await content in contentStream {
                await SharedUtilities.copyTextAndPaste(content)

                // Small delay to allow paste operation to complete
                await Task.sleep(seconds: 0.05)
            }
        } catch {
            logError("Animated copy-paste replacement failed: \(error.localizedDescription)")
        }
    }
}

extension Task where Success == Never, Failure == Never {
    /// Sleep for given seconds within a Task
    static func sleep(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
