//
//  DeepSeekFormulaImageTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import os
import Testing

@testable import Easydict

@Suite(.serialized, .tags(.requiresLocalEnvironment))
struct DeepSeekFormulaImageTests {
    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key before running this test"))
    func testRecognizesFormulaImage() async throws {
        let service = DeepSeekService()
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let started = Date()
        let measurements = OSAllocatedUnfairLock(initialState: (count: 0, first: Date?.none))
        let response = try await service.ocr(image, from: .english, to: .auto, onDelta: { _ in
            measurements.withLock {
                if $0.first == nil { $0.first = Date() }
                $0.count += 1
            }
        })
        let measured = measurements.withLock { $0 }
        #expect(measured.count >= 1, "Expected real OCR streaming deltas")
        let first = try #require(measured.first).timeIntervalSince(started)
        print("OCR stream timing: first=\(first)s total=\(Date().timeIntervalSince(started))s deltas=\(measured.count)")
        let result = try #require(response)
        let text = result.mergedText
        let compact = text.filter { !$0.isWhitespace && $0 != "{" && $0 != "}" }
        #expect(text.contains("EDLUNA-4736"))
        #expect(text.contains(#"\("#) || text.contains("$"))
        #expect(text.contains(#"\["#) || text.contains("$$"))
        #expect(compact.contains("p_7=53"))
        #expect(compact.contains("R_8="))
        #expect(compact.contains("frac"))
        #expect(compact.contains("x_j^2+1"))
        #expect(compact.contains(#"\sqrt(n+3)"#) || compact.contains(#"\sqrtn+3"#))
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key before running this test"))
    @MainActor
    func testStreamsTranslationAndRendersClosedFormula() async throws {
        let service = DeepSeekService()
        let source = #"""
        The normalized signal is calculated by the following equation.

        \[R_8 = \frac{x_j^2+1}{\sqrt{n+3}}\]

        Here j is the sample index and n is the number of frames. We average neighboring pixels
        before estimating the signal to reduce camera quantization noise. The same normalization
        is then applied to every frame. Preserve the sample index when comparing the temporal
        changes across frames, and retain the equation number when describing the procedure.
        """#
        let label = TranslationResultLabel(frame: NSRect(x: 0, y: 0, width: 600, height: 200))
        let started = Date()
        var first: TimeInterval?
        var updates = 0
        var renderedBeforeCompletion = false
        var finalText = ""
        for try await result in service.translateStream(source, from: .english, to: .simplifiedChinese) {
            let text = result.translatedText ?? ""
            label.text = text
            if !result.isStreamFinished, !text.isEmpty {
                if first == nil { first = Date().timeIntervalSince(started) }
                updates += 1
                label.textStorage?.enumerateAttribute(
                    .attachment,
                    in: NSRange(location: 0, length: label.string.utf16.count)
                ) { value, _, _ in
                    if value is NSTextAttachment { renderedBeforeCompletion = true }
                }
            }
            finalText = text
        }
        #expect(updates > 1, "Translation must arrive before the request finishes")
        #expect(renderedBeforeCompletion, "Closed formulas must render while later translation continues")
        #expect(finalText.contains("frac"))
        let compact = finalText.filter { !$0.isWhitespace && $0 != "{" && $0 != "}" }
        #expect(compact.contains("x_j"))
        print(
            "Translation stream timing: first=\(try #require(first))s total=\(Date().timeIntervalSince(started))s updates=\(updates)"
        )
    }
}
