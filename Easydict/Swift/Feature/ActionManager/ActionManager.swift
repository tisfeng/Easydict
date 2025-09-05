//
//  ActionManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/29.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import AXSwift
import Defaults
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

    // MARK: - Core Action Methods

    /// Common method to execute text replacement actions
    private func executeTextReplacementAction(_ type: ProcessingType) async {
        guard let textFieldInfo = await systemUtility.getFocusedTextFieldInfo() else {
            return
        }
        logInfo("Focused Text Field Info: \(textFieldInfo)")

        // Process auto-selection and get updated text field info
        guard let textFieldInfo = await processAutoTextSelection(for: textFieldInfo) else {
            return
        }
        logInfo("Text Field Info after Auto-Selection: \(textFieldInfo)")

        // Prepare translation request
        guard let request = await prepareTranslationRequest(
            from: textFieldInfo,
            type: type
        )
        else {
            return
        }

        // Execute the streaming service
        await performStreamingService(
            request: request,
            textFieldInfo: textFieldInfo
        )
    }

    // MARK: - Helper Methods

    /// Process automatic text selection based on user settings and return updated text field info
    /// - Parameter textFieldInfo: Information about the current text field
    /// - Returns: Updated TextFieldInfo after processing auto-selection, or nil if processing fails
    private func processAutoTextSelection(for textFieldInfo: TextFieldInfo) async -> TextFieldInfo? {
        let autoSelectEnabled = Defaults[.autoSelectAllTextFieldText]
        let selectedText = textFieldInfo.selectedText ?? ""

        guard autoSelectEnabled, selectedText.isEmpty else {
            return textFieldInfo
        }

        // Send Cmd+A to select all text in the field
        systemUtility.selectAll()

        // Small delay to allow selection to complete
        await Task.sleep(seconds: 0.1)

        logInfo("Auto-selected all text content in field")

        return await systemUtility.getFocusedTextFieldInfo()
    }

    /// Prepare translation request from text field information
    /// - Parameters:
    ///   - textFieldInfo: Information about the current text field
    ///   - type: The type of processing (translate or polish)
    /// - Returns: A configured TranslationRequest or nil if preparation fails
    private func prepareTranslationRequest(
        from textFieldInfo: TextFieldInfo,
        type: ProcessingType
    ) async
        -> TranslationRequest? {
        let queryText = textFieldInfo.focusedText

        // Detect language and target
        let queryModel = try? await EZDetectManager().detectText(queryText)
        guard let detectedLanguage = queryModel?.detectedLanguage,
              let targetLanguage = queryModel?.queryTargetLanguage
        else {
            logError("Failed to detect target language, skipping \(type) and replace")
            return nil
        }

        // Create base request
        var request = TranslationRequest(
            text: queryText,
            sourceLanguage: detectedLanguage.code,
            targetLanguage: targetLanguage.code,
            serviceType: "",
            queryType: .translation
        )

        // Set service type based on processing type
        switch type {
        case .translate:
            request.serviceType = translateService.serviceType().rawValue
        case .polish:
            request.serviceType = polishService.serviceType().rawValue
        }

        return request
    }

    // MARK: - Streaming Service Methods

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

    // MARK: - Text Replacement Methods

    /// Replace text with streaming data
    /// - Parameters:
    ///   - contentStream: AsyncThrowingStream of text content
    ///   - textFieldInfo: Information about the text field
    private func replaceTextWithStream(
        _ contentStream: AsyncThrowingStream<String, Error>,
        textFieldInfo: TextFieldInfo
    ) async {
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
        logInfo("Performing streaming replacement for AX supported text field")

        do {
            var currentRange = textFieldInfo.selectedRange
            for try await content in contentStream {
//                logInfo("Received streaming content chunk: \(content.prettyJSONString)")

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
        logInfo("Performing animated copy-paste replacement for non-AX supported text field")

        do {
            // Stream content and perform animated replacement in real-time
            for try await content in contentStream {
//                logInfo("Received streaming content chunk: \(content.prettyJSONString)")

                await SharedUtilities.copyTextAndPaste(content)

                // Small delay to allow paste operation to complete
                await Task.sleep(seconds: 0.05)
            }
        } catch {
            logError("Animated copy-paste replacement failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Task Extensions

extension Task where Success == Never, Failure == Never {
    /// Sleep for given seconds within a Task
    static func sleep(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
