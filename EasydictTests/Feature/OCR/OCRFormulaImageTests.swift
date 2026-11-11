import AppKit
import Defaults
import os
import Testing
import XCTest

@testable import Easydict

// MARK: - OCRFormulaImageTests

@Suite("Formula image OCR")
struct OCRFormulaImageTests {
    @Test("Apple OCR recognizes the text around the formula")
    func appleRecognizesFormulaImage() async throws {
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let result = try #require(try await AppleService.shared.ocr(image, from: .english, to: .auto))
        #expect(result.mergedText.localizedCaseInsensitiveContains("Formula translation test"))
        #expect(result.mergedText.contains("EDLUNA-4736"))
    }

    @Test("Only explicitly supported services expose OCR")
    func advertisedOCRCapabilities() {
        #expect(AppleService.shared.supportsOCR())
        #expect(CodexCLIService().supportsOCR())
        #expect(OpenAIService().supportsOCR())
        #expect(DeepSeekService().supportsOCR())
    }
}

// MARK: - CodexFormulaImageTests

final class CodexFormulaImageTests: XCTestCase {
    func testRecognizesFormulaImage() async throws {
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let service = CodexCLIService()
        let configuredModel = CodexServiceConfiguration(uuid: "").model
        let available = try await CodexManagedAppServer.local.availableLocalModels()
        let selected = try XCTUnwrap(CodexServiceConfiguration.localModel(configuredModel, in: available))
        XCTAssertTrue(selected.acceptsImages)
        XCTAssertTrue(selected.efforts.contains(.low))
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
        XCTAssertGreaterThan(measured.count, 0, "Expected real OCR streaming deltas")
        let first = try XCTUnwrap(measured.first).timeIntervalSince(started)
        print("OCR stream timing: first=\(first)s total=\(Date().timeIntervalSince(started))s deltas=\(measured.count)")
        let result = try XCTUnwrap(response)
        let text = result.mergedText
        let compact = text.filter { !$0.isWhitespace && $0 != "{" && $0 != "}" }
        XCTAssertTrue(text.contains("EDLUNA-4736"))
        XCTAssertTrue(text.contains(#"\("#) || text.contains("$"))
        XCTAssertTrue(text.contains(#"\["#) || text.contains("$$"))
        XCTAssertTrue(compact.contains("p_7=53"))
        XCTAssertTrue(compact.contains("R_8="))
        XCTAssertTrue(compact.contains("frac"))
        XCTAssertTrue(compact.contains("x_j^2+1"))
        XCTAssertTrue(compact.contains(#"\sqrt(n+3)"#) || compact.contains(#"\sqrtn+3"#))
        XCTAssertTrue(compact.contains(#"\tag8"#) || compact.contains("(8)"))
    }

    @MainActor
    func testStreamsTranslationAndRendersClosedFormula() async throws {
        let service = CodexCLIService()
        let configuredModel = CodexServiceConfiguration(uuid: "").model
        let available = try await CodexManagedAppServer.local.availableLocalModels()
        let selected = try XCTUnwrap(CodexServiceConfiguration.localModel(configuredModel, in: available))
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
        XCTAssertGreaterThan(updates, 1, "Translation must arrive before the request finishes")
        XCTAssertTrue(renderedBeforeCompletion, "Closed formulas must render while later translation continues")
        XCTAssertTrue(finalText.contains("frac"))
        XCTAssertTrue(finalText.contains("x_j"))
        print(
            "Translation stream timing: first=\(try XCTUnwrap(first))s total=\(Date().timeIntervalSince(started))s updates=\(updates)"
        )
    }
}
