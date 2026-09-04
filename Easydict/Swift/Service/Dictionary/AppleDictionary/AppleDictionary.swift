//
//  AppleDictionary.swift
//  Easydict
//
//  Created by tisfeng on 2023/7/29.
//  Copyright © 2023 izual. All rights reserved.
//

import AppKit
import Foundation
import SystemPackage
import UniformTypeIdentifiers

// MARK: - Constants

private let kMaxEmbeddedAudioSize = 8 * 1024 * 1024
private let kMaxEmbeddedAudioBytesPerQuery = 16 * 1024 * 1024
private let kLegacyHTMLDirectories = [
    "Dict HTML",
    ".Dict HTML",
    "easydict-apple-dictionary-html",
    ".easydict-apple-dictionary-html.noindex",
]

// MARK: - AudioEmbeddingState

private struct AudioEmbeddingState {
    var dataURLs: [URL: String] = [:]
    var embeddedBytes = 0
}

// MARK: - AppleDictionary

/// Query service that wraps Apple's built-in dictionaries.
/// Marked as `@unchecked Sendable` because lookups are dispatched to background queues.
@objc(EZAppleDictionary)
@objcMembers
class AppleDictionary: QueryService, @unchecked Sendable {
    // MARK: Lifecycle

    required init() {
        super.init()
        self.appleDictionaries = TTTDictionary.activeDictionaries()
    }

    init(dictionaryNames names: [String]) {
        super.init()
        self.appleDictionaryNames = names
    }

    // MARK: Internal

    // MARK: - Singleton

    static let shared = AppleDictionary()

    var appleDictionaryNames: [String] {
        get {
            appleDictionaries.map { $0.name }
        }
        set {
            appleDictionaries = newValue.map { TTTDictionary(named: $0) }
        }
    }

    // MARK: - Override Methods

    override func serviceType() -> ServiceType {
        .appleDictionary
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary, .sentence]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        [.dictionary, .sentence]
    }

    override func wordLink(_ queryModel: QueryModel) -> String? {
        let encodedText = self.queryModel.queryText.encode()
        return "dict://\(encodedText)"
    }

    override func name() -> String {
        NSLocalizedString("apple_dictionary", comment: "")
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let orderedDict = MMOrderedDictionary()
        let allLanguages = EZLanguageManager.shared().allLanguages
        for language in allLanguages {
            orderedDict.setObject(language as NSString, forKey: language as NSString)
        }
        return orderedDict
    }

    /// Translate text using Apple Dictionary HTML lookup.
    @nonobjc
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        let noResultError = QueryError(type: .noResult)

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .default).async { [weak self] in
                guard let self else {
                    continuation.resume(
                        throwing: QueryError.error(
                            type: .unknown,
                            message: "Service released before completing the request"
                        )
                    )
                    return
                }

                // Note: this method may cost long time(>1.0s), if the html is very large.
                let htmlString = queryAllIframeHTMLResult(
                    ofWord: text,
                    fromToLanguages: [from, to],
                    inDictionaries: appleDictionaries
                )
                result?.htmlString = htmlString

                let error: QueryError? = htmlString?.isEmpty != false ? noResultError : nil
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result ?? QueryResult())
                }
            }
        }
    }

    /// Detect language using available Apple dictionaries.
    @nonobjc
    override func detectText(_ text: String) async throws -> Language {
        let languageDict = TTTDictionary.languageToDictionaryNameMap
        let supportedLanguages = languageDict.allKeys() as? [Language] ?? []

        if let matchedLanguage = supportedLanguages.first(where: {
            queryDictionary(forText: text, language: $0)
        }) {
            return matchedLanguage
        }

        return .auto
    }

    /// Detect language for Objective-C callers using a direct lookup.
    override func detectText(
        _ text: String,
        completionHandler: @escaping (Language, Error?) -> ()
    ) {
        let languageDict = TTTDictionary.languageToDictionaryNameMap
        let supportedLanguages = languageDict.allKeys() as? [Language] ?? []

        if let matchedLanguage = supportedLanguages.first(where: {
            queryDictionary(forText: text, language: $0)
        }) {
            completionHandler(matchedLanguage, nil)
            return
        }

        completionHandler(.auto, nil)
    }

    /// Apple Dictionary does not support OCR.
    @nonobjc
    override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        _ = image
        _ = from
        _ = to
        throw QueryError.error(type: .unsupportedQueryType, message: "Apple Dictionary does not support OCR")
    }

    // MARK: - Public Methods

    func queryDictionary(forText text: String, language: Language) -> Bool {
        let languageDict = TTTDictionary.languageToDictionaryNameMap
        guard let dictName = languageDict.object(forKey: language as NSString) as? String else {
            return false
        }

        let entries = queryEntryHTMLs(
            ofWord: text,
            inDictionaryName: dictName,
            language: language
        )
        return !entries.isEmpty
    }

    // MARK: Private

    // MARK: - Private Properties

    private var appleDictionaries: [TTTDictionary] = []
}

