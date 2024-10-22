//
//  TranslationService.swift
//  AppleTranslation
//
//  Created by tisfeng on 2024/10/10.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI
import Translation

// MARK: - TranslationService

@objcMembers
@available(macOS 15.0, *)
public class TranslationService: NSObject {
    // MARK: Lifecycle

    @MainActor
    public init(
        attachedWindow: NSWindow? = nil,
        configuration: TranslationSession.Configuration? = nil
    ) {
        self.attachedWindow = attachedWindow
        self.configuration = configuration
        super.init()
        setupTranslationView()
    }

    /// Initializer for objc, since objc cannot use Swift TranslationSession.Configuration.
    ///
    /// - Note: If attachedWindow is nil, the translation view will be attached to the translationWindow we created.
    @MainActor
    public convenience init(attachedWindow: NSWindow? = nil) {
        self.init(attachedWindow: attachedWindow, configuration: nil)
    }

    // MARK: Public

    public var enableTranslateSameLanguage = false
    public var configuration: TranslationSession.Configuration?

    /// The window that the translation view is attached to.
    ///
    /// - Note: If attachedWindow is nil, the translation view will be attached to the translationWindow we created.
    public var attachedWindow: NSWindow?

    public var translationView: NSView {
        translationController.view
    }

    /// Translate text with specified source and target languages.
    ///
    /// If no languages are provided, it uses the current configuration.
    public func translate(
        text: String,
        sourceLanguage: Locale.Language? = nil,
        targetLanguage: Locale.Language? = nil
    ) async throws
        -> TranslationSession.Response {
        let source = sourceLanguage ?? configuration?.source
        let target = targetLanguage ?? configuration?.target

        do {
            // Check if the translation is ready for use.
            let isReady = try await translationIsReadyforUse(text: text, from: source, to: target)
            await MainActor.run {
                translationWindow?.alphaValue = isReady ? 0 : 1
            }
        } catch {
            await MainActor.run {
                translationWindow?.level = .floating
            }
        }

        do {
            return try await manager.translate(
                text: text,
                sourceLanguage: source,
                targetLanguage: target
            )
        } catch {
            guard let translationError = error as? TranslationError else { throw error }

            switch translationError {
            case .unsupportedLanguagePairing:
                if source == target, enableTranslateSameLanguage {
                    return TranslationSession.Response(
                        sourceLanguage: source ?? .init(identifier: ""),
                        targetLanguage: target ?? .init(identifier: ""),
                        sourceText: text,
                        targetText: text
                    )
                }

                fallthrough

            default:
                throw error
            }
        }
    }

    /// Translate text with language codes, providing a more flexible api.
    ///
    /// - Parameters
    ///   - sourceLanguageCode: ISO 639 code, such as zh, en, etc.
    ///
    /// - Note: Currently Apple Translate does not support language script, so zh-Hans and zh-Hant is the same as zh.
    public func translate(
        text: String,
        sourceLanguageCode: String,
        targetLanguageCode: String
    ) async throws
        -> String {
        let response = try await translate(
            text: text,
            sourceLanguage: .init(identifier: sourceLanguageCode),
            targetLanguage: .init(identifier: targetLanguageCode)
        )
        return response.targetText
    }

    // MARK: Private

    private let manager = TranslationManager()
    private var translationWindow: NSWindow?

    private lazy var translationController = NSHostingController(
        rootView: TranslationView(manager: manager)
    )

    /// Check if the translation is ready for use.
    private func translationIsReadyforUse(
        text: String, from source: Locale.Language?, to target: Locale.Language?
    ) async throws
        -> Bool {
        let status = try await LanguageAvailability().status(for: text, from: source, to: target)
        return status == .installed
    }

    @MainActor
    private func setupTranslationView() {
        // TranslationView must be added to a window, otherwise it will not work.
        if let attachedWindow {
            let translationView = translationController.view
            attachedWindow.contentView?.addSubview(translationView)
            translationView.isHidden = true
        } else {
            translationWindow = NSWindow(contentViewController: translationController)
            translationWindow?.title = "Translation"
            translationWindow?.setContentSize(CGSize(width: 200, height: 200))
            translationWindow?.makeKeyAndOrderFront(nil)
        }
    }
}

@available(macOS 15.0, *)
extension LanguageAvailability {
    public func status(for text: String, from source: Locale.Language?, to target: Locale.Language?)
        async throws
        -> LanguageAvailability.Status {
        if let source {
            return await status(from: source, to: target)
        }
        return try await status(for: text, to: target)
    }
}
