//
//  SelectionWorkflow.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - SelectionWorkflow

/// Orchestrates strategies for obtaining selected text.
final class SelectionWorkflow {
    // MARK: Internal

    var contextProvider: AppContextProvider?
    var systemUtility: SystemUtility?

    var isSelectedTextEditable: Bool = false

    var onStartMonitoringKeyboard: (() -> ())?
    var onBrowserURLUpdated: ((String?) -> ())?

    func getSelectedTextSnapshot(completion: @escaping (SelectedTextSnapshot?) -> ()) {
        recordSelectTextInfo()
        let frontmostApp = contextProvider?.frontmostApplication
        logInfo("getSelectedText in App: \(String(describing: frontmostApp))")

        isSelectedTextEditable = false
        updateEndPoint()

        guard let systemUtility else {
            completion(nil)
            return
        }

        let isFocusedTextField = systemUtility.isFocusedTextField()
        logInfo("Is focused text field: \(isFocusedTextField ? "YES" : "NO")")

        Task {
            do {
                let text = try await systemUtility.getSelectedText(strategy: .accessibility) ?? ""
                let editable = systemUtility.isFocusedTextField()
                isSelectedTextEditable = editable
                let frontmostBundleID = frontmostApp?.bundleIdentifier ?? ""
                let isBrowser = AppleScriptTask.isBrowserSupportingAppleScript(frontmostBundleID)
                let preferAppleScript = MyConfiguration.shared.preferAppleScriptAPI

                if !text.isEmpty {
                    if MyConfiguration.shared.autoSelectText {
                        onStartMonitoringKeyboard?()
                    }
                    if !isBrowser || !preferAppleScript {
                        completion(
                            .init(
                                text: text,
                                selectTextType: .accessibility,
                                isEditable: editable
                            ))
                        return
                    }
                }

                if contextProvider?.useAccessibilityForFirstTime() == true {
                    if AXIsProcessTrustedWithOptions([
                        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true,
                    ] as CFDictionary) == false {
                        completion(nil)
                        return
                    }
                }

                if isBrowser {
                    await getSelectedTextFromBrowser(
                        bundleID: frontmostBundleID,
                        accessibilityFallback: text,
                        completion: completion
                    )
                    return
                }

                if text.isEmpty {
                    handleForceGetSelectedTextOnAXError(axError: .success, completion: completion)
                    return
                }

                completion(.init(text: text, selectTextType: .accessibility, isEditable: editable))
            } catch let error as NSError {
                let axError = AXError(rawValue: Int32(error.code)) ?? .failure
                handleForceGetSelectedTextOnAXError(axError: axError, completion: completion)
            }
        }
    }

    func getSelectedText(completion: @escaping (String?) -> ()) {
        getSelectedTextSnapshot { snapshot in
            completion(snapshot?.text)
        }
    }

    func getSelectedText() async -> String? {
        await withCheckedContinuation { continuation in
            getSelectedText { text in
                continuation.resume(returning: text)
            }
        }
    }

    // MARK: Private

    private func recordSelectTextInfo() {
        contextProvider?.recordSelectTextInfo { [weak self] urlString in
            self?.onBrowserURLUpdated?(urlString)
        }
    }

    private func updateEndPoint() {
        EventMonitor.shared.endPoint = NSEvent.mouseLocation
    }

    private func getSelectedTextFromBrowser(
        bundleID: String,
        accessibilityFallback: String,
        completion: @escaping (SelectedTextSnapshot?) -> ()
    ) async {
        do {
            let selectedText = try await AppleScriptTask.getSelectedTextFromBrowser(bundleID)
            let trimmed = selectedText?.trim() ?? ""
            if !trimmed.isEmpty {
                let isEditable = systemUtility?.isFocusedTextField() ?? false
                isSelectedTextEditable = isEditable
                completion(.init(text: trimmed, selectTextType: .appleScript, isEditable: isEditable))
                return
            }
            logInfo("AppleScript get selected text is empty, try to use force get selected text for browser")
            tryForceGetSelectedText(completion)
        } catch {
            logError("Failed to get selected text from browser: \(error)")
            if !accessibilityFallback.isEmpty {
                logInfo("Fallback to use Accessibility selected text: \(accessibilityFallback)")
                let isEditable = systemUtility?.isFocusedTextField() ?? false
                isSelectedTextEditable = isEditable
                completion(.init(
                    text: accessibilityFallback,
                    selectTextType: .accessibility,
                    isEditable: isEditable
                ))
                return
            }
            tryForceGetSelectedText(completion)
        }
    }