// MARK: - HTML Query Methods

extension AppleDictionary {
    // MARK: Internal

    func queryAllIframeHTMLResult(
        ofWord word: String,
        fromToLanguages languages: [Language]?,
        inDictionaryNames dictNames: [String]
    )
        -> String? {
        var dicts: [TTTDictionary] = []
        for name in dictNames {
            let dict = TTTDictionary(named: name)
            if !dicts.contains(dict) {
                dicts.append(dict)
            }
        }
        return queryAllIframeHTMLResult(
            ofWord: word, fromToLanguages: languages, inDictionaries: dicts
        )
    }

    /// Get All iframe HTML of word from dictionaries, cost ~0.2s
    func queryAllIframeHTMLResult(
        ofWord word: String,
        fromToLanguages languages: [Language]?,
        inDictionaries dictionaries: [TTTDictionary]
    )
        -> String? {
        let startTime = CFAbsoluteTimeGetCurrent()
        removeLegacyHTMLDirectories()

        let fromLanguage = languages?.first

        let customIframeContainerClass = "custom-iframe-container"
        let entryStyle = DictionaryHTMLRenderer.entryStyle(
            bodyMargin: 10,
            extraCSS: ".\(customIframeContainerClass){margin-top:0;margin-bottom:0;width:100%;}"
        )
        var sections: [DictionaryHTMLSection] = []
        var audioEmbeddingState = AudioEmbeddingState()
        var allEntryHTMLs: [String] = []
        var allInnerTexts: [String] = []

        for dictionary in dictionaries {
            var wordHtmlString = ""

            // ~/Library/Dictionaries/Apple.dictionary/Contents/
            let contentsURL = dictionary.dictionaryURL.appendingPathComponent("Contents")

            let entries = queryEntries(
                ofWord: word, inDictionary: dictionary, language: fromLanguage
            )
            let entryHTMLs = entries.htmls
            allEntryHTMLs.append(contentsOf: entryHTMLs)
            allInnerTexts.append(contentsOf: entries.texts)

            for html in entryHTMLs {
                let resolvedHTML = embedAudioResources(
                    ofHTML: html,
                    in: contentsURL,
                    state: &audioEmbeddingState
                )
                wordHtmlString += resolvedHTML
            }

            if !wordHtmlString.isEmpty {
                let dictHTML = "\(entryStyle)\n\n\(wordHtmlString)"
                sections.append(DictionaryHTMLSection(title: dictionary.shortName, html: dictHTML))
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        logInfo("Query all dicts cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

        guard let renderResult = DictionaryHTMLRenderer.render(word: word, sections: sections) else {
            return nil
        }

        result?.htmlStrings = allEntryHTMLs
        result?.innerTexts = allInnerTexts
        return renderResult.htmlString
    }

    // MARK: Private

    private func queryEntryHTMLs(
        ofWord word: String,
        inDictionaryName name: String,
        language: Language?
    )
        -> [String] {
        let dictionary = TTTDictionary(named: name)
        return queryEntryHTMLs(ofWord: word, inDictionary: dictionary, language: language)
    }

    private func queryEntryHTMLs(
        ofWord word: String,
        inDictionary dictionary: TTTDictionary,
        language: Language?
    )
        -> [String] {
        queryEntries(ofWord: word, inDictionary: dictionary, language: language).htmls
    }

    private func queryEntries(
        ofWord word: String,
        inDictionary dictionary: TTTDictionary,
        language: Language?
    )
        -> (htmls: [String], texts: [String]) {
        var entryHTMLs: [String] = []
        var texts: [String] = []

        // Cost about ~10ms
        let entries = dictionary.entries(forSearchTerm: word)
        for entry in entries {
            let html = entry.htmlWithAppCSS
            let headword = entry.headword

            // LOG --> log, 根据 genju--> 根据 gēnjù
            let isValid = isValidHeadword(headword, queryWord: word, language: language)
            if !html.isEmpty, isValid {
                entryHTMLs.append(html)
                texts.append(entry.text)
            }
        }

        return (entryHTMLs, texts)
    }

    private func removeLegacyHTMLDirectories() {
        let fileManager = FileManager.default
        let dictionaryURL = TTTDictionary.userDictionaryDirectoryURL()
        for legacyHTMLDirectory in kLegacyHTMLDirectories {
            let legacyHTMLDirectoryURL = dictionaryURL.appendingPathComponent(
                legacyHTMLDirectory,
                isDirectory: true
            )
            if fileManager.fileExists(atPath: legacyHTMLDirectoryURL.path) {
                do {
                    try fileManager.removeItem(at: legacyHTMLDirectoryURL)
                } catch {
                    logError("remove legacy HTML directory error: \(error)")
                }
            }
        }
    }
}

// MARK: - Path Replacement Methods

extension AppleDictionary {
    // MARK: Private

    /// Embeds dictionary audio so in-memory HTML does not require file access.
    private func embedAudioResources(
        ofHTML html: String,
        in contentsURL: URL,
        state: inout AudioEmbeddingState
    )
        -> String {
        let patterns: [(pattern: String, pathGroup: Int)] = [
            (#"new\s+Audio\(\s*(?:&quot;|&apos;|["'])(.*?)(?:&quot;|&apos;|["'])\s*\)"#, 1),
            (#"<audio\b[^>]*?\bsrc\s*=\s*(["'])(.*?)\1"#, 2),
        ]
        var resolvedHTML = html

        for item in patterns {
            guard let regex = try? NSRegularExpression(
                pattern: item.pattern,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ) else {
                continue
            }
            let matches = regex.matches(
                in: resolvedHTML,
                range: NSRange(resolvedHTML.startIndex..., in: resolvedHTML)
            )
            for match in matches.reversed() {
                guard let pathRange = Range(match.range(at: item.pathGroup), in: resolvedHTML),
                      let dataURL = audioDataURL(
                          for: String(resolvedHTML[pathRange]),
                          in: contentsURL,
                          state: &state
                      )
                else {
                    continue
                }
                resolvedHTML.replaceSubrange(pathRange, with: dataURL)
            }
        }
        return resolvedHTML
    }

    private func audioDataURL(
        for audioPath: String,
        in contentsURL: URL,
        state: inout AudioEmbeddingState
    )
        -> String? {
        let fragment = audioPath.firstIndex(of: "#").map {
            String(audioPath[$0...])
        } ?? ""
        let fragmentIndex = audioPath.firstIndex(of: "#") ?? audioPath.endIndex
        let pathWithoutFragment = audioPath[..<fragmentIndex]
        let queryIndex = pathWithoutFragment.firstIndex(of: "?") ?? pathWithoutFragment.endIndex
        let escapedPath = String(pathWithoutFragment[..<queryIndex]).unescapedXMLString().trim()
        let decodedPath = escapedPath.removingPercentEncoding ?? escapedPath
        guard !decodedPath.isEmpty,
              let audioURL = localAudioURL(for: decodedPath, in: contentsURL)
        else {
            return nil
        }

        if let dataURL = state.dataURLs[audioURL] {
            guard state.embeddedBytes + dataURL.utf8.count <= kMaxEmbeddedAudioBytesPerQuery else {
                return nil
            }
            state.embeddedBytes += dataURL.utf8.count
            return dataURL + fragment
        }

        guard let resourceValues = try? audioURL.resourceValues(
            forKeys: [.fileSizeKey, .isRegularFileKey]
        ),
            resourceValues.isRegularFile == true,
            let fileSize = resourceValues.fileSize,
            fileSize <= kMaxEmbeddedAudioSize
        else {
            return nil
        }

        let rootURL = contentsURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootPath = FilePath(rootURL.path).lexicallyNormalized()
        let resolvedPath = FilePath(audioURL.path).lexicallyNormalized()
        guard resolvedPath.starts(with: rootPath),
              resolvedPath != rootPath,
              let audioData = FileManager.default.contents(atPath: resolvedPath.string)
        else {
            return nil
        }

        let mimeType = UTType(filenameExtension: audioURL.pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
        let dataURL = "data:\(mimeType);base64,\(audioData.base64EncodedString())"
        guard state.embeddedBytes + dataURL.utf8.count <= kMaxEmbeddedAudioBytesPerQuery else {
            return nil
        }
        state.dataURLs[audioURL] = dataURL
        state.embeddedBytes += dataURL.utf8.count
        return dataURL + fragment
    }

    private func localAudioURL(for audioPath: String, in contentsURL: URL) -> URL? {
        guard !audioPath.hasPrefix("/"),
              !audioPath.hasPrefix("//"),
              URL(string: audioPath)?.scheme == nil
        else {
            return nil
        }

        let rootURL = contentsURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootPath = FilePath(rootURL.path).lexicallyNormalized()
        let resourceRoots = [
            rootURL.appendingPathComponent("Resources", isDirectory: true),
            rootURL,
        ]
        for resourceRoot in resourceRoots {
            let audioURL = resourceRoot.appendingPathComponent(audioPath)
                .standardizedFileURL
                .resolvingSymlinksInPath()
            let resolvedPath = FilePath(audioURL.path).lexicallyNormalized()
            if resolvedPath.starts(with: rootPath),
               resolvedPath != rootPath,
               (try? audioURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                return audioURL
            }
        }
        return nil
    }
}

// MARK: - Headword Validation

extension AppleDictionary {
    // MARK: Private

    private func isValidHeadword(_ headword: String, queryWord word: String, language: Language?)
        -> Bool {
        // Convert to case-insensitive and accent-insensitive normalized string
        let normalizedWord = word.foldedString()
        let normalizedHeadword = headword.foldedString()

        // Filter results like "-log", "log-" when querying "log"
        let remainedText = normalizedHeadword.replacingOccurrences(of: normalizedWord, with: "")
        if remainedText == "-" {
            return false
        }

        // If text is Chinese
        if let language, EZLanguageManager.shared().isChineseLanguage(language) {
            if word.count == 1 {
                return true
            }

            let simplifiedWord = normalizedWord.toSimplifiedChinese()
            let simplifiedHeadword = normalizedHeadword.toSimplifiedChinese()

            let pureChineseHeadwords = simplifiedHeadword.removingAlphabet().trim()
            let hasWordSubstring = pureChineseHeadwords.contains(simplifiedWord)
            return hasWordSubstring
        }

        // If text is not Chinese
        let isQueryDictionary: Bool
        if let language {
            isQueryDictionary = word.shouldQueryDictionary(withLanguage: language, maxWordCount: 1)
        } else {
            isQueryDictionary = false
        }

        if isQueryDictionary {
            // LaTeX == latex
            if normalizedWord.caseInsensitiveCompare(normalizedHeadword) == .orderedSame {
                return true
            }

            // Filter cases like queryViewController --> query
            if word.isEnglishWordWithMaxLength(30) {
                let splitWord = word.splitCodeText().lowercased()
                let splitHeadword = headword.splitCodeText().lowercased()

                if splitWord.wordCount != splitHeadword.wordCount,
                   splitWord.contains(splitHeadword) {
                    return false
                }
            }
            return true
        } else {
            if normalizedHeadword.contains(normalizedWord) {
                return true
            }
        }

        return false
    }
}
