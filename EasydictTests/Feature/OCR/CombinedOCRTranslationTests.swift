//
//  CombinedOCRTranslationTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults
import ObjectiveC
import Testing

@testable import Easydict

/// All provider calls use the locally configured service and its actual credentials.
@MainActor
@Suite("Combined image OCR and translation", .serialized, .tags(.requiresLocalEnvironment))
struct CombinedOCRTranslationTests {
    // MARK: Internal

    @Test
    func codexStreamsBothLanguages() async throws {
        try await verifyImageRequest(CodexCLIService(), named: "codex")
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func deepSeekStreamsBothLanguages() async throws {
        try await verifyImageRequest(DeepSeekService(), named: "deepseek")
    }

    @Test(
        .enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"),
        arguments: ["edit", "clear", "image", "language", "source-language", "configuration", "stop"]
    )
    func deepSeekRejectsSupersededUpdates(change: String) async throws {
        try await verifyCancellation(DeepSeekService(), change: change)
    }

    @Test
    func codexRejectsSupersededUpdates() async throws {
        try await verifyCancellation(CodexCLIService(), change: "edit")
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func screenshotFansOutWithoutRetranslatingCodex() async throws {
        try await verifyWindow(ocr: CodexCLIService(), other: DeepSeekService())
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func screenshotFansOutWithoutRetranslatingDeepSeek() async throws {
        try await verifyWindow(ocr: DeepSeekService(), other: CodexCLIService())
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func automaticLanguagesKeepBothServicesInTheSameDirection() async throws {
        try await verifyWindow(
            ocr: DeepSeekService(),
            other: CodexCLIService(),
            automaticLanguages: true,
            ocrFirst: false
        )
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func disablingAutomaticTranslationKeepsOCRSourceOnly() async throws {
        try await verifyWindow(ocr: CodexCLIService(), other: DeepSeekService(), autoQuery: false)
    }

    @Test
    func codexTwoPhaseReferenceForTheSameImage() async throws {
        let service = CodexCLIService()
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let model = await makeModel(image)
        let started = Date()
        let original = try #require(try await service.ocr(image, from: .english, to: .simplifiedChinese))
        let ocrDuration = Date().timeIntervalSince(started)
        let ocrUsage = service.tokenUsage
        model.inputText = original.mergedText
        var firstTranslation: TimeInterval?
        var final = ""
        for try await result in service.startQueryStream(model) {
            if firstTranslation == nil, result.translatedText?.isEmpty == false {
                firstTranslation = Date().timeIntervalSince(started)
            }
            final = result.translatedText ?? ""
        }
        try assertFormula(original.mergedText)
        try assertFormula(final)
        if let ocrUsage, let translationUsage = service.tokenUsage {
            print(
                "Two-phase codex reported tokens: OCR=\(ocrUsage.totalTokens) translation=\(translationUsage.totalTokens)"
            )
        }
        print(
            "Two-phase codex: OCR=\(ocrDuration)s translation=\(try #require(firstTranslation))s total=\(Date().timeIntervalSince(started))s"
        )
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func preferenceChangeBeforeFirstDeltaNotifiesInputCancellation() async throws {
        let model = await makeModel(try NSImage.loadTestImage(named: "ocr-en-formula.png"))
        let service = DeepSeekService()
        service.queryModel = model
        _ = service.resetServiceResult()
        let manager = DetectManager(model: model)
        var cancelled = false
        var unexpectedUpdate = false
        manager.ocrAndTranslate(using: service, progress: { _ in unexpectedUpdate = true }, ocrCompletion: { _, error in
            let error = error as NSError?
            cancelled = error?.domain == NSCocoaErrorDomain && error?.code == NSUserCancelledError
        }, translation: { _, _ in unexpectedUpdate = true })
        model.userTargetLanguage = .french
        try await waitUntil { cancelled }
        #expect(!unexpectedUpdate)
        #expect(model.inputText.isEmpty)
        #expect(manager.combinedOCRRequest == nil)
        manager.cancelOCR()
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func replacingARequestKeepsTheNewGenerationAlive() async throws {
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let model = await makeModel(image)
        let service = DeepSeekService()
        let manager = DetectManager(model: model)
        var oldDeltas = 0
        var newFinished = false
        manager.ocrAndTranslate(
            using: service,
            progress: { _ in oldDeltas += 1 },
            ocrCompletion: { _, _ in },
            translation: { _, _ in }
        )
        try await waitUntil { oldDeltas > 0 }
        let previousCount = oldDeltas
        model.inputText = ""
        manager.ocrAndTranslate(using: service, progress: { _ in }, ocrCompletion: { _, error in
            #expect(error == nil)
        }, translation: { result, error in
            #expect(error == nil)
            if result.isStreamFinished { newFinished = true }
        })
        defer { manager.cancelOCR() }
        try await waitUntil { newFinished }
        #expect(oldDeltas == previousCount)
        #expect(manager.combinedOCRRequest == nil)
        try assertFormula(model.inputText)
        try assertFormula(service.result.translatedText ?? "")
    }

    // MARK: Private

    private func verifyImageRequest(_ service: StreamService, named name: String) async throws {
        let config = MyConfiguration.shared
        let markdown = config.enableMarkdownRendering
        config.enableMarkdownRendering = true
        defer { config.enableMarkdownRendering = markdown }
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let model = await makeModel(image)
        let viewType = try #require(NSClassFromString("EZQueryView") as? NSView.Type)
        let sourceView = viewType.init(frame: NSRect(x: 0, y: 330, width: 620, height: 300))
        let label = TranslationResultLabel(frame: NSRect(x: 12, y: 12, width: 596, height: 300))
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: 640))
        root.addSubview(sourceView)
        root.addSubview(label)
        let window = NSWindow(contentRect: root.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = root
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        defer { window.close() }
        let (updates, continuation) = AsyncStream<OCRTranslationStream.Update>.makeStream()
        let started = Date()
        let operation = Task {
            do {
                let result = try await service.ocrAndTranslate(image, from: .english, to: .simplifiedChinese) {
                    continuation.yield($0)
                }
                continuation.finish()
                return result
            } catch { continuation.finish(); throw error }
        }
        var firstSource: TimeInterval?
        var firstTranslation: TimeInterval?
        var translationBeforeCompleteSource = false
        var sourceAtCompletion: String?
        var lastRender = Date.distantPast
        for await update in updates {
            if firstSource == nil, !update.source.isEmpty { firstSource = Date().timeIntervalSince(started) }
            if firstTranslation == nil,
               !update.translation.isEmpty { firstTranslation = Date().timeIntervalSince(started) }
            if !update.translation.isEmpty, !update.sourceComplete { translationBeforeCompleteSource = true }
            if update.sourceComplete {
                if let sourceAtCompletion { #expect(update.source == sourceAtCompletion) }
                else { sourceAtCompletion = update.source }
            }
            guard !update.source.isEmpty,
                  update.complete || Date().timeIntervalSince(lastRender) >= 0.08 else { continue }
            lastRender = Date()
            model.inputText = update.source
            sourceView.setValue(model, forKey: "queryModel")
            sourceView.perform(NSSelectorFromString("enableStreamingFormulaPreview"))
            label.text = update.translation
        }
        let (original, translated) = try await operation.value
        #expect(firstSource != nil && firstTranslation != nil)
        #expect(translationBeforeCompleteSource, "Short blocks must alternate before the final source block")
        #expect(original.mergedText == sourceAtCompletion)
        try assertFormula(original.mergedText)
        try assertFormula(translated.translatedText ?? "")
        #expect((translated.translatedText ?? "").range(of: #"\p{Han}"#, options: .regularExpression) != nil)
        #expect(original.from == .english && translated.from == .english)
        #expect(translated.to == .simplifiedChinese)
        let preview = try #require(sourceView.value(forKey: "visibleTextView") as? NSTextView)
        #expect(mathCount(preview) >= 2)
        #expect(mathCount(label) >= 2)
        try attach(root, name: "combined-\(name).png")
        if let codex = service as? CodexCLIService, let usage = codex.tokenUsage {
            print("Combined codex reported tokens: \(usage.totalTokens)")
        }
        print(
            "Combined \(name): source=\(try #require(firstSource))s translation=\(try #require(firstTranslation))s total=\(Date().timeIntervalSince(started))s"
        )
    }

    private func verifyCancellation(_ service: StreamService, change: String) async throws {
        let originalUUID = service.uuid
        defer { service.uuid = originalUUID }
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let model = await makeModel(image)
        service.queryModel = model
        let manager = DetectManager(model: model)
        var changed = false
        var laterCallbacks = 0
        manager.ocrAndTranslate(using: service, progress: { _ in
            if changed { laterCallbacks += 1; return }
            changed = true
            switch change {
            case "clear": model.inputText = ""; model.ocrImage = nil; manager.cancelOCR()
            case "image": model.ocrImage = NSImage(size: .init(width: 2, height: 2))
            case "language": model.userTargetLanguage = .french
            case "source-language": model.userSourceLanguage = .french
            case "configuration": service.uuid = UUID().uuidString
            case "stop": model.stopServiceRequest(service.serviceTypeWithUniqueIdentifier())
            default: model.inputText = "Replacement typed input"; manager.cancelOCR()
            }
        }, ocrCompletion: { _, error in
            let error = error as NSError?
            if error?.domain != NSCocoaErrorDomain || error?.code != NSUserCancelledError { laterCallbacks += 1 }
        }, translation: { _, _ in laterCallbacks += 1 })
        try await waitUntil { changed }
        let expected = model.inputText
        try await Task.sleep(for: .milliseconds(500))
        #expect(model.inputText == expected)
        #expect(laterCallbacks == 0)
        manager.cancelOCR()
    }

    /// Spies on the real controller's text-query boundary and forwards every call unchanged.
    private func verifyWindow(
        ocr: StreamService, other: StreamService, autoQuery: Bool = true, automaticLanguages: Bool = false,
        ocrFirst: Bool = true
    ) async throws {
        let config = MyConfiguration.shared
        let oldOCR = Defaults[.ocrServiceID]
        let oldCopy = config.autoCopyOCRText
        let oldTranslatedCopy = config.autoCopyFirstTranslatedText
        let oldSave = config.localAutoSave
        Defaults[.ocrServiceID] = ocr.serviceTypeWithUniqueIdentifier()
        config.autoCopyOCRText = false
        config.autoCopyFirstTranslatedText = false
        config.localAutoSave = false
        defer {
            Defaults[.ocrServiceID] = oldOCR
            config.autoCopyOCRText = oldCopy
            config.autoCopyFirstTranslatedText = oldTranslatedCopy
            config.localAutoSave = oldSave
        }
        let base = try #require(NSClassFromString("EZBaseQueryViewController"))
        let selector = NSSelectorFromString("queryWithModel:service:")
        let originalMethod = try #require(class_getInstanceMethod(base, selector))
        typealias Query = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> ()
        let original = unsafeBitCast(method_getImplementation(originalMethod), to: Query.self)
        var textCalls: [String] = []
        let spy: @convention(block) (NSObject, QueryModel, QueryService) -> () = { controller, model, service in
            textCalls.append(service.serviceTypeWithUniqueIdentifier())
            original(controller, selector, model, service)
        }
        let subclass = try #require(objc_allocateClassPair(base, "CombinedOCRWindow_\(UUID().uuidString)", 0))
        let implementation = imp_implementationWithBlock(spy)
        try #require(class_addMethod(subclass, selector, implementation, method_getTypeEncoding(originalMethod)))
        objc_registerClassPair(subclass)
        let controllerType = try #require(subclass as? NSViewController.Type)
        let controller = controllerType.init(nibName: nil, bundle: nil)
        defer {
            controller.perform(NSSelectorFromString("cancelAutoQuery"))
            object_setClass(controller, base)
            objc_disposeClassPair(subclass)
            imp_removeBlock(implementation)
        }
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let model = await makeModel(image)
        if automaticLanguages {
            model.userSourceLanguage = .auto
            model.userTargetLanguage = .auto
        }
        let manager = DetectManager(model: model)
        let services = ocrFirst ? [ocr, other] : [other, ocr]
        for service in services {
            service.queryModel = model
            _ = service.resetServiceResult()
        }
        controller.setValue(model, forKey: "queryModel")
        controller.setValue(manager, forKey: "detectManager")
        controller.setValue(config, forKey: "config")
        controller.setValue(services, forKey: "services")
        controller.setValue(services.map { $0.serviceTypeWithUniqueIdentifier() }, forKey: "serviceTypeIds")
        let view = try #require(controller.perform(NSSelectorFromString("createQueryView"))?
            .takeUnretainedValue() as? NSView)
        view.frame = NSRect(x: 0, y: 0, width: 620, height: 300)
        controller.setValue(view, forKey: "queryView")
        try #require(manager.combinedOCRService(in: services) === ocr, "Add the OCR service in Easydict settings first")
        let start = NSSelectorFromString("startOCRImage:actionType:autoQuery:")
        typealias Start = @convention(c) (AnyObject, Selector, NSImage, NSString, Bool) -> ()
        unsafeBitCast(controller.method(for: start), to: Start.self)(
            controller,
            start,
            image,
            ActionType.ocrQuery.rawValue as NSString,
            autoQuery
        )
        defer { manager.cancelOCR(); model.stopAllService() }
        if !autoQuery {
            try await waitUntil { !model.needDetectLanguage && model.inputText.contains("EDLUNA-4736") }
            #expect(textCalls.isEmpty)
            #expect(ocr.result.translatedText?.isEmpty != false)
            #expect(other.result.translatedText?.isEmpty != false)
            try assertFormula(model.inputText)
            return
        }
        try await waitUntil {
            manager.combinedOCRRequest == nil && ocr.result.isStreamFinished && other.result.isStreamFinished
                && (other.result.translatedText?.isEmpty == false || other.result.error != nil)
        }
        #expect(ocr.result.error == nil)
        #expect(other.result.error == nil)
        #expect(textCalls == [other.serviceTypeWithUniqueIdentifier()])
        #expect(controller.value(forKey: "firstService") as? QueryService === services.first)
        #expect(other.result.queryText == model.queryText)
        try assertFormula(model.inputText)
        try assertFormula(ocr.result.translatedText ?? "")
        try assertFormula(other.result.translatedText ?? "")
        let target: Language = automaticLanguages
            ? EZLanguageManager.shared().userTargetLanguage(withSourceLanguage: .english) : .simplifiedChinese
        #expect(ocr.result.from == .english && ocr.result.to == target)
        #expect(other.result.from == .english && other.result.to == target)
    }

    private func makeModel(_ image: NSImage) async -> QueryModel {
        let model = QueryModel()
        await Task.yield()
        model.userSourceLanguage = .english
        model.userTargetLanguage = .simplifiedChinese
        model.ocrImage = image
        model.actionType = .ocrQuery
        return model
    }

    private func assertFormula(_ text: String) throws {
        #expect(text.range(of: "<[STEX][0-9A-Fa-f]{6}>", options: .regularExpression) == nil)
        let compact = text.filter { !$0.isWhitespace && $0 != "{" && $0 != "}" }
        #expect(text.contains("EDLUNA-4736"))
        #expect(compact.contains("p_7=53"))
        #expect(compact.contains("frac"))
        #expect(compact.contains("x_j^2+1"))
    }

    private func mathCount(_ textView: NSTextView) -> Int {
        var count = 0
        textView.textStorage?.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: textView.string.utf16.count)
        ) { value, _, _ in
            if value is NSTextAttachment { count += 1 }
        }
        return count
    }

    private func attach(_ view: NSView, name: String) throws {
        view.layoutSubtreeIfNeeded()
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        Attachment.record(try #require(bitmap.representation(using: .png, properties: [:])), named: name)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(90)
        while !condition(), Date() < deadline { try await Task.sleep(for: .milliseconds(20)) }
        try #require(condition())
    }
}
