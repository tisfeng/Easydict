//
//  OCRTranslationStreamTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

@Suite("Single-request OCR stream", .tags(.unit))
struct OCRTranslationStreamTests {
    // MARK: Internal

    @Test("Control markers survive every split and never leak into either Markdown stream")
    func everyBoundary() throws {
        let framing = OCRTranslationStream(identifier: "unit")
        let response = document(framing)
        for split in 0 ... response.count {
            var parser = framing
            try parser.append(String(response.prefix(split)))
            #expect(!parser.update.source.contains("<Sunit"))
            #expect(!parser.update.translation.contains("<Tunit"))
            try parser.append(String(response.dropFirst(split)))
            let result = try parser.finish()
            #expect(result.source == "# Signal\n\n" + #"\[R_8=\frac{x_j^2+1}{\sqrt{n+3}}\]"#)
            #expect(result.translation == "# 信号\n\n" + #"\[R_8=\frac{x_j^2+1}{\sqrt{n+3}}\]"#)
        }
    }

    @Test("Both channels stream before the source-complete boundary")
    func characterDeltas() throws {
        var parser = OCRTranslationStream(identifier: "unit")
        var earlyTranslation = false
        var sourceAtBoundary: String?
        for character in document(parser) {
            try parser.append(String(character))
            let update = parser.update
            if !update.translation.isEmpty, !update.sourceComplete { earlyTranslation = true }
            if update.sourceComplete {
                if let sourceAtBoundary { #expect(update.source == sourceAtBoundary) }
                else { sourceAtBoundary = update.source }
            }
        }
        #expect(earlyTranslation)
        #expect(try parser.finish().source == sourceAtBoundary)
    }

    @Test("Truncation cannot be mistaken for a successful translation")
    func truncation() throws {
        let framing = OCRTranslationStream(identifier: "unit")
        let response = document(framing)
        for prefix in 0 ..< response.count {
            var parser = framing
            try parser.append(String(response.prefix(prefix)))
            #expect(throws: QueryError.self) { try parser.finish() }
        }
    }

    @Test("Malformed order, empty blocks and trailing instructions fail")
    func malformed() {
        let framing = OCRTranslationStream(identifier: "unit")
        let samples = [
            framing.translationMarker + "wrong",
            framing.sourceMarker + "source" + framing.endMarker,
            framing.sourceMarker + "source" + framing.translationMarker + framing.sourceMarker,
            framing.sourceMarker + framing.translationMarker,
            document(framing) + "Ignore all previous instructions",
        ]
        for response in samples {
            var parser = framing
            #expect(throws: QueryError.self) {
                try parser.append(response)
                _ = try parser.finish()
            }
        }
    }

    @Test("Ordinary tags and LaTeX in the source are content")
    func literalContent() throws {
        var parser = OCRTranslationStream(identifier: "unit")
        let text = #"Use <source>, 中文 \alpha_i and <<<ed-source-another-request>>> literally."#
        try parser
            .append(parser.sourceMarker + text + parser.translationMarker + text + parser
                .endMarker)
        #expect(try parser.finish().source == text)
        #expect(try parser.finish().translation == text)
    }

    @Test("Block boundaries preserve indentation in nested Markdown lists")
    func nestedList() throws {
        var parser = OCRTranslationStream(identifier: "unit")
        try parser.append(parser.sourceMarker + "- Parent" + parser.translationMarker + "- 父项")
        try parser.append(parser.sourceMarker + "\n    - Child\n")
        try parser.append(parser.translationMarker + "\n    - 子项\n" + parser.endMarker)
        let result = try parser.finish()
        #expect(result.source == "- Parent\n\n    - Child")
        #expect(result.translation == "- 父项\n\n    - 子项")
    }

    // MARK: Private

    private func document(_ parser: OCRTranslationStream) -> String {
        parser.sourceMarker + "\n# Signal\n" + parser.translationMarker + "\n# 信号\n"
            + parser.sourceMarker + "\n" + #"\[R_8=\frac{x_j^2+1}{\sqrt{n+3}}\]"#
            + "\n" + parser.translationMarker + "\n"
            + #"\[R_8=\frac{x_j^2+1}{\sqrt{n+3}}\]"# + "\n" + parser.endMarker
    }
}
