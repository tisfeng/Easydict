//
//  Shortcut+Bind.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

// App shortcut binding func
extension Shortcut {
    @objc func clearInput() {
        EZWindowManager.shared().clearInput()
    }

    @objc func clearAll() {
        EZWindowManager.shared().clearAll()
    }

    @objc func shortcutCopy() {
        EZWindowManager.shared().copyQueryText()
    }

    @objc func shortcutCopyFirstResult() {
        EZWindowManager.shared().copyFirstTranslatedText()
    }

    @objc func shortcutFocus() {
        EZWindowManager.shared().focusInputTextView()
    }

    @objc func shortcutPlay() {
        EZWindowManager.shared().playOrStopQueryTextAudio()
    }

    @objc func shortcutRetry() {
        EZWindowManager.shared().rerty()
    }

    @objc func shortcutToggle() {
        EZWindowManager.shared().toggleTranslationLanguages()
    }

    @objc func shortcutPin() {
        EZWindowManager.shared().pin()
    }

    @objc func shortcutHide() {
        EZWindowManager.shared().closeWindowOrExitSreenshot()
    }

    @objc func increaseFontSize() {
        Configuration.shared.fontSizeIndex += 1
    }

    @objc func decreaseFontSize() {
        Configuration.shared.fontSizeIndex -= 1
    }

    @objc func shortcutGoogle() {
        let window = EZWindowManager.shared().floatingWindow
        window?.titleBar.googleButton.openLink()
    }

    @objc func shortcutEudic() {
        let window = EZWindowManager.shared().floatingWindow
        window?.titleBar.eudicButton.openLink()
    }

    @objc func shortcutAppleDic() {
        let window = EZWindowManager.shared().floatingWindow
        window?.titleBar.appleDictionaryButton.openLink()
    }
}

// global shortcut binding func
extension Shortcut {
    @objc func selectTextTranslate() {
        EZWindowManager.shared().selectTextTranslate()
    }

    @objc func snipTranslate() {
        EZWindowManager.shared().snipTranslate()
    }

    @objc func inputTranslate() {
        EZWindowManager.shared().inputTranslate()
    }

    @objc func showMiniFloatingWindow() {
        EZWindowManager.shared().showMiniFloatingWindow()
    }

    @objc func screenshotOCR() {
        EZWindowManager.shared().screenshotOCR()
    }
}
