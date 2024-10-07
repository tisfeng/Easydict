//
//  SystemUtility.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/3.
//  Copyright © 2024 izual. All rights reserved.
//

import AXSwift
import AXSwiftExt
import Carbon
import Cocoa
import ObjectiveC.runtime

// MARK: - SystemUtility

@objcMembers
public class SystemUtility: NSObject {
    // MARK: Internal

    //    public class func getSelectedText() -> String? {
    //        getSelectedTextByAXUI() ?? getSelectedTextByMenuActionCopy()
    //            ?? getSelectedTextByShortcutCopy()
    //    }

    /// Get selected text by AXUI
    class func getSelectedTextByAXUI() -> Result<String, AXError> {
        logInfo("Getting selected text via AXUI")

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElementRef: CFTypeRef?

        // Get the currently focused element
        let focusedElementResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )

        guard focusedElementResult == .success,
              let focusedElement = focusedElementRef as! AXUIElement?
        else {
            logError("Failed to get focused element")
            return .failure(focusedElementResult)
        }

        var selectedTextValue: CFTypeRef?

        // Get the selected text
        let selectedTextResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )

        guard selectedTextResult == .success else {
            logError("Failed to get selected text")
            return .failure(selectedTextResult)
        }

        guard let selectedText = selectedTextValue as? String else {
            logError("Selected text is not a string")
            return .failure(.noValue)
        }

        logInfo("Selected text via AXUI: \(selectedText)")
        return .success(selectedText)
    }

    /// Get selected text by menu action copy
    class func getSelectedTextByMenuActionCopy() -> String? {
        var result: String?
        protectPasteboard {
            result = _getSelectedTextByMenuActionCopy()
        }
        return result
    }

    /// Get selected text by shortcut copy
    class func getSelectedTextByShortcutCopy() -> String? {
        logInfo("getSelectedTextByShortcutCopy")

        var result: String?
        let pasteboard = NSPasteboard.general
        let initialChangeCount = pasteboard.changeCount

        pasteboard.onPrivateMode(endDelay: 0) {
            callSystemCopy()

            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                pollTask(every: 0.005, timeout: 0.1) {
                    if hasPasteboardChanged(initialCount: initialChangeCount) {
                        result = getPasteboardString()
                        semaphore.signal()
                        return true
                    }
                    return false
                } timeoutCallback: {
                    print("timeout")
                    semaphore.signal()
                }
            }
            semaphore.wait()
        }

        logInfo("Shortcut copy getSelectedText: \(result ?? "nil")")

        return result
    }

    class func isAccessibilityEnabled() -> Bool {
        checkIsProcessTrusted()
    }

    class func hasPasteboardChanged(initialCount: Int) -> Bool {
        NSPasteboard.general.changeCount != initialCount
    }

    class func getPasteboardString() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    // MARK: Private

    private class func _getSelectedTextByMenuActionCopy() -> String? {
        logInfo("getSelectedTextByMenuActionCopy")

        guard let copyElement = canPerformCopy() else {
            logError("Cannot perform menu action copy")
            return nil
        }

        let pasteboard = NSPasteboard.selected
        let initialChangeCount = pasteboard.changeCount

        do {
            try copyElement.performAction(.press)
            logInfo("Performed action copy")
        } catch {
            logError("Failed to perform action copy: \(error)")
            return nil
        }

        let semaphore = DispatchSemaphore(value: 0)
        var result: String?

        DispatchQueue.global().async {
            pollTask(every: 0.005, timeout: 0.1) {
                if hasPasteboardChanged(initialCount: initialChangeCount) {
                    result = getPasteboardString()
                    semaphore.signal()
                    return true
                }
                return false
            } timeoutCallback: {
                logInfo("pollTask timeout call back")
                semaphore.signal()
            }
        }

        semaphore.wait()

        logInfo("Menu action copy getSelectedText: \(result ?? "nil")")

        return result
    }
}

