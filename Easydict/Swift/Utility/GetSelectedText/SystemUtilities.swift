//
//  SystemUtilities.swift
//  SecureYourClipboard
//
//  Created by lixindong on 2024/4/2.
//

import Foundation
import AppKit
import Carbon
import Cocoa
import AXSwift
import AXSwiftExt

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
            CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: true)!,
            CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: false)!,
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
        eventSource?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents, .permitLocalKeyboardEvents], state: .numberOfEventSuppressionStates)
        return [
            CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: true)!,
            CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(virtualKey), keyDown: false)!,
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

import ObjectiveC.runtime

private var kArchiveKey: UInt8 = 0

extension NSPasteboard {

    var archive: [NSPasteboardItem]? {
        get {
            return objc_getAssociatedObject(self, &kArchiveKey) as? [NSPasteboardItem]
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
    
    func onPrivateMode(endDelay: TimeInterval = 0.05, _ task: @escaping () -> Void) {
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
    func safeCopy() {
        
    }
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
        self.safeCopyValue = pasteboardItems.copy()
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
            objc_setAssociatedObject(self, &kSafeCopyPlainTextKey, newValue, .OBJC_ASSOCIATION_RETAIN)
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
            objc_setAssociatedObject(self, &kSafeCopyChangeCountKey, newValue, .OBJC_ASSOCIATION_RETAIN)
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

func pollTask(every interval: TimeInterval, timeout: TimeInterval = 2, task: @escaping () -> Bool, timeoutCallback: @escaping () -> Void = {}) {
    var elapsedTime: TimeInterval = 0
    let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
        if task() {
            timer.invalidate()
        } else {
            elapsedTime += interval
            if elapsedTime >= timeout {
                timer.invalidate()
                timeoutCallback()
            } else {
                print("Still polling...")
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
    
    // 创建一个事件监听器，并指定位置为cghidEventTap
    let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                     place: .headInsertEventTap,
                                     options: .defaultTap,
                                     eventsOfInterest: CGEventMask(eventMask),
                                     callback: handler, userInfo: nil)
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

func measureTime(block: () -> Void) {
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
        if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost), let copy = app.findMenuItem(title: "Safe Copy") {
            print("found copy")
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
        if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost), let paste = app.findMenuItem(title: "Safe Paste") {
            print("found paste")
            try? paste.performAction(.press)
        }
    }
}

func canPerformSelectedText() -> UIElement? {
    guard AXSwift.checkIsProcessTrusted() else {
        return nil
    }
    if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost), let copy = app.findMenuItem(title: "Process Selected Text") {
        return copy
    }
    return nil
}

func canPerformCopy() -> UIElement? {
    guard AXSwift.checkIsProcessTrusted() else {
        return nil
    }
    if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost), let copy = app.findMenuItem(title: "Safe Copy") {
        return copy
    }
    return nil
}

func canPerformPaste() -> UIElement? {
    guard AXSwift.checkIsProcessTrusted() else {
        return nil
    }
    
    if let frontmost = NSWorkspace.shared.frontmostApplication, let app = Application(frontmost), let paste = app.findMenuItem(title: "Safe Paste") {
        return paste
    }
    return nil
}
