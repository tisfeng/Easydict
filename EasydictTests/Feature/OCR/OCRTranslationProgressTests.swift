// Copyright © 2026 izual. All rights reserved.

import Foundation
import Testing

@testable import Easydict

@Suite("Sequential image JSON progress", .tags(.unit))
struct OCRTranslationProgressTests {
    @Test
    func everyCharacterBoundaryKeepsChannelsSeparate() throws {
        let source = #"English \(x_j^2\), a \"quoted\" word, 🌊 and </S15D346> literally."#
        let target = #"中文 \[R_8=\frac{x_j^2+1}{\sqrt{n+3}}\]。"#
        let sourceJSON = String(decoding: try JSONEncoder().encode(source), as: UTF8.self)
        let targetJSON = String(decoding: try JSONEncoder().encode(target), as: UTF8.self)
        let json = "{\"original\":" + sourceJSON + ",\"translation\":" + targetJSON + "}"
        var previous = ""
        for end in 0 ... json.count {
            let progress = OCRTranslationProgress(String(json.prefix(end)))
            #expect(source.hasPrefix(progress.original))
            #expect(progress.original.hasPrefix(previous))
            #expect(target.hasPrefix(progress.translation))
            if progress.originalComplete { #expect(progress.original == source) }
            previous = progress.original
        }
        let final = OCRTranslationProgress(json)
        #expect(final.originalComplete)
        #expect(final.original == source && final.translation == target)
    }

    @Test
    func unfinishedSurrogateAndEscapesStayHidden() {
        for prefix in [#"{"original":"Hi \uD83C"#, #"{"original":"Hi \uD83C\uDF"#, #"{"original":"Hi \"#] {
            let progress = OCRTranslationProgress(prefix)
            #expect(progress.original == "Hi ")
            #expect(!progress.originalComplete)
        }
        let full = OCRTranslationProgress(#"{"original":"Hi \uD83C\uDF0A","translation":"你好"}"#)
        #expect(full.original == "Hi 🌊")
        #expect(full.originalComplete)
    }

    @Test
    func sourceCompletionRequiresClosedFieldAndSeparator() {
        #expect(!OCRTranslationProgress(#"{"original":"Source""#).originalComplete)
        #expect(OCRTranslationProgress(#"{"original":"Source","translation":""#).originalComplete)
        #expect(!OCRTranslationProgress(#"{"original":"   ","translation":""#).originalComplete)
    }

    @Test
    func reversedFieldsRemainSeparate() {
        let result = OCRTranslationProgress(#"{"translation":"译文","original":"Source"}"#)
        #expect(result.original == "Source")
        #expect(result.translation == "译文")
        #expect(result.originalComplete)
    }

    @Test
    func malformedOrUnknownFieldsNeverBecomeSource() {
        for text in ["<S15D346>Oops", #"{"other":"Oops","original":"Source"}"#, #"{"original":123}"#] {
            #expect(OCRTranslationProgress(text).original.isEmpty)
        }
    }
}
