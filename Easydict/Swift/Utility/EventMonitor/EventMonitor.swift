//
//  EventMonitor.swift
//  Scoco
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Carbon
import Foundation

// MARK: - EZEventMonitor

/// Monitors user input events and provides selected text extraction.
@objc(EZEventMonitor)
@objcMembers
final class EventMonitor: NSObject {
    // MARK: Lifecycle

    private override init() {
        self.eventMonitorEngine = EventMonitorEngine()
        self.eventTapMonitor = EventTapMonitor()
        self.selectionWorkflow = SelectionWorkflow()
        self.triggerEvaluator = TriggerEvaluator()
        self.popButtonController = PopButtonVisibilityController()
        self.appContextProvider = AppContextProvider()
        self.systemUtility = SystemUtility.shared
        super.init()
        configureDependencies()
    }

    // MARK: Internal

    // MARK: Public Types

    typealias SelectedTextBlock = @convention(block) (String) -> ()
    typealias VoidBlock = @convention(block) () -> ()
    typealias PointBlock = @convention(block) (CGPoint) -> ()

    static let shared = EventMonitor()

    // MARK: Public Properties (ObjC visible)

    var selectedText: String = ""
    var actionType: ActionType = .autoSelectQuery
    var selectTextType: EZSelectTextType = .accessibility
    var triggerType: EZTriggerType = []

    var frontmostApplication: NSRunningApplication?
    var browserTabURLString: String?

    var startPoint: CGPoint = .zero
    var endPoint: CGPoint = .zero

    @objc(isSelectedTextEditable) var isSelectedTextEditable: Bool = false

    var selectedTextBlock: SelectedTextBlock?
    var dismissPopButtonBlock: VoidBlock?
    var dismissAllNotPinndFloatingWindowBlock: VoidBlock?
    var doubleCommandBlock: VoidBlock?
    var leftMouseDownBlock: PointBlock?
    var rightMouseDownBlock: PointBlock?

    // MARK: Public API

    /// Fetches selected text using the active strategy pipeline.
    /// - Important: Completion is not guaranteed to be called on main thread.
    func getSelectedTextWithCompletion(_ completion: @escaping (String?) -> ()) {
        selectionWorkflow.getSelectedTextSnapshot { [weak self] snapshot in
            guard let self else {
                completion(snapshot?.text)
                return
            }
            if let snapshot {
                selectTextType = snapshot.selectTextType
                isSelectedTextEditable = snapshot.isEditable
                handleSelectedText(snapshot.text)
            } else {
                isSelectedTextEditable = selectionWorkflow.isSelectedTextEditable
            }
            completion(snapshot?.text)
        }
    }

    /// Async Swift-only convenience.
    func getSelectedText() async -> String? {
        await selectionWorkflow.getSelectedText()
    }

    func addLocalMonitorWithEvent(_ mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> ()) {
        eventMonitorEngine.monitor(type: .local, mask: mask, handler: handler)
    }

    func addGlobalMonitorWithEvent(_ mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> ()) {
        eventMonitorEngine.monitor(type: .global, mask: mask, handler: handler)
    }

    func bothMonitorWithEvent(_ mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> ()) {
        eventMonitorEngine.monitor(type: .both, mask: mask, handler: handler)
    }

    func addBothMonitor(_ isAutoSelectTextEnabled: Bool) {
        let eventMask: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .keyDown,
            .keyUp,
            .flagsChanged,
            .leftMouseDragged,
            .cursorUpdate,
        ]
        let maskWhenAutoSelectTextEnabled: NSEvent.EventTypeMask = [.scrollWheel, .mouseMoved]
        let mask = isAutoSelectTextEnabled ? eventMask.union(maskWhenAutoSelectTextEnabled) : eventMask

