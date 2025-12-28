//
//  QueryModel.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/22.
//

import AppKit
import Combine
import Defaults
import Foundation

/// Model that encapsulates query text, language preferences, and request state.
@objc(EZQueryModel)
@objcMembers
open class QueryModel: NSObject, NSCopying {
    // MARK: Lifecycle

    /// Initializes a new query model and starts observing defaults.
    override init() {
        super.init()
        startObservingDefaults()
    }

    // MARK: Public

    // MARK: - NSCopying

    /// Creates a copy of the model for request isolation.
    public func copy(with zone: NSZone? = nil) -> Any {
        let model = QueryModel()
        model.actionType = actionType
        model.inputText = inputText
        model.userSourceLanguage = userSourceLanguage
        model.userTargetLanguage = userTargetLanguage
        model.detectedLanguage = detectedLanguage
        model.ocrImage = ocrImage
        model.queryViewHeight = queryViewHeight
        model.audioURL = audioURL
        model.needDetectLanguage = needDetectLanguage
        model.showAutoLanguage = showAutoLanguage
        model.specifiedTextLanguageDict = specifiedTextLanguageDict.mutableCopy() as? NSMutableDictionary
            ?? NSMutableDictionary()
        model.autoQuery = autoQuery
        return model
    }

    // MARK: Internal

    /// Normalized query text derived from the input text.
    private(set) var queryText: String = ""

    /// Selection type for text capture.
    var selectTextType: EZSelectTextType = .accessibility

    /// User selected source language.
    var userSourceLanguage: Language = .auto

    /// User selected target language.
    var userTargetLanguage: Language = .auto

    /// OCR confidence for the last OCR result.
    var ocrConfidence: CGFloat = 0

    /// Language detection confidence for the last detection result.
    var detectConfidence: CGFloat = 0

    /// Whether to show the auto language indicator.
    var showAutoLanguage: Bool = false

    /// Mapping from query text to a specified language.
    var specifiedTextLanguageDict: NSMutableDictionary = .init()

    /// OCR image for the current query.
    var ocrImage: NSImage?

    /// Audio URL generated for the current query.
    var audioURL: String?

    /// Cached query view height.
    var queryViewHeight: CGFloat = 0

    /// Whether to auto query after updating the model.
    var autoQuery: Bool = true

    // MARK: - Public Properties

    /// User input text.
    var inputText: String {
        get { inputTextStorage }
        set {
            if newValue != inputTextStorage {
                audioURL = nil
                needDetectLanguage = true
                queryText = newValue.handlingInputText()
            }

            inputTextStorage = newValue

            if queryText.isEmpty {
                detectedLanguageStorage = .auto
                showAutoLanguage = false
            }
        }
    }

    /// Action type that triggers the query.
    var actionType: ActionType = .none {
        didSet {
            let isOCRAction = actionType == .ocrQuery
                || actionType == .screenshotOCR
                || actionType == .pasteboardOCR
                || actionType == .none
            if !isOCRAction {
                ocrImage = nil
            }
        }
    }

    /// Detected language for the current query text.
    var detectedLanguage: Language {
        get { detectedLanguageStorage }
        set {
            detectedLanguageStorage = newValue
            applySpecifiedLanguageOverride()
        }
    }

    /// Effective query source language.
    var queryFromLanguage: Language {
        hasUserSourceLanguage ? userSourceLanguage : detectedLanguage
    }

    /// Effective query target language.
    var queryTargetLanguage: Language {
        let fromLanguage = queryFromLanguage
        if hasUserTargetLanguage {
            return userTargetLanguage
        }
        return EZLanguageManager.shared().userTargetLanguage(withSourceLanguage: fromLanguage)
    }

    /// Whether the query source language is not auto.
    var hasQueryFromLanguage: Bool {
        queryFromLanguage != .auto
    }

    /// Whether the user has specified the source language.
    var hasUserSourceLanguage: Bool {
        userSourceLanguage != .auto
    }

    /// Whether the user has specified the target language.
    var hasUserTargetLanguage: Bool {
        userTargetLanguage != .auto
    }

    /// Whether language detection is required for the current query.
    var needDetectLanguage: Bool {
        get { needDetectLanguageStorage }
        set {
            needDetectLanguageStorage = newValue
            if newValue {
                showAutoLanguage = false
            }
            detectedLanguage = detectedLanguageStorage
        }
    }

    // MARK: - Stop Block

    /// Registers a stop block for a service.
    /// - Parameters:
    ///   - stopBlock: Block that cancels the service request.
    ///   - serviceType: Service type identifier.
    @objc(setStopBlock:serviceType:)
    func setStop(_ stopBlock: (() -> ())?, serviceType: String) {
        if let stopBlock {
            stopBlockDictionary[serviceType] = stopBlock
        } else {
            stopBlockDictionary.removeValue(forKey: serviceType)
        }
    }

    /// Stops the request for a service type and removes the block.
    /// - Parameter serviceType: Service type identifier.
    func stopServiceRequest(_ serviceType: String) {
        if let stopBlock = stopBlockDictionary[serviceType] {
            stopBlock()
            stopBlockDictionary.removeValue(forKey: serviceType)
        }
    }

    /// Returns whether a service has been stopped.
    /// - Parameter serviceType: Service type identifier.
    /// - Returns: True if no stop block is registered for the service.
    func isServiceStopped(_ serviceType: String) -> Bool {
        stopBlockDictionary[serviceType] == nil
    }

    /// Stops all registered services.
    func stopAllService() {
        let serviceTypes = Array(stopBlockDictionary.keys)
        for serviceType in serviceTypes {
            stopServiceRequest(serviceType)
        }
    }

    // MARK: Private

    // MARK: - Stored Properties

    private var inputTextStorage: String = ""
    private var detectedLanguageStorage: Language = .auto
    private var needDetectLanguageStorage: Bool = true
    private var stopBlockDictionary: [String: () -> ()] = [:]
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Defaults Observation

    /// Starts observing language defaults for user preferences.
    private func startObservingDefaults() {
        Defaults.publisher(.queryFromLanguage, options: [.initial])
            .map(\.newValue)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] language in
                self?.userSourceLanguage = language
            }
            .store(in: &cancellables)

        Defaults.publisher(.queryToLanguage, options: [.initial])
            .map(\.newValue)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] language in
                self?.userTargetLanguage = language
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers

    /// Applies a user specified language override for the current query text.
    private func applySpecifiedLanguageOverride() {
        guard let specifiedLanguage = specifiedTextLanguageDict[queryText] as? Language else {
            return
        }
        detectedLanguageStorage = specifiedLanguage
        needDetectLanguageStorage = false
    }
}
