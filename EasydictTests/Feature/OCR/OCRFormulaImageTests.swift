import AppKit
import Testing

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

    // Run explicitly with TEST_RUNNER_EASYDICT_RUN_LIVE_CODEX_OCR=1 and a signed-in Codex service.
    @Test(
        "Codex OCR transcribes the formula as LaTeX",
        .enabled(if: ProcessInfo.processInfo.environment["EASYDICT_RUN_LIVE_CODEX_OCR"] == "1")
    )
    func codexRecognizesFormulaImage() async throws {
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let service = CodexCLIService()
        let result = try #require(try await service.ocr(image, from: .english, to: .auto))
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

    @Test("Only explicitly supported services expose OCR")
    func advertisedOCRCapabilities() {
        #expect(AppleService.shared.supportsOCR())
        #expect(CodexCLIService().supportsOCR())
        #expect(OpenAIService().supportsOCR())
        #expect(!DeepSeekService().supportsOCR())
    }
}
