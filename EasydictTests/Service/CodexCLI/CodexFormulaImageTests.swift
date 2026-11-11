//
//  CodexFormulaImageTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults
import os
import Testing

@testable import Easydict

@Suite(.serialized, .tags(.requiresLocalEnvironment))
struct CodexFormulaImageTests {
    // MARK: Internal

    @Test
    func testRecognizesFormulaImage() async throws {
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let service = CodexCLIService()
        let selected = try await configuredLocalModel()
        #expect(selected.acceptsImages)
        #expect(selected.efforts.contains(.low))
        service.uuid = UUID().uuidString
        let modeKey = CodexAccessMode.key(uuid: service.uuid)
        let modelKey = CodexServiceConfiguration.modelKey(uuid: service.uuid, mode: .localCLI)
        let effortKey = CodexServiceConfiguration.effortKey(uuid: service.uuid, mode: .localCLI)
        defer { Defaults.reset(modeKey, modelKey, effortKey) }
        Defaults[modeKey] = .localCLI
        Defaults[modelKey] = selected.identifier
        Defaults[effortKey] = .low
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
        #expect(compact.contains(#"\tag8"#) || compact.contains("(8)"))
    }

    @Test
    @MainActor
    func testStreamsTranslationAndRendersClosedFormula() async throws {
        let service = CodexCLIService()
        let selected = try await configuredLocalModel()
        service.uuid = UUID().uuidString
        let modeKey = CodexAccessMode.key(uuid: service.uuid)
        let modelKey = CodexServiceConfiguration.modelKey(uuid: service.uuid, mode: .localCLI)
        let effortKey = CodexServiceConfiguration.effortKey(uuid: service.uuid, mode: .localCLI)
        defer { service.cancelStream(); Defaults.reset(modeKey, modelKey, effortKey) }
        Defaults[modeKey] = .localCLI
        Defaults[modelKey] = selected.identifier
        Defaults[effortKey] = .low
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
        #expect(finalText.contains("x_j"))
        print(
            "Translation stream timing: first=\(try #require(first))s total=\(Date().timeIntervalSince(started))s updates=\(updates)"
        )
    }

    // MARK: Private

    private func configuredLocalModel() async throws -> CodexManagedAppServer.LocalModel {
        let server = CodexManagedAppServer.local
        let models: [CodexManagedAppServer.LocalModel]
        do {
            try await server.requireLocalAccountIfNeeded()
            models = try await server.availableLocalModels()
        } catch CodexCLIError.notInstalled {
            try Test.cancel("Install the Codex CLI before running this test")
        } catch CodexCLIError.notLoggedIn {
            try Test.cancel("Run codex login or configure local Codex credentials before running this test")
        }
        let modelKey = CodexServiceConfiguration.modelKey(uuid: "", mode: .localCLI)
        let configuredModel = Defaults[modelKey]
        return try #require(CodexServiceConfiguration.localModel(configuredModel, in: models))
    }
}
