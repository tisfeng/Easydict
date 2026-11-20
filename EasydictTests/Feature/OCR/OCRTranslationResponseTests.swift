//
//  OCRTranslationResponseTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

@Suite("Complete image OCR and translation response", .tags(.unit))
struct OCRTranslationResponseTests {
    @Test("JSON fields keep original and translated Markdown separate, including escaped math")
    func separateFields() throws {
        let original = #"English \(x_j^2\), quoted \"text\" and </S15D346> literally."#
        let translation = #"中文 \(x_j^2\)，保留公式。"#
        let data = try JSONSerialization.data(withJSONObject: ["original": original, "translation": translation])
        let response = try OCRTranslationResponse(response: String(decoding: data, as: UTF8.self))
        #expect(response.original == original)
        #expect(response.translation == translation)
    }

    @Test("Both outputs must exist and be nonempty strings")
    func requiredFields() {
        let invalid = [
            "{}", #"{"original":"text"}"#, #"{"translation":"译文"}"#,
            #"{"original":null,"translation":"译文"}"#,
            #"{"original":[],"translation":"译文"}"#,
            #"{"original":"text","translation":1}"#,
            #"{"original":"  ","translation":"译文"}"#,
            #"{"original":"text","translation":"\n "}"#,
        ]
        for text in invalid {
            #expect(throws: QueryError.self) { _ = try OCRTranslationResponse(response: text) }
        }
    }

    @Test("Only one whole optional JSON fence is accepted")
    func fencedJSON() throws {
        let json = #"{"original":"Source","translation":"译文"}"#
        for fence in ["```json", "```"] {
            let response = try OCRTranslationResponse(response: fence + "\n" + json + "\n```")
            #expect(response.original == "Source")
            #expect(response.translation == "译文")
        }
    }

    @Test("Truncated JSON cannot complete the final pair")
    func truncation() {
        let json = #"{"original":"Source","translation":"译文"}"#
        for count in 0 ..< json.count {
            #expect(throws: QueryError.self) { _ = try OCRTranslationResponse(response: String(json.prefix(count))) }
        }
    }

    @Test("Legacy markers, extra prose and incorrectly escaped LaTeX fail as a whole")
    func invalidResponse() {
        let json = #"{"original":"Source","translation":"译文"}"#
        for text in [
            "<S15D346>Source</S15D346>译文",
            "Explanation\n" + json,
            json + "\nMore text",
            #"{"original":"\alpha","translation":"译文"}"#,
        ] {
            #expect(throws: QueryError.self) { _ = try OCRTranslationResponse(response: text) }
        }
    }
}
