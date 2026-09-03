//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import AXSwift
import Defaults
import Foundation
import SelectedTextKit

// MARK: - TextInsertionConfidence

/// Expresses how strongly the target application confirmed one insertion attempt.
enum TextInsertionConfidence: Int, Comparable {
    case dispatchedUnverified
    case acceptedByTargetAPI
    case verifiedMutation

    // MARK: Internal

    var logValue: String {
        switch self {
        case .dispatchedUnverified:
            "dispatched_unverified"
        case .acceptedByTargetAPI:
            "accepted_by_target_api"
        case .verifiedMutation:
            "verified_mutation"
        }
    }

    static func < (lhs: TextInsertionConfidence, rhs: TextInsertionConfidence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - TextInsertionReceipt

/// Records the strategy and confirmation level for one successfully dispatched chunk.
struct TextInsertionReceipt: Equatable {
    let strategy: TextStrategy
    let confidence: TextInsertionConfidence
    let characterCount: Int
}

// MARK: - TextInsertionError

/// Describes local insertion failures without retaining selected or generated text.
enum TextInsertionError: Error, Equatable {
    case noAvailableStrategy
    case permissionDenied
    case targetChanged
    case targetUnavailable
    case apiRejected(TextStrategy)
    case dispatchFailed(TextStrategy)
    case verificationFailed(TextStrategy)

    // MARK: Internal

    var logCategory: String {
        switch self {
        case .noAvailableStrategy:
            "no_strategy"
        case .permissionDenied:
            "permission_denied"
        case .targetChanged:
            "target_changed"
        case .targetUnavailable:
            "target_unavailable"
        case let .apiRejected(strategy):
            "api_rejected_\(strategy.rawValue)"
        case let .dispatchFailed(strategy):
            "dispatch_failed_\(strategy.rawValue)"
        case let .verificationFailed(strategy):
            "verification_failed_\(strategy.rawValue)"
        }
    }
}

// MARK: - TextInsertionSession

/// Inserts streaming chunks into the application that was frontmost when the action began.
@MainActor
protocol TextInsertionSession: AnyObject {
    func insert(_ text: String) async throws -> TextInsertionReceipt
}

// MARK: - TextInsertionTarget

/// Captures the process identity used to prevent a delayed stream from writing into another app.
struct TextInsertionTarget: Equatable {
    let processIdentifier: pid_t
    let bundleIdentifier: String

    /// Validates a supplied process identity at a stable, testable boundary.
    func validate(processIdentifier currentProcessIdentifier: pid_t?) throws {
        guard let currentProcessIdentifier else {
            throw TextInsertionError.targetUnavailable
        }
        guard currentProcessIdentifier == processIdentifier else {
            throw TextInsertionError.targetChanged
        }
    }

    /// Checks the actual current frontmost process immediately before a write.
    @MainActor
    func validateCurrentApplication() throws {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            throw TextInsertionError.targetUnavailable
        }
        try validate(processIdentifier: application.processIdentifier)
        guard (application.bundleIdentifier ?? "") == bundleIdentifier else {
            throw TextInsertionError.targetChanged
        }
    }
}

// MARK: - SystemTextInsertionSession

/// AppKit-backed insertion session that owns one target and its captured Accessibility element.
@MainActor
final class SystemTextInsertionSession: TextInsertionSession {
    // MARK: Lifecycle

    init(
        systemUtility: SystemUtility,
        target: TextInsertionTarget,
        strategies: [TextStrategy],
        focusedElement: UIElement?,
        contextElement: UIElement?,
        browserTabURL: String?
    ) {
        self.systemUtility = systemUtility
        self.target = target
        self.strategies = strategies
        self.focusedElement = focusedElement
        self.contextElement = contextElement
        self.browserTabURL = browserTabURL
    }

    // MARK: Internal