/// Protect pasteboard, record the last pasteboard content, and restore it after the task is completed.
func protectPasteboard(task: () -> ()) {
    let pasteboard = NSPasteboard.general
    pasteboard.save()
    task()
    pasteboard.restore()
}

// 模拟粘贴
func pastePrivacy(_ text: String) {
    NSPasteboard.general.onPrivateMode {
        copyToClipboard(text)
        callSystemPaste()
    }
}

func callSystemPaste() {
    func keyEvents(forPressAndReleaseVirtualKey virtualKey: Int) -> [CGEvent] {
        let eventSource = CGEventSource(stateID: .privateState)
        return [
            CGEvent(
                keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: true
            )!,
            CGEvent(
                keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: false
            )!,
        ]
    }

    let tapLocation = CGEventTapLocation.cgAnnotatedSessionEventTap
    let events = keyEvents(forPressAndReleaseVirtualKey: 9)

    events.forEach {
        $0.flags = .maskCommand
        $0.post(tap: tapLocation)
    }
}

func callSystemCopy() {
    func keyEvents(forPressAndReleaseVirtualKey virtualKey: Int) -> [CGEvent] {
        let eventSource = CGEventSource(stateID: .privateState)
        eventSource?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents, .permitLocalKeyboardEvents],
            state: .numberOfEventSuppressionStates
        )
        return [
            CGEvent(
                keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: true
            )!,
            CGEvent(
                keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: false
            )!,
        ]
    }

    let tapLocation = CGEventTapLocation.cgAnnotatedSessionEventTap
    let events = keyEvents(forPressAndReleaseVirtualKey: 8)

    events.forEach {
        $0.flags = .maskCommand
        $0.post(tap: tapLocation)
    }
}

func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

private var kArchiveKey: UInt8 = 0

extension NSPasteboard {
    var archive: [NSPasteboardItem]? {
        get {
            objc_getAssociatedObject(self, &kArchiveKey) as? [NSPasteboardItem]
        }
        set {
            objc_setAssociatedObject(self, &kArchiveKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func save() {
        var archive = [NSPasteboardItem]()
        for item in pasteboardItems! {
            let archivedItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    archivedItem.setData(data, forType: type)
                }
            }
            archive.append(archivedItem)
        }
        self.archive = archive
    }

    func restore() {
        clearContents()
        writeObjects(archive ?? [])
    }

    func onPrivateMode(endDelay: TimeInterval = 0.05, _ task: @escaping () -> ()) {
        save()
        task()
        if endDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + endDelay) {
                NSPasteboard.general.restore()
                NSPasteboard.general.archive = nil
            }
        } else {
            NSPasteboard.general.restore()
            NSPasteboard.general.archive = nil
        }
    }
}

// safe copy value
private var kSafeCopyKey = 0
extension NSPasteboard {
    func safeCopy() {}

