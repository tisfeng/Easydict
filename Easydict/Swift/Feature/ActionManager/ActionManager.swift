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
        guard let queryText = await systemUtility.getFocusedTextFieldText() else {
            return
        }

        let queryModel = try? await EZDetectManager().detectText(queryText)
        guard let detectedLanguage = queryModel?.detectedLanguage,
              let targetLanguage = queryModel?.queryTargetLanguage
        else {
            logError("Failed to detect target language, skipping \(type) and replace")
            return
        }

        let selectedText = await EZEventMonitor.shared().getSelectedText()
        var request: TranslationRequest

        switch type {
        case .translate:
            request = .init(
                text: queryText,
                sourceLanguage: detectedLanguage.code,
                targetLanguage: targetLanguage.code,
                serviceType: translateService.serviceType().rawValue
            )
            await performServiceQuery(request: request, selectedText: selectedText)
        case .polish:
            request = .init(
                text: queryText,
                sourceLanguage: detectedLanguage.code,
                targetLanguage: targetLanguage.code,
                serviceType: polishService.serviceType().rawValue
            )
            await performServiceQuery(request: request, selectedText: selectedText)
        }
    }

    /// Common method to perform stream translation/polishing and replace text
    private func performServiceQuery(
        request: TranslationRequest,
        selectedText: String?,
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
            var result = ""
            for try await content in contentStream {
                result += content
            }
            await replaceText(result, selectedText: selectedText)
        } catch {
            logError("stream failed: \(error.localizedDescription)")
        }
    }

    /// Replace text based on selection state
    private func replaceText(_ resultText: String, selectedText: String?) async {
        if let selectedText, !selectedText.trim().isEmpty {
            // Has selected text, use copy and paste for replacement
            await SharedUtilities.copyTextAndPaste(resultText)
        } else {
            // No selected text, replace the whole text field content
            systemUtility.replaceFocusedTextFieldText(with: resultText)
        }
    }
}
