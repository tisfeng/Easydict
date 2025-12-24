//
//  QueryResult.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/20.
//  Copyright © 2025 izual. All rights reserved.
//

import CoreGraphics
import Foundation

/// Converts a part-of-speech string to its abbreviated form.
private func partAbbreviation(_ part: String) -> String {
    guard !part.isEmpty else {
        return ""
    }

    let partOfSpeechMap: [(String, [String])] = [
        ("adj.", ["adjective", "形容词"]),
        ("adv.", ["adverb", "副词"]),
        ("v.", ["verb", "动词"]),
        ("linkv.", ["linkv", "linking verb", "系动词"]),
        ("auxv.", ["auxv", "auxiliary verb", "助动词"]),
        ("modalv.", ["modalv", "modal verb", "情态动词"]),
        ("n.", ["noun", "名词"]),
        ("pron.", ["pronoun", "代词"]),
        ("prep.", ["preposition", "介词"]),
        ("conj.", ["conjunction", "连词"]),
        ("int.", ["int", "感叹词"]),
        ("interj.", ["interjection", "感叹词"]),
        ("det.", ["determinative", "限定词"]),
        ("art.", ["article", "冠词"]),
        ("abbr.", ["abbreviation", "缩写"]),
        ("inf.", ["infinitive", "不定词"]),
        ("part.", ["participle", "分词"]),
        ("num.", ["numeral", "数词"]),
        ("Web", ["Web", "网络"]),
    ]

    for (abbreviation, values) in partOfSpeechMap {
        if values.contains(part) {
            return abbreviation
        }

        if values.contains(where: { $0.hasPrefix(part) }) {
            return abbreviation
        }
    }

    if part.isEnglishWord {
        return "\(part)."
    }

    return part
}

// MARK: - EZWordPhonetic

/// Represents a phonetic item for a dictionary word.
@objcMembers
class EZWordPhonetic: NSObject {
    var word: String = ""
    var language: Language = .auto
    var value: String?
    var speakURL: String?
    var name: String?
    var accent: String?
}

// MARK: - EZTranslatePart

/// Represents a grouped translation item by part of speech.
@objcMembers
class EZTranslatePart: NSObject {
    // MARK: Internal

    var means: [String] = []

    var part: String? {
        get { storedPart }
        set { storedPart = newValue.map(partAbbreviation) ?? newValue }
    }

    // MARK: Private

    private var storedPart: String?
}

// MARK: - EZTranslateExchange

/// Represents a word form exchange entry.
@objcMembers
class EZTranslateExchange: NSObject {
    var name: String = ""
    var words: [String] = []
}

// MARK: - EZTranslateSimpleWord

/// Represents a simple dictionary entry for a word or phrase.
@objcMembers
class EZTranslateSimpleWord: NSObject {
    // MARK: Internal

    var word: String = ""

    var part: String? {
        get { storedPart }
        set { storedPart = newValue.map(partAbbreviation) ?? newValue }
    }

    var means: [String]? {
        didSet { cachedMeansText = nil }
    }

    var meansText: String {
        if let cachedMeansText {
            return cachedMeansText
        }

        let joinedText = means?.joined(separator: "; ") ?? ""
        cachedMeansText = joinedText
        return joinedText
    }

    var showPartMeans: Bool = false {
        didSet {
            guard showPartMeans else { return }
            let pos = part?.isEmpty == false ? "\(part ?? "")  " : ""
            cachedMeansText = "\(pos)\(meansText)"
        }
    }

    // MARK: Private

    private var storedPart: String?
    private var cachedMeansText: String?
}

// MARK: - EZTranslateWordResult

/// Contains detailed word translation data returned by dictionary services.
@objcMembers
class EZTranslateWordResult: NSObject {
    var phonetics: [EZWordPhonetic]?
    var parts: [EZTranslatePart]?
    var exchanges: [EZTranslateExchange]?
    var simpleWords: [EZTranslateSimpleWord]?
    var tags: [String]?
    var etymology: String?
    var synonyms: [EZTranslatePart]?
    var antonyms: [EZTranslatePart]?
    var collocation: [EZTranslatePart]?
}

