//
//  ActionManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/29.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Defaults
import Foundation
import SelectedTextKit

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
        let queryText = textFieldInfo.focusedText
        guard let request = await prepareTranslationRequest(queryText: queryText, type: type) else {
            return
        }

        // Execute the streaming service
        await performStreamingService(
            request: request,
            textFieldInfo: textFieldInfo
        )
    }

    // MARK: - Helper Methods

    /// Determine the appropriate text strategy set based on the text field info and user settings
    private func textStrategySet(for textFieldInfo: TextFieldInfo) -> TextStrategySet {
        let isSupportedAX = textFieldInfo.isSupportedAXElement
        let enableCompatibilityMode = Defaults[.enableCompatibilityReplace]

        let isBrowser = AppleScriptTask.isBrowserSupportingAppleScript(frontmostAppBundleID)
        let preferAppleScriptAPI = Defaults[.preferAppleScriptAPI]
        let shouldUseAppleScript = isBrowser && preferAppleScriptAPI

        return systemUtility.textStrategySet(
            shouldUseAppleScript: shouldUseAppleScript,
            enableCompatibilityMode: enableCompatibilityMode,
            isSupportedAX: isSupportedAX
        )
    }

    /// Process automatic text selection based on user settings and return updated text field info
    /// - Parameter textFieldInfo: Information about the current text field
    /// - Returns: Updated TextFieldInfo after processing auto-selection, or nil if processing fails
    private func processAutoTextSelection(for textFieldInfo: TextFieldInfo) async -> TextFieldInfo? {
        let autoSelectEnabled = Defaults[.autoSelectAllTextFieldText]
        let selectedText = textFieldInfo.selectedText?.trim() ?? ""

        guard autoSelectEnabled, selectedText.isEmpty else {
            return textFieldInfo
        }

        let textStrategy = textStrategySet(for: textFieldInfo)
        await systemUtility.selectAll(using: textStrategy)

        logInfo("Auto-selected all text content in field")

        return await systemUtility.getFocusedTextFieldInfo()
    }

    /// Prepare translation request from text field information
    /// - Parameters:
    ///   - textFieldInfo: Information about the current text field
    ///   - type: The type of processing (translate or polish)
    /// - Returns: A configured TranslationRequest or nil if preparation fails
    private func prepareTranslationRequest(
        queryText: String,
        type: ProcessingType
    ) async
        -> TranslationRequest? {
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

    /// Replace text with streaming data
    private func replaceTextWithStream(
        _ contentStream: AsyncThrowingStream<String, Error>,
        textFieldInfo: TextFieldInfo
    ) async {
        logInfo("Replacing text with streaming content")

        // For avoding polluting user pasteboard content, we need to save and restore it when AX is not supported.
        let pasteboard = NSPasteboard.general
        var snapshotItems: [NSPasteboardItem]?

        let isSupportedAX = textFieldInfo.isSupportedAXElement
        if !isSupportedAX {
            snapshotItems = await pasteboard.backupItems()
        }

        do {
            let textStrategy = textStrategySet(for: textFieldInfo)

            /**
             - Note:
             For GitHub web text area, if select all and insert empty string,
             it will clear the text area and lose focus.
             So we do not insert empty string.
             */

            var reuslt = ""
            for try await content in contentStream where !content.isEmpty {
                //                logInfo("Received streaming content chunk: \(content.prettyJSONString)")

                reuslt += content
                await systemUtility.insertText(content, using: textStrategy)
            }
            logInfo("Final replacement result: \(reuslt.prettyJSONString)")
        } catch {
            logError("Streaming replacement failed: \(error)")
        }

        if let snapshotItems, !isSupportedAX {
            await pasteboard.restoreItems(snapshotItems)
        }
    }
}
