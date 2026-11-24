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

    @Test("Only explicitly supported services expose OCR")
    func advertisedOCRCapabilities() {
        #expect(AppleService.shared.supportsOCR())
        #expect(CodexService().supportsOCR())
        #expect(OpenAIService().supportsOCR())
        #expect(DeepSeekService().supportsOCR())
    }
}
