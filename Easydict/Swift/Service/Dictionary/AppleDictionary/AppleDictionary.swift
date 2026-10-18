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

private let kMaxEmbeddedResourceSize = 8 * 1024 * 1024
/// Icon fonts are a few KB; larger text fonts are left as file URLs to keep query HTML small.
private let kMaxEmbeddedFontSize = 512 * 1024
private let kMaxEmbeddedResourceBytesPerQuery = 16 * 1024 * 1024
private let kLegacyHTMLDirectories = [
    "Dict HTML",
    ".Dict HTML",
    "easydict-apple-dictionary-html",
    ".easydict-apple-dictionary-html.noindex",
]

// MARK: - ResourceEmbeddingState

private struct ResourceEmbeddingState {
    var dataURLs: [URL: String] = [:]
    var embeddedBytes = 0
    var loadingURLs: Set<URL> = []
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
            appleDictionaries = newValue.compactMap { TTTDictionary(named: $0) }
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
            guard let dict = TTTDictionary(named: name) else {
                logWarn("Apple dictionary is unavailable: name=\(name)")
                continue
            }
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
        var resourceEmbeddingState = ResourceEmbeddingState()
        var allEntryHTMLs: [String] = []
        var allInnerTexts: [String] = []

        for dictionary in dictionaries {
            var wordHtmlString = ""

            // ~/Library/Dictionaries/Apple.dictionary/Contents/
            let contentsURL = dictionary.dictionaryURL?.appendingPathComponent("Contents")
            if contentsURL == nil {
                logWarn(
                    "Apple dictionary has no resource URL: "
                        + "name=\(dictionary.name), identifier=\(dictionary.identifier ?? "<missing>")"
                )
            }

            let entries = queryEntries(
                ofWord: word, inDictionary: dictionary, language: fromLanguage
            )
            let entryHTMLs = entries.htmls
            allEntryHTMLs.append(contentsOf: entryHTMLs)
            allInnerTexts.append(contentsOf: entries.texts)

            for html in entryHTMLs {
                if let contentsURL {
                    wordHtmlString += embedDictionaryResources(
                        ofHTML: html,
                        in: contentsURL,
                        state: &resourceEmbeddingState
                    )
                } else {
                    wordHtmlString += html
                }
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
        result?.translatedResults = allInnerTexts
        result?.copiedText = allInnerTexts.joined(separator: "\n\n")
        return renderResult.htmlString
    }

    // MARK: Private

    private func queryEntryHTMLs(
        ofWord word: String,
        inDictionaryName name: String,
        language: Language?
    )
        -> [String] {
        guard let dictionary = TTTDictionary(named: name) else {
            logWarn("Apple dictionary is unavailable: name=\(name)")
            return []
        }
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

    /// Embeds dictionary media, styles and small fonts so in-memory HTML does not require file access.
    private func embedDictionaryResources(
        ofHTML html: String,
        in contentsURL: URL,
        state: inout ResourceEmbeddingState,
        relativeTo baseURL: URL? = nil
    )
        -> String {
        let patterns: [(pattern: String, pathGroup: Int, extensions: Set<String>?)] = [
            (#"new\s+Audio\(\s*(?:&quot;|&apos;|["'])(.*?)(?:&quot;|&apos;|["'])\s*\)"#, 1, nil),
            (#"<(?:audio|source|img|video)\b[^>]*?\ssrc\s*=\s*(["'])(.*?)\1"#, 2, nil),
            (#"<link\b[^>]*?\shref\s*=\s*(["'])(.*?)\1"#, 2, nil),
            // Font-face declarations are handled separately with a smaller size limit.
            (
                #"@font-face\s*\{[^}]*\}|\burl\(\s*(&quot;|&apos;|["']?)(.*?)\1\s*\)"#, 2,
                ["png", "jpg", "jpeg", "gif", "svg", "webp", "bmp", "ico", "avif", "css"]
            ),
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
                guard match.range(at: item.pathGroup).location != NSNotFound,
                      let pathRange = Range(match.range(at: item.pathGroup), in: resolvedHTML),
                      let dataURL = resourceDataURL(
                          for: String(resolvedHTML[pathRange]),
                          in: contentsURL,
                          state: &state,
                          relativeTo: baseURL,
                          allowedExtensions: item.extensions
                      )
                else {
                    continue
                }
                resolvedHTML.replaceSubrange(pathRange, with: dataURL)
            }
        }
        return embedFontResources(ofHTML: resolvedHTML, in: contentsURL, state: &state, relativeTo: baseURL)
    }

    /// Resolves font URLs only within inline font-face declarations.
    private func embedFontResources(
        ofHTML html: String,
        in contentsURL: URL,
        state: inout ResourceEmbeddingState,
        relativeTo baseURL: URL? = nil
    )
        -> String {
        guard let fontFaceRegex = try? NSRegularExpression(
            pattern: #"@font-face\s*\{[^}]*\}"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ),
            let urlRegex = try? NSRegularExpression(
                pattern: #"url\(\s*(?:"([^"]*)"|'([^']*)'|([^\s)]+))\s*\)"#,
                options: [.caseInsensitive]
            )
        else { return html }

        var resolvedHTML = html
        let fontFaces = fontFaceRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        for fontFace in fontFaces.reversed() {
            guard let fontFaceRange = Range(fontFace.range, in: resolvedHTML) else { continue }
            var declaration = String(resolvedHTML[fontFaceRange])
            let urls = urlRegex.matches(in: declaration, range: NSRange(declaration.startIndex..., in: declaration))
            for url in urls.reversed() {
                guard let group = (1 ... 3).first(where: { url.range(at: $0).location != NSNotFound }),
                      let pathRange = Range(url.range(at: group), in: declaration),
                      let dataURL = resourceDataURL(
                          for: String(declaration[pathRange]), in: contentsURL, state: &state,
                          relativeTo: baseURL,
                          allowedExtensions: ["ttf", "otf", "woff", "woff2"],
                          maxFileSize: kMaxEmbeddedFontSize
                      )
                else { continue }
                declaration.replaceSubrange(pathRange, with: dataURL)
            }
            resolvedHTML.replaceSubrange(fontFaceRange, with: declaration)
        }
        return resolvedHTML
    }

    private func resourceDataURL(
        for resourcePath: String,
        in contentsURL: URL,
        state: inout ResourceEmbeddingState,
        relativeTo baseURL: URL? = nil,
        allowedExtensions: Set<String>? = nil,
        maxFileSize: Int = kMaxEmbeddedResourceSize
    )
        -> String? {
        let fragment = resourcePath.firstIndex(of: "#").map {
            String(resourcePath[$0...])
        } ?? ""
        let fragmentIndex = resourcePath.firstIndex(of: "#") ?? resourcePath.endIndex
        let pathWithoutFragment = resourcePath[..<fragmentIndex]
        let queryIndex = pathWithoutFragment.firstIndex(of: "?") ?? pathWithoutFragment.endIndex
        let escapedPath = String(pathWithoutFragment[..<queryIndex]).unescapedXMLString().trim()
        let decodedPath = escapedPath.removingPercentEncoding ?? escapedPath
        guard !decodedPath.isEmpty,
              let resourceURL = localResourceURL(for: decodedPath, in: contentsURL, relativeTo: baseURL),
              allowedExtensions?.contains(resourceURL.pathExtension.lowercased()) != false
        else {
            return nil
        }

        // Check the size before the cache so a caller's smaller limit also applies to cached data.
        guard let resourceValues = try? resourceURL.resourceValues(
            forKeys: [.fileSizeKey, .isRegularFileKey]
        ),
            resourceValues.isRegularFile == true,
            let fileSize = resourceValues.fileSize,
            fileSize <= maxFileSize
        else {
            return nil
        }

        if let dataURL = state.dataURLs[resourceURL] {
            guard state.embeddedBytes + dataURL.utf8.count <= kMaxEmbeddedResourceBytesPerQuery else {
                return nil
            }
            state.embeddedBytes += dataURL.utf8.count
            return dataURL + fragment
        }

        let rootURL = contentsURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootPath = FilePath(rootURL.path).lexicallyNormalized()
        let resolvedPath = FilePath(resourceURL.path).lexicallyNormalized()
        guard resolvedPath.starts(with: rootPath),
              resolvedPath != rootPath,
              var resourceData = FileManager.default.contents(atPath: resolvedPath.string)
        else {
            return nil
        }

        guard !state.loadingURLs.contains(resourceURL), state.loadingURLs.count < 8 else {
            return nil
        }
        if resourceURL.pathExtension.lowercased() == "css" {
            guard let css = String(data: resourceData, encoding: .utf8) else { return nil }
            state.loadingURLs.insert(resourceURL)
            let resolvedCSS = embedDictionaryResources(
                ofHTML: css, in: contentsURL, state: &state,
                relativeTo: resourceURL.deletingLastPathComponent()
            )
            state.loadingURLs.remove(resourceURL)
            resourceData = Data(resolvedCSS.utf8)
        }

        let mimeType = UTType(filenameExtension: resourceURL.pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
        let dataURL = "data:\(mimeType);base64,\(resourceData.base64EncodedString())"
        guard state.embeddedBytes + dataURL.utf8.count <= kMaxEmbeddedResourceBytesPerQuery else {
            return nil
        }
        state.dataURLs[resourceURL] = dataURL
        state.embeddedBytes += dataURL.utf8.count
        return dataURL + fragment
    }

    private func localResourceURL(
        for resourcePath: String,
        in contentsURL: URL,
        relativeTo baseURL: URL?
    )
        -> URL? {
        guard !resourcePath.hasPrefix("//"),
              URL(string: resourcePath)?.scheme == nil
        else {
            return nil
        }

        let rootURL = contentsURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootPath = FilePath(rootURL.path).lexicallyNormalized()
        let candidates: [URL]
        if resourcePath.hasPrefix("/") {
            // Dictionary entries may provide absolute paths within their bundle.
            candidates = [URL(fileURLWithPath: resourcePath)]
        } else if let baseURL {
            candidates = [baseURL.appendingPathComponent(resourcePath)]
        } else {
            candidates = [
                rootURL.appendingPathComponent("Resources", isDirectory: true)
                    .appendingPathComponent(resourcePath),
                rootURL.appendingPathComponent(resourcePath),
            ]
        }
        for candidate in candidates {
            let resourceURL = candidate
                .standardizedFileURL
                .resolvingSymlinksInPath()
            let resolvedPath = FilePath(resourceURL.path).lexicallyNormalized()
            if resolvedPath.starts(with: rootPath),
               resolvedPath != rootPath,
               (try? resourceURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                return resourceURL
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
