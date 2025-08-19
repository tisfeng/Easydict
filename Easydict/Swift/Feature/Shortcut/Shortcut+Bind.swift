//
//  Shortcut+Bind.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

// App shortcut binding func
extension Shortcut {
    func clearInput() {
        EZWindowManager.shared().clearInput()
    }

    func clearAll() {
        EZWindowManager.shared().clearAll()
    }

    func shortcutCopy() {
        EZWindowManager.shared().copyQueryText()
    }

    func shortcutCopyFirstResult() {
        EZWindowManager.shared().copyFirstTranslatedText()
    }

    func shortcutFocus() {
        EZWindowManager.shared().focusInputTextView()
    }

    func shortcutPlay() {
        EZWindowManager.shared().playOrStopQueryTextAudio()
    }

    func shortcutRetry() {
        EZWindowManager.shared().rerty()
    }

    func shortcutToggle() {
        EZWindowManager.shared().toggleTranslationLanguages()
    }

    func shortcutPin() {
        EZWindowManager.shared().pin()
    }

    func shortcutHide() {
        EZWindowManager.shared().closeWindowOrExitSreenshot()
    }

    func increaseFontSize() {
        if Configuration.shared.fontSizeIndex < Configuration.shared.fontSizes.count - 1 {
            Configuration.shared.fontSizeIndex += 1
        }
    }

    func decreaseFontSize() {
        if Configuration.shared.fontSizeIndex > 0 {
            Configuration.shared.fontSizeIndex -= 1
        }
    }

    func shortcutGoogle() {
        let window = EZWindowManager.shared().floatingWindow
        window?.titleBar.googleButton.openLink()
    }

    func shortcutEudic() {
        let window = EZWindowManager.shared().floatingWindow
        window?.titleBar.eudicButton.openLink()
    }

    func shortcutAppleDic() {
        let window = EZWindowManager.shared().floatingWindow
        window?.titleBar.appleDictionaryButton.openLink()
    }
}

// global shortcut binding func
extension Shortcut {
    @objc
    func selectTextTranslate() {
        EZWindowManager.shared().selectTextTranslate()
    }

    @objc
    func snipTranslate() {
        EZWindowManager.shared().snipTranslate()
    }

    @objc
    func inputTranslate() {
        EZWindowManager.shared().inputTranslate()
    }

    @objc
    func showMiniFloatingWindow() {
        EZWindowManager.shared().showMiniFloatingWindow()
    }

    @objc
    func silentScreenshotOCR() {
        EZWindowManager.shared().silentScreenshotOCR()
    }

    @objc
    func pasteboardOCR() {
        EZWindowManager.shared().pasteboardOCR()
    }
}