// MARK: - QueryResult

/// Stores the translation or dictionary results for a query.
@objcMembers
@objc(EZQueryResult)
public class QueryResult: NSObject {
    // MARK: Lifecycle

    /// Creates a new query result with default values.
    override init() {
        super.init()
        reset()
    }

    // MARK: Internal

    var queryModel: QueryModel = .init()

    var serviceTypeWithUniqueIdentifier: String = ServiceType.youdao.rawValue
    weak var service: QueryService?

    var isShowing: Bool = false
    var viewHeight: CGFloat = 0

    var isLoading: Bool = false
    var isStreamFinished: Bool = true

    var queryText: String = ""
    var from: Language = .auto
    var to: Language = .auto

    var wordResult: EZTranslateWordResult?

    var error: QueryError?

    var manualShow: Bool = false

    var fromSpeakURL: String?
    var toSpeakURL: String?

    @nonobjc var raw: Any?

    var promptTitle: String?
    var promptURL: String?

    var showBigWord: Bool = false
    var translateResultsTopInset: CGFloat = 0

    var htmlString: String?
    var htmlStrings: [String]?
    var innerTexts: [String]?

    var didFinishLoadingHTMLBlock: (@convention(block) () -> ())?

    var webViewManager: EZWebViewManager = .init()

    var showReplaceButton: Bool = false

    var translatedResults: [String]? {
        get {
            translatedResultsLock.lock()
            defer { translatedResultsLock.unlock() }
            return translatedResultsStorage
        }
        set {
            translatedResultsLock.lock()
            translatedResultsStorage = newValue
            translatedResultsLock.unlock()
        }
    }

    var translatedText: String? {
        guard let translatedResults else { return nil }
        return translatedResults.joined(separator: "\n")
    }

    var hasShowingResult: Bool {
        hasTranslatedResult || error != nil || (htmlString?.isEmpty == false)
    }

    var hasTranslatedResult: Bool {
        wordResult != nil || translatedText != nil || (htmlString?.isEmpty == false)
    }

    var isWarningErrorType: Bool {
        guard let error else { return false }
        return error.type == .unsupportedLanguage || error.type == .noResult
    }

    var copiedText: String? {
        get {
            guard htmlString?.isEmpty == false else {
                return translatedText
            }
            return storedCopiedText
        }
        set {
            storedCopiedText = newValue
        }
    }

    var queryFromLanguage: Language {
        queryModel.queryFromLanguage
    }

    var errorMessage: String? {
        error?.localizedDescription
    }

    /// Returns property names that should be ignored by MJExtension.
    class func mj_ignoredPropertyNames() -> [String] {
        ["service"]
    }

    /// Resets the result to its initial state.
    func reset() {
        queryModel = QueryModel()
        translatedResults = nil
        wordResult = nil
        error = nil
        serviceTypeWithUniqueIdentifier = ServiceType.youdao.rawValue
        service?.audioPlayer.stop()
        service = nil
        isShowing = false
        isLoading = false
        viewHeight = 0
        queryText = ""
        from = .auto
        to = .auto
        toSpeakURL = nil
        fromSpeakURL = nil
        raw = nil
        promptTitle = nil
        promptURL = nil
        showBigWord = false
        translateResultsTopInset = 0
        isStreamFinished = true
        manualShow = false
        htmlString = nil
        copiedText = nil
        didFinishLoadingHTMLBlock = nil
        webViewManager.reset()
        showReplaceButton = false
    }

    /// Converts translated results to Traditional Chinese.
    func convertToTraditionalChineseResult() {
        translatedResults = translatedResults?.toTraditionalChineseTexts()
    }

    // MARK: Private

    private let translatedResultsLock = NSLock()
    private var translatedResultsStorage: [String]?
    private var storedCopiedText: String?
}