    private func handleForceGetSelectedTextOnAXError(
        axError: AXError,
        completion: @escaping (SelectedTextSnapshot?) -> ()
    ) {
        if shouldForceGetSelectedText(axError: axError) {
            tryForceGetSelectedText(completion)
        } else {
            completion(nil)
        }
    }

    private func tryForceGetSelectedText(_ completion: @escaping (SelectedTextSnapshot?) -> ()) {
        if isFrontmostAppSelf() {
            logInfo("Frontmost app is Easydict, skip force get selected text")
            completion(nil)
            return
        }

        let enableForce = MyConfiguration.shared.enableForceGetSelectedText
        logInfo("Enable force get selected text: \(enableForce ? "YES" : "NO")")
        guard enableForce else {
            completion(nil)
            return
        }

        logInfo("Use force get selected text")

        if MyConfiguration.shared.forceGetSelectedTextType == .menuBarActionCopy {
            getSelectedTextByMenuBarActionCopyFirst(completion)
        } else {
            getSelectedTextBySimulatedKeyFirst(completion)
        }
    }

    private func getSelectedTextBySimulatedKey(_ completion: @escaping (SelectedTextSnapshot?) -> ()) {
        logInfo("Get selected text by simulated key.")

        guard let contextProvider else {
            completion(nil)
            return
        }

        let frontmostTriggerType = contextProvider.frontmostAppTriggerType(
            forceGetSelectedTextType: .simulatedShortcutCopy
        )

        if !frontmostTriggerType.contains(EventMonitor.shared.triggerType) {
            logInfo(
                "Frontmost app trigger type does not contain current trigger type: \(EventMonitor.shared.triggerType)"
            )
            completion(nil)
            return
        }

        Task {
            do {
                let selectedText = try await systemUtility?.getSelectedText(strategy: .shortcut)
                logInfo("Get selected text by simulated key success: \(selectedText ?? "")")
                let isEditable = systemUtility?.isFocusedTextField() ?? false
                isSelectedTextEditable = isEditable
                completion(.init(
                    text: selectedText,
                    selectTextType: .simulatedKey,
                    isEditable: isEditable
                ))
            } catch {
                completion(nil)
            }
        }
    }

