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

    @Test(arguments: 1 ... 3)
    func codexReturnsBothLanguages(repetition: Int) async throws {
        try await verifyImageRequest(CodexService(), named: "codex")
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"), arguments: 1 ... 3)
    func deepSeekReturnsBothLanguages(repetition: Int) async throws {
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
        try await verifyCancellation(CodexService(), change: "edit")
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func screenshotFansOutWithoutRetranslatingCodex() async throws {
        try await verifyWindow(ocr: CodexService(), other: DeepSeekService())
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func screenshotFansOutWithoutRetranslatingDeepSeek() async throws {
        try await verifyWindow(ocr: DeepSeekService(), other: CodexService())
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func automaticLanguagesKeepBothServicesInTheSameDirection() async throws {
        try await verifyWindow(
            ocr: DeepSeekService(),
            other: CodexService(),
            automaticLanguages: true,
            ocrFirst: false
        )
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func disablingAutomaticTranslationKeepsOCRSourceOnly() async throws {
        try await verifyWindow(ocr: CodexService(), other: DeepSeekService(), autoQuery: false)
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func preferenceChangeWhileAwaitingResponseNotifiesInputCancellation() async throws {
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
        try await Task.sleep(for: .milliseconds(100))
        #expect(oldDeltas == 0)
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

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func cancellationAtSourceCompletionStopsTargetPublication() async throws {
        let model = await makeModel(try NSImage.loadTestImage(named: "ocr-en-formula.png"))
        let service = DeepSeekService()
        let manager = DetectManager(model: model)
        var sourceCompletions = 0
        var cancelled = false
        var staleUpdates = 0
        manager.ocrAndTranslate(using: service, progress: { _ in
            if cancelled { staleUpdates += 1 }
        }, ocrCompletion: { _, error in
            #expect(error == nil)
            sourceCompletions += 1
            cancelled = true
            manager.cancelOCR()
        }, translation: { _, _ in
            if cancelled { staleUpdates += 1 }
        })
        try await waitUntil { cancelled }
        let source = model.inputText
        try await Task.sleep(for: .milliseconds(500))
        #expect(sourceCompletions == 1)
        #expect(staleUpdates == 0)
        #expect(model.inputText == source)
        #expect(manager.combinedOCRRequest == nil)
        try assertFormula(source)
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func cancellingOneWindowLeavesTheOtherStreaming() async throws {
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let firstModel = await makeModel(image)
        let secondModel = await makeModel(image)
        let firstService = DeepSeekService()
        let secondService = DeepSeekService()
        let firstManager = DetectManager(model: firstModel)
        let secondManager = DetectManager(model: secondModel)
        var firstCancelled = false
        var firstStaleUpdates = 0
        var secondFinished = false
        firstManager.ocrAndTranslate(using: firstService, progress: { _ in
            if firstCancelled { firstStaleUpdates += 1 }
        }, ocrCompletion: { _, _ in }, translation: { _, _ in
            if firstCancelled { firstStaleUpdates += 1 }
        })
        secondManager.ocrAndTranslate(using: secondService, progress: { _ in }, ocrCompletion: { _, error in
            #expect(error == nil)
        }, translation: { result, error in
            #expect(error == nil)
            if result.isStreamFinished { secondFinished = true }
        })
        defer { firstManager.cancelOCR(); secondManager.cancelOCR() }
        try await Task.sleep(for: .milliseconds(100))
        firstCancelled = true
        firstManager.cancelOCR()
        firstModel.inputText = "New window input"
        try await waitUntil { secondFinished }
        #expect(firstModel.inputText == "New window input")
        #expect(firstStaleUpdates == 0)
        try assertFormula(secondModel.inputText)
        try assertFormula(secondService.result.translatedText ?? "")
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func editingAfterFirstStreamedSourceStopsOldRequest() async throws {
        let model = await makeModel(try NSImage.loadTestImage(named: "ocr-en-formula.png"))
        let service = DeepSeekService()
        let manager = DetectManager(model: model)
        var edited = false
        var stale = 0
        manager.ocrAndTranslate(using: service, progress: { text in
            if edited { stale += 1 }
            if !text.isEmpty, !edited {
                edited = true
                model.inputText = "Replacement pasted text"
            }
        }, ocrCompletion: { _, error in
            let error = error as NSError?
            if error?.code != NSUserCancelledError { stale += 1 }
        }, translation: { _, _ in stale += 1 })
        defer { manager.cancelOCR() }
        try await waitUntil { edited && manager.combinedOCRRequest == nil }
        #expect(model.inputText == "Replacement pasted text")
        #expect(!service.result.isLoading)
        #expect(stale == 0)
    }

    @Test(.enabled(if: !DeepSeekService().apiKey.isEmpty, "Configure a DeepSeek API key"))
    func combinedRequestPreservesCorrectedDetectionLanguage() async throws {
        try await verifyWindow(ocr: DeepSeekService(), other: CodexService(), preserveCorrection: true)
    }

    // MARK: Private

    private func verifyImageRequest(_ service: StreamService, named name: String) async throws {
        try await requireCodexConfiguration(service)
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
        let started = Date()
        var completions = 0
        var sourceUpdates = 0
        var targetUpdates = 0
        var originalClosed = false
        var sourceFormulaDuringStream = false
        var targetFormulaDuringStream = false
        var firstSource: TimeInterval?
        var firstTarget: TimeInterval?
        var pair: (EZOCRResult?, QueryResult?) = (nil, nil)
        sourceView.setValue(model, forKey: "queryModel")
        for try await event in service.ocrTranslationStream(image, from: .english, to: .simplifiedChinese) {
            switch event {
            case let .original(text, complete):
                #expect(!originalClosed)
                #expect(text.range(of: #"\p{Han}"#, options: .regularExpression) == nil)
                if firstSource == nil, !text.isEmpty { firstSource = Date().timeIntervalSince(started) }
                sourceUpdates += 1
                model.inputText = text
                sourceView.perform(NSSelectorFromString("updateInputText:"), with: text)
                sourceView.perform(NSSelectorFromString("enableStreamingFormulaPreview"))
                if let preview = sourceView.value(forKey: "visibleTextView") as? NSTextView,
                   mathCount(preview) >= 2 { sourceFormulaDuringStream = true }
                if complete { originalClosed = true; completions += 1 }
            case let .translation(text):
                #expect(originalClosed, "Translation must never enter the original channel")
                if firstTarget == nil, !text.isEmpty { firstTarget = Date().timeIntervalSince(started) }
                targetUpdates += 1
                label.text = text
                if mathCount(label) >= 2 { targetFormulaDuringStream = true }
            case let .finished(original, target):
                if !originalClosed { completions += 1 }
                pair = (original, target)
            }
        }
        // A fast provider can coalesce a whole field into one network chunk.
        // Require publication before the terminal event, rather than a timing-dependent chunk count.
        #expect(sourceUpdates >= 1)
        #expect(targetUpdates >= 1)
        #expect(sourceFormulaDuringStream && targetFormulaDuringStream)
        #expect(try #require(firstSource) < #require(firstTarget))
        print(
            "Sequential \(name): source=\(firstSource ?? -1)s target=\(firstTarget ?? -1)s total=\(Date().timeIntervalSince(started))s updates=\(sourceUpdates)/\(targetUpdates)"
        )
        let original = try #require(pair.0)
        let translated = try #require(pair.1)
        #expect(completions == 1)
        #expect(translated.isStreamFinished && !translated.isLoading)
        #expect(original.mergedText.range(of: #"\p{Han}"#, options: .regularExpression) == nil)
        model.inputText = original.mergedText
        sourceView.setValue(model, forKey: "queryModel")
        sourceView.perform(NSSelectorFromString("enableStreamingFormulaPreview"))
        label.text = translated.translatedText
        try assertFormula(original.mergedText)
        try assertFormula(translated.translatedText ?? "")
        #expect((translated.translatedText ?? "").range(of: #"\p{Han}"#, options: .regularExpression) != nil)
        #expect(original.from == .english && translated.from == .english)
        #expect(translated.to == .simplifiedChinese)
        let preview = try #require(sourceView.value(forKey: "visibleTextView") as? NSTextView)
        #expect(mathCount(preview) >= 2)
        #expect(mathCount(label) >= 2)
        try attach(root, name: "combined-\(name).png")
    }

    private func verifyCancellation(_ service: StreamService, change: String) async throws {
        try await requireCodexConfiguration(service)
        let originalUUID = service.uuid
        defer { service.uuid = originalUUID }
        let image = try NSImage.loadTestImage(named: "ocr-en-formula.png")
        let model = await makeModel(image)
        service.queryModel = model
        let manager = DetectManager(model: model)
        var laterCallbacks = 0
        manager.ocrAndTranslate(using: service, progress: { _ in
            laterCallbacks += 1
        }, ocrCompletion: { _, error in
            let error = error as NSError?
            if error?.domain != NSCocoaErrorDomain || error?.code != NSUserCancelledError { laterCallbacks += 1 }
        }, translation: { _, _ in laterCallbacks += 1 })
        try await Task.sleep(for: .milliseconds(100))
        #expect(laterCallbacks == 0)
        switch change {
        case "clear": model.inputText = ""; model.ocrImage = nil; manager.cancelOCR()
        case "image": model.ocrImage = NSImage(size: .init(width: 2, height: 2))
        case "language": model.userTargetLanguage = .french
        case "source-language": model.userSourceLanguage = .french
        case "configuration": service.uuid = UUID().uuidString
        case "stop": model.stopServiceRequest(service.serviceTypeWithUniqueIdentifier())
        default: model.inputText = "Replacement typed input"; manager.cancelOCR()
        }
        let expected = model.inputText
        try await waitUntil { manager.combinedOCRRequest == nil }
        #expect(model.inputText == expected)
        #expect(laterCallbacks == 0)
        manager.cancelOCR()
    }

    /// Spies on the real controller's text-query boundary and forwards every call unchanged.
    private func verifyWindow(
        ocr: StreamService, other: StreamService, autoQuery: Bool = true, automaticLanguages: Bool = false,
        ocrFirst: Bool = true, preserveCorrection: Bool = false
    ) async throws {
        try await requireCodexConfiguration(ocr)
        try await requireCodexConfiguration(other)
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
        var otherStartedBeforeTranslationFinished = false
        let spy: @convention(block) (NSObject, QueryModel, QueryService) -> () = { controller, model, service in
            textCalls.append(service.serviceTypeWithUniqueIdentifier())
            if service === other {
                otherStartedBeforeTranslationFinished = !ocr.result.isStreamFinished
                #expect(!model.needDetectLanguage)
                #expect(model.inputText.contains("EDLUNA-4736"))
            }
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
        model.inputText = "Previous screenshot input"
        model.detectedLanguage = preserveCorrection ? .english : .french
        if preserveCorrection { model.userSourceLanguage = .auto; model.needDetectLanguage = false }
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
        if preserveCorrection { #expect(model.queryFromLanguage == .english) }
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
        #expect(
            otherStartedBeforeTranslationFinished,
            "The other service starts as soon as the original closes, before the image translation finishes"
        )
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

    /// Missing local setup is a documented skip, while actual provider and protocol failures still fail.
    private func requireCodexConfiguration(_ service: StreamService) async throws {
        guard service is CodexService else { return }
        let configuration = CodexServiceConfig(uuid: service.uuid)
        do {
            if configuration.mode == .localCLI {
                let server = CodexAppServer.localCLI
                try await server.requireLocalAccountIfNeeded()
                let models = try await server.availableLocalModels()
                guard let selected = CodexServiceConfig.localModel(configuration.model, in: models),
                      selected.acceptsImages else {
                    try Test.cancel("Select an available image-capable local Codex model before running this test")
                }
            } else {
                let runtime = try await CodexRuntime.installed()
                let status = try await runtime.command(["login", "status"], process: CodexCommandProcess())
                guard try CodexConnectionCheck.isSignedIn(status) else {
                    try Test.cancel("Sign in to the bundled ChatGPT runtime before running this test")
                }
            }
        } catch CodexCLIError.notInstalled {
            try Test.cancel("Install the Codex CLI before running this test")
        } catch CodexCLIError.notLoggedIn {
            try Test.cancel("Sign in to the local Codex CLI before running this test")
        } catch CodexServiceError.componentMissing {
            try Test.cancel("Install the bundled ChatGPT component before running this test")
        }
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
        #expect(text.range(of: "<(?:[STX]|LAST_TRANSLATION_)[0-9A-Fa-f]{6}>", options: .regularExpression) == nil)
        let compact = text.filter { !$0.isWhitespace && $0 != "{" && $0 != "}" }
        #expect(text.contains("EDLUNA-4736"))
        #expect(compact.contains("p_7=53"))
        #expect(compact.contains("R_8="))
        #expect(compact.contains("frac"))
        #expect(compact.contains("x_j^2+1"))
        #expect(compact.contains("sqrtn+3") || compact.contains("sqrt(n+3)"))
        // Real providers occasionally hallucinate an extra denominator square, also in ordinary OCR.
        // Keep reporting that accuracy defect; routing/rendering checks above remain hard assertions.
        withKnownIssue("Vision output can add a denominator exponent to this image", isIntermittent: true) {
            #expect(compact.filter { $0 == "^" }.count == 1, "The fixture has only the numerator square")
        }
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
