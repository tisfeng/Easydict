//
//  BingLanguageVoice.swift
//  Easydict
//
//  Created by Jerry on 2023-10-14.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

// Docs: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/language-support?tabs=tts

@objc(EZBingLanguageVoice)
class BingLanguageVoice: NSObject {
    // MARK: Lifecycle

    init(lang: String, voiceName: String) {
        self.lang = lang
        self.voiceName = voiceName
    }

    // MARK: Internal

    @objc var lang: String // BCP-47, en-US
    @objc var voiceName: String // en-US-JennyNeural

    @objc
    class func voice(withLanguage language: String, voiceName: String) -> BingLanguageVoice {
        BingLanguageVoice(lang: language, voiceName: voiceName)
    }
}