    var safeCopyValue: [NSPasteboardItem]? {
        get {
            objc_getAssociatedObject(self, &kSafeCopyKey) as? [NSPasteboardItem]
        }
        set {
            objc_setAssociatedObject(self, &kSafeCopyKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func saveToSafeCopyValue() {
        //        self.safeCopyValue = pasteboardItems.copy()
        safeCopyValue = pasteboardItems.copy()
    }
}

// clone
extension [NSPasteboardItem]? {
    func copy() -> [NSPasteboardItem] {
        var copyValue = [NSPasteboardItem]()

        for item in self ?? [] {
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            copyValue.append(newItem)
        }
        let fromSCX = NSPasteboardItem()
        fromSCX.setData(Data(), forType: .fromCopi)
        copyValue.append(fromSCX)

        return copyValue
    }
}

// safe copy plain text value
private var kSafeCopyPlainTextKey = 0
extension NSPasteboard {
    var safeCopyPlainTextValue: String? {
        get {
            objc_getAssociatedObject(self, &kSafeCopyPlainTextKey) as? String
        }
        set {
            objc_setAssociatedObject(
                self, &kSafeCopyPlainTextKey, newValue, .OBJC_ASSOCIATION_RETAIN
            )
            safeCopyChangeCountValue += 1
        }
    }
}

// safe copy changeCount
private var kSafeCopyChangeCountKey = 0
extension NSPasteboard {
    var safeCopyChangeCountValue: Int {
        get {
            objc_getAssociatedObject(self, &kSafeCopyChangeCountKey) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(
                self, &kSafeCopyChangeCountKey, newValue, .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
}

// safe copy plain text value
private var kSelectedTextKey = 0
extension NSPasteboard {
    var selectedTextValue: String? {
        get {
            objc_getAssociatedObject(self, &kSelectedTextKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &kSelectedTextKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

func pollTask(
    every interval: TimeInterval,
    timeout: TimeInterval = 2,
    task: @escaping () -> Bool,
    timeoutCallback: @escaping () -> () = {}
) {
    var elapsedTime: TimeInterval = 0
    Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
        if task() {
            timer.invalidate()
        } else {
            elapsedTime += interval
            if elapsedTime >= timeout {
                timer.invalidate()
                timeoutCallback()
            } else {
                logInfo("Still polling...")
            }
        }
    }

    RunLoop.current.run()
}

func unlistenKeyEvent(_ eventTap: CFMachPort) {
    CGEvent.tapEnable(tap: eventTap, enable: false)
    CFRunLoopStop(CFRunLoopGetCurrent())
}

func listenAndInterceptKeyEvent(events: [CGEventType], handler: CGEventTapCallBack) -> CFMachPort? {
    let eventMask = events.reduce(into: 0) { partialResult, eventType in
        partialResult = partialResult | 1 << eventType.rawValue
    }

    // 创建一个事件监听器，并指定位置为 cghidEventTap
    let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: handler,
        userInfo: nil
    )
    // 启用事件监听器
    if let eventTap {
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }
    return eventTap
}

extension NSPasteboard.PasteboardType {
    static var fromCopi: NSPasteboard.PasteboardType = .init("com.gokoding.Copi")
}

func measureTime(block: () -> ()) {
    let startTime = DispatchTime.now()
    block()
    let endTime = DispatchTime.now()

    let nanoseconds = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let milliseconds = Double(nanoseconds) / 1_000_000

    print("Execution time: \(milliseconds) milliseconds")
}

func copyByService() {
    print("copyByService")
    guard AXSwift.checkIsProcessTrusted() else {
        return
    }
    //    Task {
    if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost),
       let copy = app.findMenuItem(title: "Safe Copy") {
        logInfo("found copy")
        try? copy.performAction(.press)
    }
    //    }
}

func pasteByService() {
    print("pasteByService")
    guard AXSwift.checkIsProcessTrusted() else {
        return
    }
    Task {
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let app = Application(frontmost),
           let paste = app.findMenuItem(title: "Safe Paste") {
            logInfo("found paste")
            try? paste.performAction(.press)
        }
    }
}

func canPerformCopy() -> UIElement? {
    guard AXSwift.checkIsProcessTrusted() else {
        return nil
    }
    if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost) {
        if let copyElement = app.findCopy(), copyElement.isEnabled == true,
           isCopyMenuItem(copyElement) {
            return copyElement
        }
    }

    return nil
}

func isCopyMenuItem(_ element: UIElement) -> Bool {
    guard let title = element.title else {
        return false
    }

    let copyTitles = [
        "Copy",
        "拷贝",
        "复制",
        "拷貝",
        "複製",
    ]

    return copyTitles.contains(title)
}

func canPerformPaste() -> UIElement? {
    guard AXSwift.checkIsProcessTrusted() else {
        return nil
    }

    if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost),
       let paste = app.findMenuItem(title: "Safe Paste") {
        return paste
    }
    return nil
}
