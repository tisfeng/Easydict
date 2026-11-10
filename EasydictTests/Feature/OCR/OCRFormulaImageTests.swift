import AppKit
import OpenAI
import Testing

@testable import Easydict

// MARK: - OCRFormulaImageTests

@Suite("Formula image OCR")
struct OCRFormulaImageTests {
    // MARK: Internal

    @Test("Apple OCR recognizes the text around a formula")
    func appleRecognizesFormulaImage() async throws {
        let result = try #require(try await AppleService.shared.ocr(formulaImage(), from: .english, to: .auto))
        #expect(result.mergedText.localizedCaseInsensitiveContains("Equation"))
        #expect(result.mergedText.contains("7"))
    }

    @Test("Stream OCR passes a PNG and source language through and preserves LaTeX")
    func streamOCRPreservesFormula() async throws {
        let service = FormulaOCRService()
        let result = try #require(try await service.ocr(formulaImage(), from: .english, to: .french))
        #expect(result.from == .english)
        #expect(result.mergedText == #"Equation (7): \(x_1 = \frac{1}{2}\)."#)
    }

    @Test("OpenAI OCR uses a multimodal chat request and returns editable LaTeX")
    func openAIOCRUsesImageMessage() async throws {
        let result = try #require(try await FormulaOpenAIService().ocr(formulaImage(), from: .english, to: .auto))
        #expect(result.mergedText == #"Equation (7): \(x_1 = \frac{1}{2}\)."#)
    }

    @Test("Only explicitly supported services expose OCR")
    func advertisedOCRCapabilities() {
        #expect(AppleService.shared.supportsOCR())
        #expect(CodexCLIService().supportsOCR())
        #expect(OpenAIService().supportsOCR())
        #expect(!DeepSeekService().supportsOCR())
    }

    // MARK: Private

    private func formulaImage() -> NSImage {
        NSImage(size: NSSize(width: 820, height: 170), flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            ("Equation (7): x₁ = ½." as NSString).draw(
                at: NSPoint(x: 38, y: 55),
                withAttributes: [.font: NSFont.systemFont(ofSize: 48), .foregroundColor: NSColor.black]
            )
            return true
        }
    }
}

// MARK: - FormulaOCRService

private final class FormulaOCRService: StreamService {
    override func serviceType() -> ServiceType { .openAI }

    override func supportsOCR() -> Bool { true }

    override func recognizeImage(_ imageURL: String, prompt: String) async throws -> String {
        let prefix = "data:image/png;base64,"
        #expect(imageURL.hasPrefix(prefix))
        let bytes = try #require(Data(base64Encoded: String(imageURL.dropFirst(prefix.count))))
        let bitmap = try #require(NSBitmapImageRep(data: bytes))
        #expect(bitmap.pixelsWide > 0)
        #expect(prompt.contains("The source language is English"))
        #expect(prompt.contains("in its original language"))
        return #" Equation (7): \(x_1 = \frac{1}{2}\). "#
    }
}

// MARK: - FormulaOpenAIService

private final class FormulaOpenAIService: OpenAIService {
    override func validateChatStreamRequest() throws -> URL {
        try #require(URL(string: "https://example.com/v1/chat/completions"))
    }

    override func requestChatText(query: ChatQuery, url: URL, apiKey: String) async throws -> String {
        let payload = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(query)) as? [String: Any]
        )
        let messages = try #require(payload["messages"] as? [[String: Any]])
        let message = try #require(messages.first)
        let parts = try #require(message["content"] as? [[String: Any]])
        let image = try #require(parts.first { $0["type"] as? String == "image_url" })
        let imageURL = try #require((image["image_url"] as? [String: Any])?["url"] as? String)
        #expect(imageURL.hasPrefix("data:image/png;base64,"))
        #expect(message["role"] as? String == "user")
        #expect(payload["model"] as? String == model)
        return #"Equation (7): \(x_1 = \frac{1}{2}\)."#
    }
}
