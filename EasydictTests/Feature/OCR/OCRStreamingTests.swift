//
//  OCRStreamingTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Testing

@testable import Easydict

// MARK: - OCRStreamingTests

/// Exercises incremental OCR through the same request gate used by screenshot windows.
@MainActor
@Suite("OCR source streaming", .serialized, .tags(.unit))
struct OCRStreamingTests {
    // MARK: Internal

    @Test("Original text is available before recognition completes; final text stays authoritative")
    func incrementalSource() async throws {
        let model = makeModel()
        let manager = DetectManager(model: model)
        let service = ControlledOCRService()
        var previews: [String] = []
        var finished = false
        manager.ocrAndDetectText(using: service, progress: { previews.append($0) }) { _, error in
            #expect(error == nil)
            finished = true
        }
        try await waitUntil { service.started }
        service.emit("The signal ")
        try await waitUntil { previews.count == 1 }
        #expect(!finished)
        #expect(model.inputText == "The signal ")
        service.emit(#"\(x_j^2\)"#)
        service.finish(#"The signal \(x_j^2\)."#)
        try await waitUntil { finished }
        #expect(model.inputText == #"The signal \(x_j^2\)."#)
        #expect(model.detectedLanguage == .english)
        service.emit("late")
        await settle()
        #expect(model.inputText == #"The signal \(x_j^2\)."#)
    }

    @Test("Edits, clearing, image replacement, action and language changes reject queued deltas", arguments: [
        "typing", "clear", "image", "action", "language", "model",
    ])
    func changedInputWins(change: String) async throws {
        let model = makeModel()
        let manager = DetectManager(model: model)
        let service = ControlledOCRService()
        var previews: [String] = []
        var finished = false
        manager.ocrAndDetectText(using: service, progress: { previews.append($0) }) { _, _ in finished = true }
        try await waitUntil { service.started }
        service.emit("first")
        try await waitUntil { !previews.isEmpty }
        switch change {
        case "typing": model.inputText = "my edit"
        case "clear": model.inputText = ""; model.ocrImage = nil; manager.cancelOCR()
        case "image": model.ocrImage = NSImage(size: .init(width: 2, height: 2))
        case "action": model.actionType = .inputQuery
        case "language": model.userSourceLanguage = .japanese
        default: manager.queryModel = makeModel()
        }
        let expected = manager.queryModel.inputText
        service.emit(" stale")
        service.finish("stale final")
        await settle()
        #expect(previews == ["first"])
        #expect(manager.queryModel.inputText == expected)
        #expect(!finished || change == "language")
        manager.cancelOCR()
    }

    @Test("A newer screenshot keeps its own stream and completion")
    func replacementRequest() async throws {
        let model = makeModel()
        let manager = DetectManager(model: model)
        let old = ControlledOCRService()
        let current = ControlledOCRService()
        var previews: [String] = []
        var oldFinished = false
        var currentFinished = false
        manager.ocrAndDetectText(using: old, progress: { previews.append($0) }) { _, _ in oldFinished = true }
        try await waitUntil { old.started }
        model.ocrImage = NSImage(size: .init(width: 3, height: 3))
        manager.ocrAndDetectText(using: current, progress: { previews.append($0) }) { _, _ in currentFinished = true }
        try await waitUntil { current.started }
        old.emit("old text")
        current.emit("new text")
        try await waitUntil { !previews.isEmpty }
        old.finish("old final")
        current.finish("new final")
        try await waitUntil { currentFinished }
        #expect(previews == ["new text"])
        #expect(!oldFinished)
        #expect(model.inputText == "new final")
    }

    @Test("A stream error preserves visible partial text and reports failure")
    func failedStream() async throws {
        let model = makeModel()
        let manager = DetectManager(model: model)
        let service = ControlledOCRService()
        var finished = false
        manager.ocrAndDetectText(using: service, progress: { _ in }) { _, error in
            #expect(error != nil)
            finished = true
        }
        try await waitUntil { service.started }
        service.emit("partial")
        try await waitUntil { model.inputText == "partial" }
        service.fail()
        try await waitUntil { finished }
        #expect(model.inputText == "partial")
    }

    @Test("Ordinary OCR still completes once without intermediate previews")
    func ordinaryOCR() async throws {
        let model = makeModel()
        let manager = DetectManager(model: model)
        var previews: [String] = []
        var finished = false
        manager.ocrAndDetectText(using: SingleResultOCRService(), progress: { previews.append($0) }) { _, error in
            #expect(error == nil)
            finished = true
        }
        try await waitUntil { finished }
        #expect(previews.isEmpty)
        #expect(model.inputText == "ordinary OCR")
    }

    @Test("Closed original formulas render while later formulas are incomplete, preserving source and manual editing")
    func originalFormulaPreviewDuringStream() throws {
        let configuration = MyConfiguration.shared
        let originalPreference = configuration.enableMarkdownRendering
        configuration.enableMarkdownRendering = true
        defer { configuration.enableMarkdownRendering = originalPreference }
        let viewType = try #require(NSClassFromString("EZQueryView") as? NSView.Type)
        let view = viewType.init(frame: NSRect(x: 0, y: 0, width: 600, height: 260))
        let model = makeModel()
        func display(_ source: String) {
            model.inputText = source
            view.setValue(model, forKey: "queryModel")
            view.perform(NSSelectorFromString("enableStreamingFormulaPreview"))
        }
        func visible() throws -> NSTextView { try #require(view.value(forKey: "visibleTextView") as? NSTextView) }
        func mathCount(_ textView: NSTextView) -> Int {
            var count = 0
            textView.textStorage?.enumerateAttribute(
                .attachment,
                in: NSRange(location: 0, length: textView.string.utf16.count)
            ) { value, _, _ in
                if value is NSTextAttachment { count += 1 }
            }
            return count
        }
        let first = #"First \(x_j^2\)."#
        display(first + "\n\n" + #"\[\frac{1}{"#)
        #expect(try mathCount(visible()) == 1)
        #expect(try visible().string.contains(#"\frac{1}{"#))
        let completed = first + "\n\n" + #"\[\frac{1}{2}\]"# + "\n\nLater words keep arriving"
        display(completed)
        #expect(try mathCount(visible()) == 2)
        #expect(view.value(forKey: "copiedText") as? String == completed)
        view.perform(NSSelectorFromString("toggleFormulaPreview:"), with: nil)
        display(completed + " and more")
        #expect(try mathCount(visible()) == 0)
        #expect(try visible().string == completed + " and more")
        view.perform(NSSelectorFromString("resetFormulaPreview"))
        display(first)
        #expect(try mathCount(visible()) == 1)
    }

    @Test("Leading whitespace does not replace the original source before content arrives")
    func leadingWhitespace() async throws {
        let model = makeModel()
        model.inputText = "previous text"
        let manager = DetectManager(model: model)
        let service = ControlledOCRService()
        var previews: [String] = []
        var finished = false
        manager.ocrAndDetectText(using: service, progress: { previews.append($0) }) { _, _ in finished = true }
        try await waitUntil { service.started }
        service.emit(" \n")
        await settle()
        #expect(previews.isEmpty)
        #expect(model.inputText == "previous text")
        service.emit("new text")
        try await waitUntil { !previews.isEmpty }
        service.finish("new text")
        try await waitUntil { finished }
        #expect(model.inputText == "new text")
    }

    // MARK: Private

    private func makeModel() -> QueryModel {
        let model = QueryModel()
        model.userSourceLanguage = .english
        model.userTargetLanguage = .simplifiedChinese
        model.actionType = .ocrQuery
        model.ocrImage = NSImage(size: .init(width: 1, height: 1))
        return model
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let limit = Date().addingTimeInterval(3)
        while !condition(), Date() < limit { try await Task.sleep(for: .milliseconds(5)) }
        #expect(condition())
    }

    private func settle() async { try? await Task.sleep(for: .milliseconds(100)) }
}

// MARK: - ControlledOCRService

/// Deliberately ignores cancellation until explicitly finished to exercise late-provider callbacks.
private final class ControlledOCRService: QueryService {
    // MARK: Internal

    var started: Bool { lock.withLock { callback != nil } }

    override func ocr(
        _: NSImage, from _: Language, to _: Language, onDelta: @escaping @Sendable (String) -> ()
    ) async throws
        -> EZOCRResult? {
        try await withCheckedThrowingContinuation { continuation in
            lock.withLock {
                self.callback = onDelta
                self.continuation = continuation
            }
        }
    }

    func emit(_ delta: String) { lock.withLock { callback }?(delta) }

    func finish(_ text: String) {
        let result = EZOCRResult()
        result.mergedText = text
        result.from = .english
        takeContinuation()?.resume(returning: result)
    }

    func fail() { takeContinuation()?.resume(throwing: CocoaError(.fileReadUnknown)) }

    // MARK: Private

    private let lock = NSLock()
    private var callback: (@Sendable (String) -> ())?
    private var continuation: CheckedContinuation<EZOCRResult?, Error>?

    private func takeContinuation() -> CheckedContinuation<EZOCRResult?, Error>? {
        lock.withLock {
            defer { continuation = nil }
            return continuation
        }
    }
}

// MARK: - SingleResultOCRService

private final class SingleResultOCRService: QueryService {
    override func ocr(_: NSImage, from _: Language, to _: Language) async throws -> EZOCRResult? {
        let result = EZOCRResult()
        result.mergedText = "ordinary OCR"
        result.from = .english
        return result
    }
}