    private func getSelectedTextByMenuBarActionCopy(
        _ completion: @escaping (String?, Error?) -> ()
    ) {
        logInfo("Get selected text by menu bar action copy")
        Task {
            do {
                let selectedText = try await systemUtility?.getSelectedText(strategy: .menuAction)
                completion(selectedText ?? nil, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func getSelectedTextBySimulatedKeyFirst(_ completion: @escaping (SelectedTextSnapshot?) -> ()) {
        logInfo("Get selected text by simulated key first")
        getSelectedTextBySimulatedKey { [weak self] snapshot in
            guard let self else { return }
            if let text = snapshot?.text, !text.isEmpty {
                completion(snapshot)
                return
            }
            logError("Get selected text by simulated key is empty, try to use menu bar action copy")
            getSelectedTextByMenuBarActionCopy { text, _ in
                guard let text, !text.isEmpty else {
                    completion(nil)
                    return
                }
                let isEditable = self.systemUtility?.isFocusedTextField() ?? false
                self.isSelectedTextEditable = isEditable
                completion(.init(
                    text: text,
                    selectTextType: .menuBarActionCopy,
                    isEditable: isEditable
                ))
            }
        }
    }

    private func getSelectedTextByMenuBarActionCopyFirst(_ completion: @escaping (SelectedTextSnapshot?) -> ()) {
        logInfo("Get selected text by menu bar action copy first")

        guard let contextProvider else {
            completion(nil)
            return
        }

        let frontmostTriggerType = contextProvider.frontmostAppTriggerType(
            forceGetSelectedTextType: .menuBarActionCopy
        )

        if !frontmostTriggerType.contains(EventMonitor.shared.triggerType) {
            logInfo(
                "Frontmost app trigger type does not contain current trigger type: \(EventMonitor.shared.triggerType)"
            )
            completion(nil)
            return
        }

        getSelectedTextByMenuBarActionCopy { [weak self] text, error in
            guard let self else { return }
            let trimmed = text?.trim() ?? ""
            if !trimmed.isEmpty {
                logInfo("Get selected text by menu bar action copy success: \(trimmed)")
                let isEditable = systemUtility?.isFocusedTextField() ?? false
                isSelectedTextEditable = isEditable
                completion(.init(
                    text: trimmed,
                    selectTextType: .menuBarActionCopy,
                    isEditable: isEditable
                ))
                return
            }

            if let error {
                logError("Failed to get selected text by menu bar action copy: \(error)")
            }

            if systemUtility?.hasEnabledCopyMenuItem() == false {
                logError("Has no enabled copy menu item, try to use simulated key to get selected text")
                getSelectedTextBySimulatedKey(completion)
            } else {
                logError(
                    "Get selected text by menu bar action copy is empty, and app has copy menu item, return empty text"
                )
                completion(nil)
            }
        }
    }

    private func shouldForceGetSelectedText(axError: AXError) -> Bool {
        let enableForce = MyConfiguration.shared.enableForceGetSelectedText
        logInfo("Enable force get selected text: \(enableForce ? "YES" : "NO")")
        guard enableForce else { return false }

        let application = contextProvider?.frontmostApplication
        let bundleID = application?.bundleIdentifier ?? ""
        if isFrontmostAppSelf() {
            logInfo("Frontmost app is Easydict, skip force get selected text")
            return false
        }

        if axError == .noValue {
            logInfo("error: kAXErrorNoValue, unsupported Accessibility App: \(String(describing: application))")
            logError("This error type allow force get selected text")
            return true
        }

        let allowedAppErrorDict: [AXError: [String]] = [
            .success: [
                "com.microsoft.VSCode",
                "com.jetbrains.intellij.ce",
                "com.foxitsoftware.FoxitReaderLite",
                "com.foxit-software.Foxit.PDF.Reader",
                "com.foxit-software.Foxit.PDF.Editor",
                "com.apple.iBooksX",
            ],
            .attributeUnsupported: [
                "com.sublimetext.4",
                "com.microsoft.Word",
                "com.microsoft.Powerpoint",
                AppBundleIDs.weChat,
                "com.readdle.PDFExpert-Mac",
                "org.zotero.zotero",
                "com.apple.iWork.Pages",
                "com.apple.iWork.Keynote",
                "com.apple.iWork.Numbers",
                "com.apple.freeform",
                "org.mozilla.firefox",
                "com.openai.chat",
            ],
            .failure: [
                "com.apple.dt.Xcode",
            ],
        ]

        if let bundleIDs = allowedAppErrorDict[axError], bundleIDs.contains(bundleID) {
            logError("Allow force get selected text: \(axError), \(String(describing: application))")
            return true
        }

        if EventMonitor.shared.actionType == .shortcutQuery {
            logInfo("Fallback to use force get selected text for shortcut query")
            logError(
                "Maybe need to add it to allowed app error list dict: \(axError), \(String(describing: application))"
            )
            return true
        }

        logInfo("After check axError: \(axError), not use force get selected text: \(String(describing: application))")
        return false
    }

    private func isFrontmostAppSelf() -> Bool {
        let easydictBundleID = Bundle.main.bundleIdentifier ?? ""
        let frontmostBundleID = contextProvider?.frontmostApplication?.bundleIdentifier ?? ""
        return !easydictBundleID.isEmpty && easydictBundleID == frontmostBundleID
    }
}