        bothMonitorWithEvent(mask) { [weak self] event in
            self?.handleMonitorEvent(event)
        }
    }

    func start() {
        eventMonitorEngine.start()
    }

    func stop() {
        eventMonitorEngine.stop()
        eventTapMonitor.stop()
    }

    /// Monitor local and global events.
    func startMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == kVK_Escape {
                logInfo("escape")
            }
            return event
        }
        addBothMonitor(MyConfiguration.shared.autoSelectText)
    }

    func isAccessibilityEnabled() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isEnabled = AXIsProcessTrustedWithOptions(options)
        logInfo("accessibilityEnabled: \(isEnabled)")
        return isEnabled
    }

    func authorize() {
        logInfo("AuthorizeButton clicked")
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    func updateSelectedTextEditableState() {
        isSelectedTextEditable = systemUtility.isFocusedTextField()
    }

    func frameFromStartPoint(_ startPoint: CGPoint, endPoint: CGPoint) -> CGRect {
        RectHelper.frame(from: startPoint, to: endPoint, expandedRadius: Constants.expandedRadius)
    }

    // MARK: Private

    private enum Constants {
        static let dismissPopButtonDelay: TimeInterval = 0.1
        static let delayGetSelectedText: TimeInterval = 0.1
        static let expandedRadius: CGFloat = 120
    }

    private let eventMonitorEngine: EventMonitorEngine
    private let eventTapMonitor: EventTapMonitor
    private let selectionWorkflow: SelectionWorkflow
    private let triggerEvaluator: TriggerEvaluator
    private let popButtonController: PopButtonVisibilityController
    private let appContextProvider: AppContextProvider
    private let systemUtility: SystemUtility

    private var lastEvent: NSEvent?

    private func configureDependencies() {
        eventMonitorEngine.eventHandler = { [weak self] event in
            self?.handleMonitorEvent(event)
        }

        eventTapMonitor.keyDownHandler = { [weak self] in
            self?.delayDismissPopButton()
        }

        selectionWorkflow.contextProvider = appContextProvider
        selectionWorkflow.systemUtility = systemUtility
        selectionWorkflow.onBrowserURLUpdated = { [weak self] urlString in
            self?.browserTabURLString = urlString
        }

        selectionWorkflow.onStartMonitoringKeyboard = { [weak self] in
            guard MyConfiguration.shared.autoSelectText else { return }
            self?.eventTapMonitor.start()
        }

        triggerEvaluator.onTrigger = { [weak self] trigger in
            self?.triggerType = trigger
        }

        popButtonController.dismissHandler = { [weak self] in
            self?.dismissPopButton()
        }
    }

    private func handleMonitorEvent(_ event: NSEvent) {
        lastEvent = event
        frontmostApplication = appContextProvider.frontmostApplication
        popButtonController.lastEvent = event

        switch event.type {
        case .leftMouseUp:
            EZWindowManager.shared().lastPoint = NSEvent.mouseLocation
            endPoint = NSEvent.mouseLocation
            if triggerEvaluator.checkIfLeftMouseDragged() {
                triggerType = .dragged
                let frontmostTriggerType = appContextProvider.frontmostAppTriggerType(
                    forceGetSelectedTextType: MyConfiguration.shared.forceGetSelectedTextType
                )
                if frontmostTriggerType.contains(triggerType) {
                    autoGetSelectedText()
                }
            }
        case .leftMouseDown:
            triggerEvaluator.updateRecordedEvents(event)
            handleLeftMouseDown(event)
        case .leftMouseDragged:
            triggerEvaluator.updateRecordedEvents(event)
            endPoint = NSEvent.mouseLocation
        case .rightMouseDown:
            rightMouseDownBlock?(NSEvent.mouseLocation)
        case .keyDown:
            EZWindowManager.shared().lastPoint = NSEvent.mouseLocation
            if popButtonController.isPopButtonVisible {
                dismissPopButton()
            }
        case .scrollWheel:
            popButtonController.handleScrollWheel(event)
        case .mouseMoved:
            popButtonController.handleMouseMoved(isMouseInExpandedFrame: isMouseInPopButtonExpandedFrame())
        case .flagsChanged:
            EZWindowManager.shared().lastPoint = NSEvent.mouseLocation
            if event.keyCode == kVK_Command || event.keyCode == kVK_RightCommand {
                triggerEvaluator.updateCommandKeyEvents(event)
                if triggerEvaluator.checkIfDoubleCommandEvents() {
                    dismissPopButton()
                    doubleCommandBlock?()
                }
            }
        default:
            if popButtonController.isPopButtonVisible {
                dismissPopButton()
            }
        }
    }

    private func handleLeftMouseDown(_ event: NSEvent) {
        startPoint = NSEvent.mouseLocation
        leftMouseDownBlock?(startPoint)
        dismissWindowsIfMouseLocationOutsideFloatingWindow()

        frontmostApplication = appContextProvider.frontmostApplication

        let frontmostTriggerType = appContextProvider.frontmostAppTriggerType(
            forceGetSelectedTextType: MyConfiguration.shared.forceGetSelectedTextType
        )

        if event.clickCount == 2 {
            triggerType = .doubleClick
            if frontmostTriggerType.contains(triggerType) {
                delayGetSelectedText(0.2)
            }
        } else if event.clickCount == 3 {
            triggerType = .tripleClick
            if frontmostTriggerType.contains(triggerType) {
                cancelDelayGetSelectedText()
                delayGetSelectedText()
            }
        } else if event.modifierFlags.contains(.shift) {
            triggerType = .shift
            if frontmostTriggerType.contains(triggerType) {
                delayGetSelectedText()
            }
        } else {
            dismissPopButton()
        }
    }

    private func dismissWindowsIfMouseLocationOutsideFloatingWindow() {
        if !checkIfMouseLocation(in: EZWindowManager.shared().floatingWindow) {
            dismissAllNotPinndFloatingWindowBlock?()
        }
    }

    private func checkIfMouseLocation(in window: NSWindow?) -> Bool {
        guard let window else { return false }
        return window.frame.contains(NSEvent.mouseLocation)
    }

    private func autoGetSelectedText() {
        guard enabledAutoSelectText() else { return }
        logInfo("auto get selected text")

        popButtonController.resetScrollState()
        actionType = .autoSelectQuery

        selectionWorkflow.getSelectedTextSnapshot { [weak self] snapshot in
            guard let self else { return }
            popButtonController.isPopButtonVisible = true
            DispatchQueue.main.async {
                if let snapshot {
                    self.selectTextType = snapshot.selectTextType
                    self.isSelectedTextEditable = snapshot.isEditable
                } else {
                    self.isSelectedTextEditable = self.selectionWorkflow.isSelectedTextEditable
                }
                self.handleSelectedText(snapshot?.text)
            }
        }
    }

    private func enabledAutoSelectText() -> Bool {
        let config = MyConfiguration.shared
        let enabled = config.autoSelectText && !config.disabledAutoSelect
        if !enabled {
            logInfo("disabled autoSelectText")
        }
        return enabled
    }

    private func handleSelectedText(_ text: String?) {
        let trimmed = (text ?? "").removeInvisibleChar().trim()
        guard !trimmed.isEmpty else { return }
        selectedText = trimmed
        cancelDismissPopButton()

        // call back on main thread
        DispatchQueue.main.async {
            self.selectedTextBlock?(trimmed)
        }
    }

    @objc
    private func dismissPopButton() {
        if popButtonController.shouldIgnoreDismiss() {
            return
        }
        dismissPopButtonBlock?()
        popButtonController.isPopButtonVisible = false
        eventTapMonitor.stop()
    }

    private func delayDismissPopButton() {
        delayDismissPopButton(delay: Constants.dismissPopButtonDelay)
    }

    private func delayDismissPopButton(delay: TimeInterval) {
        perform(#selector(dismissPopButton), with: nil, afterDelay: delay)
    }

    private func cancelDismissPopButton() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismissPopButton), object: nil)
    }

    private func delayGetSelectedText() {
        perform(#selector(autoGetSelectedTextObjc), with: nil, afterDelay: Constants.delayGetSelectedText)
    }

    private func delayGetSelectedText(_ delay: TimeInterval) {
        perform(#selector(autoGetSelectedTextObjc), with: nil, afterDelay: delay)
    }

    private func cancelDelayGetSelectedText() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(autoGetSelectedTextObjc),
            object: nil
        )
    }

    @objc
    private func autoGetSelectedTextObjc() {
        autoGetSelectedText()
    }

    private func isMouseInPopButtonExpandedFrame() -> Bool {
        let popButtonWindow = EZWindowManager.shared().popButtonWindow
        let popButtonFrame = popButtonWindow.frame
        let centerPoint = CGPoint(
            x: popButtonFrame.origin.x + popButtonFrame.size.width / 2,
            y: popButtonFrame.origin.y + popButtonFrame.size.height / 2
        )
        let mouseLocation = NSEvent.mouseLocation
        return GeometryHelper.isPoint(
            mouseLocation,
            insideCircleWithCenter: centerPoint,
            radius: Constants.expandedRadius
        )
    }
}