    func insert(_ text: String) async throws -> TextInsertionReceipt {
        try validateBoundTarget()

        if strategies.contains(.appleScript), let browserTabURL {
            do {
                try await systemUtility.insertTextByAppleScript(
                    text,
                    bundleID: target.bundleIdentifier,
                    expectedTabURL: browserTabURL
                )
                return receipt(
                    strategy: .appleScript,
                    confidence: .acceptedByTargetAPI,
                    text: text
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as TextInsertionError {
                if error == .targetChanged || error == .targetUnavailable {
                    throw error
                }
                logError(
                    "Text insertion strategy failed strategy=apple_script category=api_rejected"
                )
            } catch {
                logError(
                    "Text insertion strategy failed strategy=apple_script category=api_rejected"
                )
            }
        }

        try validateBoundTarget()
        return try await insertUsingNonBrowserStrategy(text)
    }

    // MARK: Private

    private let systemUtility: SystemUtility
    private let target: TextInsertionTarget
    private let strategies: [TextStrategy]
    private let focusedElement: UIElement?
    private let contextElement: UIElement?
    private let browserTabURL: String?

    private func insertUsingNonBrowserStrategy(_ text: String) async throws
        -> TextInsertionReceipt {
        if strategies.contains(.menuAction) {
            do {
                try await systemUtility.insertTextByMenuAction(text) {
                    try self.validateBoundTarget()
                }
                return receipt(
                    strategy: .menuAction,
                    confidence: .dispatchedUnverified,
                    text: text
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as TextInsertionError {
                if error == .targetChanged || error == .targetUnavailable {
                    throw error
                }
                logError(
                    "Text insertion strategy failed strategy=menu_action category=dispatch_failed"
                )
            } catch {
                logError(
                    "Text insertion strategy failed strategy=menu_action category=dispatch_failed"
                )
            }
        }

        if strategies.contains(.shortcut) {
            try await systemUtility.insertTextByShortcut(text) {
                try self.validateBoundTarget()
            }
            return receipt(
                strategy: .shortcut,
                confidence: .dispatchedUnverified,
                text: text
            )
        }

        if strategies.contains(.accessibility), let focusedElement {
            do {
                try validateBoundTarget()
                let confidence = try systemUtility.insertTextByAX(
                    text,
                    element: focusedElement
                )
                return receipt(strategy: .accessibility, confidence: confidence, text: text)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as TextInsertionError {
                throw error
            } catch {
                if !UIElement.isProcessTrusted() {
                    throw TextInsertionError.permissionDenied
                }
                throw TextInsertionError.apiRejected(.accessibility)
            }
        }

        if !UIElement.isProcessTrusted() {
            throw TextInsertionError.permissionDenied
        }
        throw TextInsertionError.noAvailableStrategy
    }

    /// Verifies both the process identity and the captured focused Accessibility context.
    private func validateBoundTarget() throws {
        try Task.checkCancellation()
        try target.validateCurrentApplication()
        guard let contextElement else { return }

        guard let applicationElement = systemUtility.frontmostAppElement else {
            throw TextInsertionError.targetUnavailable
        }

        do {
            guard let currentElement = try applicationElement.focusedUIElement(),
                  CFEqual(contextElement.element, currentElement.element)
            else {
                throw TextInsertionError.targetChanged
            }
        } catch let error as TextInsertionError {
            throw error
        } catch {
            throw TextInsertionError.targetChanged
        }
    }

    private func receipt(
        strategy: TextStrategy,
        confidence: TextInsertionConfidence,
        text: String
    )
        -> TextInsertionReceipt {
        TextInsertionReceipt(
            strategy: strategy,
            confidence: confidence,
            characterCount: text.count
        )
    }
}

// MARK: - SystemUtility

@objc(EZSystemUtility)
class SystemUtility: NSObject {
    // MARK: Internal

    @objc static let shared = SystemUtility()

    let axManager = AXManager.shared
    let selectedTextManager = SelectedTextManager.shared

    /// Bundle identifiers of apps that should use the "Paste menu item enabled" heuristic
    /// when the focused text field element cannot be reliably determined via Accessibility APIs.
    var bundleIDAllowListForPasteMenuCheck: Set<String> = [AppBundleIDs.weChat]

    /// Bundle identifiers of apps allowed to bypass focused element checks for selectable text.
    /// Useful when focused UI element cannot be reliably determined via Accessibility APIs,
    /// e.g. Sublime Text's focused element role is AXWindow, but its selection can still be
    /// obtained by force-get (simulated copy).
    var bundleIDAllowListForSelectableTextCheck: Set<String> = [
        AppBundleIDs.weChat,
        "com.sublimetext.4",
    ]

    /// Get selected text from current focused application.
    ///
    /// - Note: Just a wrapper of EZEventMonitor's getSelectedText method.
    func getSelectedText() async -> String? {
        await EventMonitor.shared.getSelectedText()
    }

    /// Select all text using the specified operation set.
    ///
    /// TODO: Refactor the nested function to avoid code duplication with insertText
    func selectAll(using strategies: [TextStrategy]) async {
        logInfo("Select all using operation set: \(strategies)")

        func selectAllInNonBrowser() async {
            if strategies.contains(.menuAction) {
                await selectAllByMenuAction()
            } else if strategies.contains(.shortcut) {
                await selectAllByShortcut()
            } else if strategies.contains(.accessibility) {
                selectAllByAX()
            }
        }

        if strategies.contains(.appleScript) {
            do {
                try await selectAllByAppleScript()
            } catch {
                logError(
                    "Select all failed strategy=apple_script category=api_rejected; " +
                        "falling back"
                )
                await selectAllInNonBrowser()
            }
        } else {
            await selectAllInNonBrowser()
        }
    }

    /// Insert text using the specified operation set and report the target's confirmation level.
    ///
    /// - Parameters:
    ///   - text: The text to insert
    ///   - strategies: The text strategies to use, in order of preference
    ///
    /// - Important: This function may be called many times in streaming mode,
    ///              so we pass the strategies array each time to avoid recomputation.
    @MainActor
    func insertText(_ text: String, using strategies: [TextStrategy]) async throws
        -> TextInsertionReceipt {
        let session = try await makeTextInsertionSession(using: strategies)
        return try await session.insert(text)
    }

    /// Insert text into the currently focused text field.
    ///
    /// - Note: This method determines the best strategy to use based on the current context
    ///         and user preferences. It may use AppleScript, Accessibility APIs, menu actions,
    ///         or keyboard shortcuts as needed.
    @objc
    @MainActor
    func insertText(_ text: String) async {
        do {
            let strategies = await textStrategies()
            _ = try await insertText(text, using: strategies)
        } catch let error as TextInsertionError {
            logError("Text insertion failed category=\(error.logCategory)")
        } catch {
            logError("Text insertion failed category=unknown")
        }
    }

    // MARK: - Text Strategies

    /// Get text strategies for current focused element
    func textStrategies(enableSelectAll: Bool = false) async -> [TextStrategy] {
        let elementInfo = await focusedElementInfo(enableSelectAll: enableSelectAll)
        return textStrategies(for: elementInfo)
    }

    /// Determine the appropriate text strategy set based on the focused element info and user settings
    func textStrategies(
        for elementInfo: FocusedElementInfo,
        targetBundleID: String? = nil
    )
        -> [TextStrategy] {
        let isSupportedAX = elementInfo.isSupportedAXElement
        let enableCompatibilityMode = Defaults[.enableCompatibilityReplace]

        let bundleID = targetBundleID ?? frontmostAppBundleID
        let isBrowser = AppleScriptTask.isBrowserSupportingAppleScript(bundleID)
        let preferAppleScriptAPI = Defaults[.preferAppleScriptAPI]
        let shouldUseAppleScript = isBrowser && preferAppleScriptAPI

        return textStrategies(
            shouldUseAppleScript: shouldUseAppleScript,
            enableCompatibilityMode: enableCompatibilityMode,
            isSupportedAX: isSupportedAX
        )
    }

    /// Captures the process identity before any asynchronous selected-text lookup begins.
    @MainActor
    func captureTextInsertionTarget() throws -> TextInsertionTarget {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            throw TextInsertionError.targetUnavailable
        }

        return TextInsertionTarget(
            processIdentifier: application.processIdentifier,
            bundleIdentifier: application.bundleIdentifier ?? ""
        )
    }

    /// Captures the available insertion mechanisms and browser context before a provider starts.
    @MainActor
    func makeTextInsertionSession(
        for elementInfo: FocusedElementInfo,
        target: TextInsertionTarget
    ) async throws
        -> any TextInsertionSession {
        try target.validateCurrentApplication()
        let strategies = textStrategies(
            for: elementInfo,
            targetBundleID: target.bundleIdentifier
        )
        return try await makeTextInsertionSession(
            target: target,
            strategies: strategies,
            contextElement: elementInfo.accessibilityElement
        )
    }

    // MARK: - Focused Element Info

    func focusedElementInfo(enableSelectAll: Bool = false) async -> FocusedElementInfo {
        var elementInfo = await fetchFocusedElementInfo()
        logInfo("Focused Element Info: \(elementInfo)")

        let selectedText = elementInfo.selectedText ?? ""

        // Only auto-select all text option when enabled and no selected text
        if enableSelectAll, selectedText.isEmpty {
            elementInfo = await processAutoAllTextSelection(for: elementInfo)
            logInfo("Element Info after Auto-Selection: \(elementInfo)")
        }
        return elementInfo
    }

    // MARK: Private

    @MainActor
    private func makeTextInsertionSession(using strategies: [TextStrategy]) async throws
        -> any TextInsertionSession {
        let target = try captureTextInsertionTarget()
        let contextElement = try? frontmostAppElement?.focusedUIElement()
        return try await makeTextInsertionSession(
            target: target,
            strategies: strategies,
            contextElement: contextElement
        )
    }

    @MainActor
    private func makeTextInsertionSession(
        target: TextInsertionTarget,
        strategies: [TextStrategy],
        contextElement: UIElement?
    ) async throws
        -> any TextInsertionSession {
        var availableStrategies = strategies
        var focusedElement: UIElement?
        var browserTabURL: String?

        if availableStrategies.contains(.accessibility) {
            focusedElement = try? focusedTextFieldElement()
            if let contextElement, let focusedElement,
               !CFEqual(contextElement.element, focusedElement.element) {
                throw TextInsertionError.targetChanged
            }
            if focusedElement == nil {
                availableStrategies.removeAll { $0 == .accessibility }
            }
        }

        if availableStrategies.contains(.appleScript) {
            do {
                browserTabURL = try await AppleScriptTask.getCurrentTabURLFromBrowser(
                    target.bundleIdentifier
                )
                try target.validateCurrentApplication()
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as TextInsertionError {
                throw error
            } catch {
                logError(
                    "Text insertion context unavailable strategy=apple_script " +
                        "category=apple_script"
                )
            }

            if browserTabURL == nil {
                availableStrategies.removeAll { $0 == .appleScript }
            }
        }

        guard !availableStrategies.isEmpty else {
            if !UIElement.isProcessTrusted() {
                throw TextInsertionError.permissionDenied
            }
            throw TextInsertionError.noAvailableStrategy
        }

        return SystemTextInsertionSession(
            systemUtility: self,
            target: target,
            strategies: availableStrategies,
            focusedElement: focusedElement,
            contextElement: contextElement,
            browserTabURL: browserTabURL
        )
    }

    /// Get text strategies based on user preferences and system capabilities
    private func textStrategies(
        shouldUseAppleScript: Bool,
        enableCompatibilityMode: Bool,
        isSupportedAX: Bool
    )
        -> [TextStrategy] {
        var strategies: [TextStrategy] = []
        if shouldUseAppleScript {
            strategies.append(.appleScript)
        }
        if isSupportedAX {
            strategies.append(.accessibility)
        }
        if enableCompatibilityMode {
            strategies.append(.menuAction)
            strategies.append(.shortcut)
        }
        return strategies
    }

    /// Fetch comprehensive information from current focused element
    ///
    /// - Returns: FocusedElementInfo containing text, range, and selected text. Returns empty info when unavailable.
    private func fetchFocusedElementInfo() async -> FocusedElementInfo {
        do {
            guard let element = try frontmostAppElement?.focusedUIElement() else {
                logInfo("No focused UI element found")
                return .empty
            }

            let roleValue = try? element.roleValue()
            let fullText: String? = try? element.value()
            let selectedRange: CFRange? = try? element.selectedTextRange()
            let selectedText = await getSelectedText()

            return FocusedElementInfo(
                fullText: fullText,
                selectedRange: selectedRange,
                selectedText: selectedText,
                roleValue: roleValue,
                accessibilityElement: element
            )
        } catch {
            logError("Get focused element info failed category=accessibility")
            return .empty
        }
    }

    /// Process automatic all text selection based on user settings and return updated element info
    ///
    /// - Parameter elementInfo: Information about the current focused element
    /// - Returns: Updated FocusedElementInfo after processing auto-selection.
    private func processAutoAllTextSelection(for elementInfo: FocusedElementInfo) async
        -> FocusedElementInfo {
        guard elementInfo.isTextInputField else {
            return elementInfo
        }

        let textStrategy = textStrategies(for: elementInfo)
        await selectAll(using: textStrategy)

        logInfo("Auto-selected all text content in field")

        return await fetchFocusedElementInfo()
    }
}
