import AppKit
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
        let response = try await service.ocr(image, from: .english, to: .auto)
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
}
