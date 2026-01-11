//
//  BingLanguageVoice.swift
//  Easydict
//
//  Created by Jerry on 2023-10-14.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

// MARK: - BingLanguageVoice

/// Docs: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/language-support?tabs=tts
struct BingLanguageVoice {
    /// BCP-47 language code, e.g. en-US
    var lang: String
    /// Voice name, e.g. en-US-JennyNeural
    var voiceName: String
}

// MARK: - BingLanguageVoice + LanguageVoices

extension BingLanguageVoice {
    // MARK: - Language Voices Dictionary

    static let languageVoices: [Language: BingLanguageVoice] = [
        .simplifiedChinese: BingLanguageVoice(lang: "zh-CN", voiceName: "zh-CN-XiaoxiaoNeural"),
        .traditionalChinese: BingLanguageVoice(lang: "zh-TW", voiceName: "zh-TW-HsiaoChenNeural"),
        .english: BingLanguageVoice(lang: "en-US", voiceName: "en-US-JennyNeural"),
        .japanese: BingLanguageVoice(lang: "ja-JP", voiceName: "ja-JP-NanamiNeural"),
        .korean: BingLanguageVoice(lang: "ko-KR", voiceName: "ko-KR-SunHiNeural"),
        .french: BingLanguageVoice(lang: "fr-FR", voiceName: "fr-FR-DeniseNeural"),
        .spanish: BingLanguageVoice(lang: "es-ES", voiceName: "es-ES-ElviraNeural"),
        .portuguese: BingLanguageVoice(lang: "pt-PT", voiceName: "pt-PT-RaquelNeural"),
        .italian: BingLanguageVoice(lang: "it-IT", voiceName: "it-IT-ElsaNeural"),
        .german: BingLanguageVoice(lang: "de-DE", voiceName: "de-DE-KatjaNeural"),
        .russian: BingLanguageVoice(lang: "ru-RU", voiceName: "ru-RU-SvetlanaNeural"),
        .arabic: BingLanguageVoice(lang: "ar-EG", voiceName: "ar-EG-SalmaNeural"),
        .swedish: BingLanguageVoice(lang: "sv-SE", voiceName: "sv-SE-HedvigNeural"),
        .romanian: BingLanguageVoice(lang: "ro-RO", voiceName: "ro-RO-AlinaNeural"),
        .thai: BingLanguageVoice(lang: "th-TH", voiceName: "th-TH-PremwadeeNeural"),
        .slovak: BingLanguageVoice(lang: "sk-SK", voiceName: "sk-SK-ViktoriaNeural"),
        .dutch: BingLanguageVoice(lang: "nl-NL", voiceName: "nl-NL-ColetteNeural"),
        .czech: BingLanguageVoice(lang: "cs-CZ", voiceName: "cs-CZ-AntoninNeural"),
        .turkish: BingLanguageVoice(lang: "tr-TR", voiceName: "tr-TR-EmelNeural"),
        .greek: BingLanguageVoice(lang: "el-GR", voiceName: "el-GR-AthinaNeural"),
        .danish: BingLanguageVoice(lang: "da-DK", voiceName: "da-DK-ChristelNeural"),
        .finnish: BingLanguageVoice(lang: "fi-FI", voiceName: "fi-FI-NooraNeural"),
        .polish: BingLanguageVoice(lang: "pl-PL", voiceName: "pl-PL-AgnieszkaNeural"),
        .lithuanian: BingLanguageVoice(lang: "lt-LT", voiceName: "lt-LT-OnaNeural"),
        .latvian: BingLanguageVoice(lang: "lv-LV", voiceName: "lv-LV-EveritaNeural"),
        .ukrainian: BingLanguageVoice(lang: "uk-UA", voiceName: "uk-UA-OstapNeural"),
        .bulgarian: BingLanguageVoice(lang: "bg-BG", voiceName: "bg-BG-KalinaNeural"),
        .indonesian: BingLanguageVoice(lang: "id-ID", voiceName: "id-ID-DamayantiNeural"),
        .malay: BingLanguageVoice(lang: "ms-MY", voiceName: "ms-MY-OsmanNeural"),
        .slovenian: BingLanguageVoice(lang: "sl-SI", voiceName: "sl-SI-PetraNeural"),
        .estonian: BingLanguageVoice(lang: "et-EE", voiceName: "et-EE-AnuNeural"),
        .vietnamese: BingLanguageVoice(lang: "vi-VN", voiceName: "vi-VN-HoaiMyNeural"),
        .persian: BingLanguageVoice(lang: "fa-IR", voiceName: "fa-IR-SimaNeural"),
        .hindi: BingLanguageVoice(lang: "hi-IN", voiceName: "hi-IN-MadhurNeural"),
        .telugu: BingLanguageVoice(lang: "te-IN", voiceName: "te-IN-MohanNeural"),
        .tamil: BingLanguageVoice(lang: "ta-IN", voiceName: "ta-IN-PallaviNeural"),
        .urdu: BingLanguageVoice(lang: "ur-PK", voiceName: "ur-PK-AsadNeural"),
        .filipino: BingLanguageVoice(lang: "fil-PH", voiceName: "fil-PH-AlingNeural"),
        .khmer: BingLanguageVoice(lang: "km-KH", voiceName: "km-KH-PichNeural"),
        .lao: BingLanguageVoice(lang: "lo-LA", voiceName: "lo-LA-AcharaNeural"),
        .bengali: BingLanguageVoice(lang: "bn-IN", voiceName: "bn-IN-AnuNeural"),
        .burmese: BingLanguageVoice(lang: "my-MM", voiceName: "my-MM-ShanNeural"),
        .norwegian: BingLanguageVoice(lang: "nb-NO", voiceName: "nb-NO-PernilleNeural"),
        .serbian: BingLanguageVoice(lang: "sr-SP", voiceName: "sr-SP-LjubicaNeural"),
        .croatian: BingLanguageVoice(lang: "hr-HR", voiceName: "hr-HR-SreckoNeural"),
        .mongolian: BingLanguageVoice(lang: "mn-MN", voiceName: "mn-MN-NarangerelNeural"),
        .hebrew: BingLanguageVoice(lang: "he-IL", voiceName: "he-IL-HilaNeural"),
        .georgian: BingLanguageVoice(lang: "ka-GE", voiceName: "ka-GE-EkaNeural"),
    ]
}
