//
//  AppleSpeechService.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/21.
//  Copyright © 2025 izual. All rights reserved.
//

import AVFoundation
import Foundation

// MARK: - AppleSpeechService

@objc
public class AppleSpeechService: NSObject {
    // MARK: Public

    /// Play text using system speech synthesizer
    @objc
    public func playAudio(
        text: String,
        language: Language,
        completion: @escaping (Error?) -> ()
    )
        -> NSSpeechSynthesizer? {
        let voiceIdentifier = voiceIdentifier(for: language) ?? "com.apple.voice.compact.en-US.Samantha"
        print("Language: \(language), Voice Identifier: \(voiceIdentifier)")
        print("System speak: \(text)")

        let synthesizer = NSSpeechSynthesizer(voice: .init(rawValue: voiceIdentifier))

        // Adjust rate for English
        if language == .english {
            synthesizer?.rate = 150
        }

        synthesizer?.startSpeaking(text)
        completion(nil)

        return synthesizer
    }

    /// Get available voices for language
    @objc
    public func availableVoices(for language: Language) -> [String] {
        let localeIdentifier = localeIdentifier(for: language)
        let availableVoices = NSSpeechSynthesizer.availableVoices

        var matchingVoices: [String] = []

        for voice in availableVoices {
            let attributes = NSSpeechSynthesizer.attributes(forVoice: voice)
            if let voiceLocale = attributes[NSSpeechSynthesizer.VoiceAttributeKey.localeIdentifier]
                as? String,
                voiceLocale == localeIdentifier {
                if let voiceId = attributes[NSSpeechSynthesizer.VoiceAttributeKey.identifier]
                    as? String {
                    matchingVoices.append(voiceId)
                }
            }
        }

        return matchingVoices
    }

    // MARK: Private

    private func voiceIdentifier(for language: Language) -> String? {
        let localeIdentifier = localeIdentifier(for: language)
        let availableVoices = NSSpeechSynthesizer.availableVoices

        var matchingVoices: [(id: String, priority: Int)] = []

        for voice in availableVoices {
            let attributes = NSSpeechSynthesizer.attributes(forVoice: voice)
            if let voiceLocale = attributes[NSSpeechSynthesizer.VoiceAttributeKey.localeIdentifier]
                as? String,
                voiceLocale == localeIdentifier,
                let voiceId = attributes[NSSpeechSynthesizer.VoiceAttributeKey.identifier] as? String {
                // Prefer higher quality voices: premium > enhanced > others (including compact)
                let priority: Int
                if voiceId.contains("premium") {
                    priority = 2
                } else if voiceId.contains("enhanced") {
                    priority = 1
                } else {
                    priority = 0
                }
                matchingVoices.append((id: voiceId, priority: priority))
            }
        }

        return matchingVoices.sorted { $0.priority > $1.priority }.first?.id
    }

    private func localeIdentifier(for language: Language) -> String {
        AppleLanguageMapper.shared.supportedLanguages[language] ?? "en_US"
    }
}
