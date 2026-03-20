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

    // MARK: Internal

    func preferredVoiceIdentifier(from voiceIds: [String]) -> String? {
        var bestVoice: (id: String, priority: Int)?

        for voiceId in voiceIds {
            let priority = voicePriority(for: voiceId)

            if let currentBest = bestVoice {
                if priority > currentBest.priority {
                    bestVoice = (id: voiceId, priority: priority)
                }
            } else {
                bestVoice = (id: voiceId, priority: priority)
            }
        }

        return bestVoice?.id
    }

    func voicePriority(for voiceId: String) -> Int {
        if voiceId.contains("premium") {
            return 3
        }
        if voiceId.contains("enhanced") {
            return 2
        }
        if voiceId.contains("compact") {
            return 1
        }
        return 0
    }

    // MARK: Private

    private func voiceIdentifier(for language: Language) -> String? {
        let localeIdentifier = localeIdentifier(for: language)
        let availableVoices = NSSpeechSynthesizer.availableVoices

        var matchingVoices: [String] = []

        for voice in availableVoices {
            let attributes = NSSpeechSynthesizer.attributes(forVoice: voice)
            if let voiceLocale = attributes[NSSpeechSynthesizer.VoiceAttributeKey.localeIdentifier]
                as? String,
                voiceLocale == localeIdentifier,
                let voiceId = attributes[NSSpeechSynthesizer.VoiceAttributeKey.identifier] as? String {
                matchingVoices.append(voiceId)
            }
        }

        return preferredVoiceIdentifier(from: matchingVoices)
    }

    private func localeIdentifier(for language: Language) -> String {
        AppleLanguageMapper.shared.supportedLanguages[language] ?? "en_US"
    }
}
