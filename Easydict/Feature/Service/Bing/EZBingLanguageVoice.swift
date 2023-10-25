//
//  EZBingLanguageVoice.swift
//  Easydict
//
//  Created by Jerry on 2023-10-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

// Docs: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/language-support?tabs=tts

@objc class EZBingLanguageVoice: NSObject {

    @objc var lang: String // BCP-47, en-US
    @objc var voiceName: String // en-US-JennyNeural
    
    init(lang: String, voiceName: String) {
        self.lang = lang
        self.voiceName = voiceName
    }

    @objc class func voice(withLanguage language: String, voiceName: String) ->
    EZBingLanguageVoice {
        return EZBingLanguageVoice(lang: language, voiceName: voiceName)
    }
}
