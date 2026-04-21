//
//  AppleSpeechServiceTests.swift
//  EasydictTests
//
//  Created by Codex on 2026/3/19.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Unit tests for Apple speech voice selection heuristics.
@Suite("Apple Speech Service", .tags(.apple, .unit))
struct AppleSpeechServiceTests {
    @Test("Prefers premium over enhanced and compact", .tags(.apple, .unit))
    func prefersPremiumVoice() {
        let speechService = AppleSpeechService()
        let voiceIds = [
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Ava",
            "com.apple.voice.premium.en-US.Ava",
        ]

        #expect(
            speechService.preferredVoiceIdentifier(from: voiceIds)
                == "com.apple.voice.premium.en-US.Ava"
        )
    }

    @Test("Prefers enhanced over compact when premium is unavailable", .tags(.apple, .unit))
    func prefersEnhancedVoice() {
        let speechService = AppleSpeechService()
        let voiceIds = [
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Ava",
        ]

        #expect(
            speechService.preferredVoiceIdentifier(from: voiceIds)
                == "com.apple.voice.enhanced.en-US.Ava"
        )
    }

    @Test("Uses compact as fallback over Eloquence", .tags(.apple, .unit))
    func usesCompactBeforeEloquence() {
        let speechService = AppleSpeechService()
        let voiceIds = [
            "com.apple.eloquence.en-US.Eddy",
            "com.apple.voice.compact.en-US.Samantha",
        ]

        #expect(
            speechService.preferredVoiceIdentifier(from: voiceIds)
                == "com.apple.voice.compact.en-US.Samantha"
        )
    }

    @Test("Uses compact as fallback over novelty voices", .tags(.apple, .unit))
    func usesCompactBeforeNoveltyVoice() {
        let speechService = AppleSpeechService()
        let voiceIds = [
            "com.apple.speech.synthesis.voice.Albert",
            "com.apple.voice.compact.zh-CN.Tingting",
        ]

        #expect(
            speechService.preferredVoiceIdentifier(from: voiceIds)
                == "com.apple.voice.compact.zh-CN.Tingting"
        )
    }

    @Test("Falls back to the first regular voice when no preferred quality exists", .tags(.apple, .unit))
    func fallsBackToFirstRegularVoice() {
        let speechService = AppleSpeechService()
        let voiceIds = [
            "com.apple.eloquence.en-US.Eddy",
            "com.apple.speech.synthesis.voice.Albert",
        ]

        #expect(
            speechService.preferredVoiceIdentifier(from: voiceIds)
                == "com.apple.eloquence.en-US.Eddy"
        )
    }

    @Test("Returns nil when no candidates are available", .tags(.apple, .unit))
    func returnsNilForEmptyCandidates() {
        let speechService = AppleSpeechService()

        #expect(speechService.preferredVoiceIdentifier(from: []) == nil)
    }
}
