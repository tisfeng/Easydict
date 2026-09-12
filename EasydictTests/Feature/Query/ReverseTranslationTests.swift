//
//  ReverseTranslationTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/5.
//

import AppKit
import ObjectiveC
import Testing

@testable import Easydict

// MARK: - ReverseTranslationTests

/// Exercises the real controller and language cell without starting a query window
/// or contacting translation services. Captures the cell's query callback and
/// restores the language preferences that the production toggle updates.
@MainActor
@Suite("Reverse Translation", .serialized, .tags(.unit))
struct ReverseTranslationTests {
    // MARK: Internal

    @Test("Auto source reverses to the detected language, not an Auto target")
    func detectedSource() throws {
        try withFixture { controller, model, service in
            model.detectedLanguage = .japanese
            #expect(model.queryFromLanguage == .japanese)
            #expect(model.queryTargetLanguage == .simplifiedChinese)

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "你好")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .japanese)
            #expect(model.queryTargetLanguage == .japanese)
            #expect(model.ocrImage == nil)
            #expect(model.actionType == .inputQuery)
            #expect(service.result.translatedText == "你好")
        }
    }

    @Test("Explicit languages still reverse with completed stream output")
    func explicitSource() throws {
        try withFixture { controller, model, service in
            model.userSourceLanguage = .english
            service.result.from = .english
            service.streaming = true
            service.result.isStreamFinished = true

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "你好")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .english)
        }
    }

    @Test(
        "Unavailable results preserve the original text and language-only swap",
        arguments: ["empty", "whitespace", "loading", "streaming", "error", "stale"]
    )
    func unavailableResult(state: String) throws {
        try withFixture { controller, model, service in
            makeResultUnavailable(state, controller: controller, service: service)

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "こんにちは")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .auto)
            #expect(model.ocrImage != nil)
            #expect(model.actionType == .ocrQuery)
        }
    }

    @Test("Invalid result languages do not replace the input", arguments: ["same", "autoFrom", "autoTo"])
    func invalidResultLanguages(state: String) throws {
        try withFixture { controller, model, service in
            switch state {
            case "same": service.result.from = service.result.to
            case "autoFrom": service.result.from = .auto
            case "autoTo": service.result.to = .auto
            default: Issue.record("Unknown language state")
            }

            controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

            #expect(model.inputText == "こんにちは")
            #expect(model.userSourceLanguage == .simplifiedChinese)
            #expect(model.userTargetLanguage == .auto)
            #expect(model.ocrImage != nil)
            #expect(model.actionType == .ocrQuery)
        }
    }

    @Test("Completed result direction survives language preference propagation")
    func changedPreferences() async throws {
        let config = MyConfiguration.shared
        let savedFrom = config.fromLanguage
        let savedTo = config.toLanguage
        defer {
            config.fromLanguage = savedFrom
            config.toLanguage = savedTo
        }

        // Retain the fixture across the asynchronous Defaults propagation below.
        var fixture: (NSViewController, QueryModel, ReverseTranslationService)?
        try withFixture { fixture = ($0, $1, $2) }
        let (controller, model, service) = try #require(fixture)
        config.fromLanguage = .english
        config.toLanguage = .french

        let deadline = ContinuousClock.now.advanced(by: .seconds(1))
        while model.userSourceLanguage != .english || model.userTargetLanguage != .french,
              ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(1))
        }
        try #require(model.queryFromLanguage == .english)
        try #require(model.queryTargetLanguage == .french)
        #expect(service.result.queryModel === model)
        #expect(service.result.from == .japanese)
        #expect(service.result.to == .simplifiedChinese)

        controller.perform(NSSelectorFromString("toggleTranslationLanguages"))

        #expect(model.inputText == "你好")
        #expect(model.userSourceLanguage == .simplifiedChinese)
        #expect(model.userTargetLanguage == .japanese)
        #expect(config.fromLanguage == .simplifiedChinese)
        #expect(config.toLanguage == .japanese)
        #expect(model.ocrImage == nil)
        #expect(model.actionType == .inputQuery)
    }

    @Test("Auto to Auto requeries completed output without changing preferences", arguments: [false, true])
    func bothAutomatic(streaming: Bool) throws {
        try withFixture { controller, model, service in
            MyConfiguration.shared.fromLanguage = .auto
            MyConfiguration.shared.toLanguage = .auto
            model.userTargetLanguage = .auto
            service.streaming = streaming
            var queryCount = 0

            try withCapturedQuery(controller, capture: { text, action in
                queryCount += 1
                #expect(text == "你好")
                #expect(action == .inputQuery)
                #expect(model.ocrImage == nil)
                #expect(model.userSourceLanguage == .auto)
                #expect(model.userTargetLanguage == .auto)
            }) {
                controller.perform(NSSelectorFromString("toggleTranslationLanguages"))
            }

            #expect(queryCount == 1)
            #expect(model.userSourceLanguage == .auto)
            #expect(model.userTargetLanguage == .auto)
            #expect(MyConfiguration.shared.fromLanguage == .auto)
            #expect(MyConfiguration.shared.toLanguage == .auto)
        }
    }

    @Test(
        "Auto to Auto ignores unavailable output without changing input or preferences",
        arguments: ["missing", "empty", "whitespace", "loading", "streaming", "error", "stale"]
    )
    func bothAutomaticUnavailable(state: String) throws {
        try withFixture { controller, model, service in
            MyConfiguration.shared.fromLanguage = .auto
            MyConfiguration.shared.toLanguage = .auto
            model.userTargetLanguage = .auto
            makeResultUnavailable(state, controller: controller, service: service)
            var queryCount = 0

            try withCapturedQuery(controller, capture: { _, _ in queryCount += 1 }) {
                controller.perform(NSSelectorFromString("toggleTranslationLanguages"))
            }

            #expect(queryCount == 0)
            #expect(model.inputText == "こんにちは")
            #expect(model.userSourceLanguage == .auto)
            #expect(model.userTargetLanguage == .auto)
            #expect(model.ocrImage != nil)
            #expect(model.actionType == .ocrQuery)
            #expect(MyConfiguration.shared.fromLanguage == .auto)
            #expect(MyConfiguration.shared.toLanguage == .auto)
        }
    }

    // MARK: Private

    private func makeResultUnavailable(
        _ state: String, controller: NSViewController, service: ReverseTranslationService
    ) {
        switch state {
        case "missing": controller.setValue(nil, forKey: "firstService")
        case "empty": service.result.translatedResults = []
        case "whitespace": service.result.translatedResults = [" \n\t "]
        case "loading": service.result.isLoading = true
        case "streaming":
            service.streaming = true
            service.result.isStreamFinished = false
        case "error": service.result.error = QueryError(type: .api)
        case "stale": service.result.queryText = "a different query"
        default: Issue.record("Unknown result state")
        }
    }

    /// Replaces only this fixture's query entry point, preventing detection and
    /// network work while leaving the production toggle and other instances intact.
    private func withCapturedQuery(
        _ controller: NSViewController,
        capture: @escaping (String?, ActionType) -> (),
        body: () -> ()
    ) throws {
        let originalClass: AnyClass = try #require(object_getClass(controller))
        let selector = NSSelectorFromString("startQueryText:actionType:")
        let method = try #require(class_getInstanceMethod(originalClass, selector))
        let subclass: AnyClass = try #require(objc_allocateClassPair(
            originalClass, "ReverseTranslationQueryCapture_\(UUID().uuidString)", 0
        ))
        let block: @convention(block) (NSObject, NSString?, NSString) -> () = { _, text, action in
            capture(text as String?, ActionType(rawValue: action as String))
        }
        let implementation = imp_implementationWithBlock(block)
        defer {
            object_setClass(controller, originalClass)
            objc_disposeClassPair(subclass)
            imp_removeBlock(implementation)
        }
        try #require(class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method)))
        objc_registerClassPair(subclass)
        object_setClass(controller, subclass)
        body()
    }

    /// KVC supplies existing private collaborators without adding production hooks.
    /// The inherited nib initializer avoids unrelated window and service setup.
    private func withFixture(
        _ body: (NSViewController, QueryModel, ReverseTranslationService) throws -> ()
    ) throws {
        let config = MyConfiguration.shared
        let savedFrom = config.fromLanguage
        let savedTo = config.toLanguage
        defer {
            config.fromLanguage = savedFrom
            config.toLanguage = savedTo
        }

        let controllerType = try #require(NSClassFromString("EZBaseQueryViewController") as? NSViewController.Type)
        let cellType = try #require(NSClassFromString("EZSelectLanguageCell") as? NSView.Type)
        let controller = controllerType.init(nibName: nil, bundle: nil)
        let cell = cellType.init(frame: .zero)
        let model = QueryModel()
        model.userSourceLanguage = .auto
        model.userTargetLanguage = .simplifiedChinese
        controller.setValue(model, forKey: "queryModel")
        controller.setValue("こんにちは", forKey: "inputText")
        model.detectedLanguage = .japanese
        model.actionType = .ocrQuery
        model.ocrImage = NSImage(size: NSSize(width: 1, height: 1))
        cell.setValue(model, forKey: "queryModel")
        let query: @convention(block) (NSString, NSString) -> () = { from, to in
            model.userSourceLanguage = Language(rawValue: from as String)
            model.userTargetLanguage = Language(rawValue: to as String)
        }
        cell.setValue(query, forKey: "enterActionBlock")
        controller.setValue(cell, forKey: "selectLanguageCell")

        let service = ReverseTranslationService()
        service.queryModel = model
        service.result = QueryResult()
        service.result.queryText = model.queryText
        service.result.from = model.queryFromLanguage
        service.result.to = model.queryTargetLanguage
        service.result.translatedResults = ["你好"]
        controller.setValue(service, forKey: "firstService")
        try body(controller, model, service)
    }
}

// MARK: - ReverseTranslationService

/// Supplies completed or streaming results without invoking a provider.
private final class ReverseTranslationService: QueryService {
    var streaming = false

    override func serviceType() -> ServiceType { .apple }

    override func isStream() -> Bool { streaming }
}
