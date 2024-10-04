//
//  GetSelectedText.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Automator
import Foundation

// 创建一个AppleScript字符串
let script = """
contents of selection
"""

func callAppleScript() {
    // 创建一个NSAppleScript对象
    if let appleScript = NSAppleScript(source: script) {
        var error: NSDictionary?
        // 执行AppleScript
        if let output = appleScript.executeAndReturnError(&error).stringValue {
            print("AppleScript output: \(output)")
        } else if let error = error {
            print("AppleScript error: \(error)")
        }
    } else {
        print("Failed to create NSAppleScript object")
    }
}

func callAppleScript2() {
//    let ascr = "tell application id \"MACS\" to reveal some item in the first Finder window"
    let ascr = "get contents of selection"
//    let ascr = """
//            tell application "System Events"
//                set selectedText to (get contents of selection)
//            end tell
//            return selectedText
//            """
//    let ascr = """
//            tell application "System Events"
//                set selectedText to (get the clipboard)
//            end tell
//            return selectedText
//            """
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: ascr) {
        if let scriptResult = scriptObject
            .executeAndReturnError(&error)
            .stringValue {
            print(scriptResult)
        } else if error != nil {
            print("error: ", error!)
        }
    }
}

import ApplicationServices
import Cocoa

func getSelectedTextByAXUI() -> String? {
    let systemWideElement = AXUIElementCreateSystemWide()

    var selectedTextValue: AnyObject?
    let errorCode = AXUIElementCopyAttributeValue(
        systemWideElement,
        kAXFocusedUIElementAttribute as CFString,
        &selectedTextValue
    )

    if errorCode == .success {
        let selectedTextElement = selectedTextValue as! AXUIElement
        var selectedText: AnyObject?
        let textErrorCode = AXUIElementCopyAttributeValue(
            selectedTextElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        if textErrorCode == .success, let selectedTextString = selectedText as? String {
            return selectedTextString
        } else {
            return nil
        }
    } else {
        return nil
    }
}

func getSelectedTextByCopy() -> String? {
    var result: String?
    let pasteboard = NSPasteboard.general
    pasteboard.onPrivateMode(endDelay: 0) {
        let changeCount = pasteboard.changeCount
        print("changeCount before copy", changeCount)
        callSystemCopy()

        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            pollTask(every: 0.005, timeout: 0.1) {
                if pasteboard.changeCount != changeCount {
                    result = pasteboard.string(forType: .string)
                    print("get result", result)
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
    print("return result", result)
    return result
}

func getSelectedByService() -> String? {
    var result: String?
//    let pasteboard = NSPasteboard.general
    let pasteboard = NSPasteboard.selected

    if let safeCopy = canPerformSelectedText() {
        print("canPerformSelectedText")
        let semaphore = DispatchSemaphore(value: 0)
        let changeCount = pasteboard.changeCount
        print("performSelectedText changeCount \(changeCount)")
        try? safeCopy.performAction(.press)
        print("perform selectedText")

        DispatchQueue.global().async {
            print("Dispatching thread", Thread.current)
            pollTask(every: 0.005, timeout: 0.1) {
                print("Pulling Task thread")
                if pasteboard.changeCount != changeCount {
                    result = pasteboard.string()
                    print("get result", result)
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
    print("return result \(result)")
    return result
}

func getSelectedText() -> String? {
    getSelectedTextByAXUI() ?? getSelectedByService()
//    return getSelectedTextByAXUI() ?? getSelectedByService() ?? getSelectedTextByCopy()
}

func executeAppleScript() {
    let script = """
    tell application "System Events"
        keystroke "c" using command down
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        appleScript.executeAndReturnError(&error)
    }
}
