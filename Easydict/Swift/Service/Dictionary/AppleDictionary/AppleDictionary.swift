//
//  AppleDictionary.swift
//  Easydict
//
//  Created by tisfeng on 2023/7/29.
//  Copyright © 2023 izual. All rights reserved.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

// MARK: - Constants

private let kHTMLDirectory = ".easydict-apple-dictionary-html.noindex"
private let kHTMLDictFilePath = "all_dict.html"
private let kMaxEmbeddedResourceSize = 20 * 1024 * 1024
private let kLegacyHTMLDirectories = [
    "Dict HTML",
    ".Dict HTML",
    "easydict-apple-dictionary-html",
]

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

        let fromLanguage = languages?.first

        let customIframeContainerClass = "custom-iframe-container"
        let entryStyle = DictionaryHTMLRenderer.entryStyle(
            bodyMargin: 10,
            extraCSS: ".\(customIframeContainerClass){margin-top:0;margin-bottom:0;width:100%;}"
        )
        var sections: [DictionaryHTMLSection] = []

        for dictionary in dictionaries {
            var wordHtmlString = ""

            // ~/Library/Dictionaries/Apple.dictionary/Contents/
            let contentsURL = dictionary.dictionaryURL.appendingPathComponent("Contents")

            let entryHTMLs = queryEntryHTMLs(
                ofWord: word, inDictionary: dictionary, language: fromLanguage
            )
            result?.htmlStrings = entryHTMLs

            for html in entryHTMLs {
                let resolvedHTML = embedLocalResources(ofHTML: html, in: contentsURL)
                wordHtmlString += resolvedHTML
            }

            if !wordHtmlString.isEmpty {
                let dictHTML = "\(entryStyle)\n\n\(wordHtmlString)"
                sections.append(DictionaryHTMLSection(title: dictionary.shortName, html: dictHTML))
                saveDictHTML(dictHTML, dictName: dictionary.shortName)
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        logInfo("Query all dicts cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

        guard let renderResult = DictionaryHTMLRenderer.render(word: word, sections: sections) else {
            return nil
        }

        saveAllDictHTML(renderResult.htmlString)
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

        // `detectText` may call this method without setting `result` beforehand.
        // Avoid crashing when `result` is nil.
        result?.innerTexts = texts

        return entryHTMLs
    }

    private func saveDictHTML(_ dictHTML: String, dictName: String) {
        let dictionaryURL = TTTDictionary.userDictionaryDirectoryURL()
        let htmlDirectoryURL = dictionaryURL.appendingPathComponent(kHTMLDirectory, isDirectory: true)

        createHTMLDirectoryIfNeeded(htmlDirectoryURL, in: dictionaryURL)

        let htmlFileURL = htmlDirectoryURL.appendingPathComponent("\(dictName).html")
        do {
            try dictHTML.write(to: htmlFileURL, atomically: true, encoding: .utf8)
        } catch {
            logError("writeToFile error: \(error)")
        }
    }

    private func saveAllDictHTML(_ htmlString: String) {
        let dictionaryURL = TTTDictionary.userDictionaryDirectoryURL()
        let htmlDirectoryURL = dictionaryURL.appendingPathComponent(kHTMLDirectory, isDirectory: true)
        createHTMLDirectoryIfNeeded(htmlDirectoryURL, in: dictionaryURL)

        let fileURL = htmlDirectoryURL.appendingPathComponent(kHTMLDictFilePath)
        do {
            try htmlString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            logError("writeToFile error: \(error)")
        }
    }

    private func createHTMLDirectoryIfNeeded(_ htmlDirectoryURL: URL, in dictionaryURL: URL) {
        let fileManager = FileManager.default
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

        guard !fileManager.fileExists(atPath: htmlDirectoryURL.path) else { return }

        do {
            try fileManager.createDirectory(
                at: htmlDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            logError("createDirectoryAtPath error: \(error)")
        }
    }
}

// MARK: - Path Replacement Methods

extension AppleDictionary {
    // MARK: Private

    /// Embeds local media used by in-memory dictionary HTML.
    private func embedLocalResources(ofHTML html: String, in contentsURL: URL) -> String {
        let patterns: [(pattern: String, pathGroup: Int)] = [
            (#"new\s+Audio\(\s*(?:&quot;|&apos;|["'])(.*?)(?:&quot;|&apos;|["'])\s*\)"#, 1),
            (#"<(?:audio|source|img|video)\b[^>]*?\bsrc\s*=\s*(["'])(.*?)\1"#, 2),
            (#"url\(\s*(["']?)(.*?)\1\s*\)"#, 2),
        ]
        var embeddedResources: [URL: String] = [:]
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
                      let dataURL = resourceDataURL(
                          for: String(resolvedHTML[pathRange]),
                          in: contentsURL,
                          embeddedResources: &embeddedResources
                      )
                else {
                    continue
                }
                resolvedHTML.replaceSubrange(pathRange, with: dataURL)
            }
        }
        return resolvedHTML
    }

    private func resourceDataURL(
        for resourcePath: String,
        in contentsURL: URL,
        embeddedResources: inout [URL: String]
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
              let resourceURL = localResourceURL(for: decodedPath, in: contentsURL)
        else {
            return nil
        }

        if let dataURL = embeddedResources[resourceURL] {
            return dataURL + fragment
        }

        guard let resourceValues = try? resourceURL.resourceValues(
            forKeys: [.fileSizeKey, .isRegularFileKey]
        ),
            resourceValues.isRegularFile == true,
            let fileSize = resourceValues.fileSize,
            fileSize <= kMaxEmbeddedResourceSize,
            let resourceData = try? Data(contentsOf: resourceURL)
        else {
            return nil
        }

        let mimeType = UTType(filenameExtension: resourceURL.pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
        let dataURL = "data:\(mimeType);base64,\(resourceData.base64EncodedString())"
        embeddedResources[resourceURL] = dataURL
        return dataURL + fragment
    }

    private func localResourceURL(for resourcePath: String, in contentsURL: URL) -> URL? {
        let fileManager = FileManager.default
        let rootURL = contentsURL.standardizedFileURL.resolvingSymlinksInPath()
        let resourceURL: URL

        if resourcePath.hasPrefix("file://") {
            resourceURL = URL(fileURLWithPath: String(resourcePath.dropFirst("file://".count)))
        } else if resourcePath.hasPrefix("/") {
            resourceURL = URL(fileURLWithPath: resourcePath)
        } else {
            guard URL(string: resourcePath)?.scheme == nil,
                  !resourcePath.hasPrefix("//")
            else {
                return nil
            }

            var resourceBaseURL = rootURL
            let components = resourcePath.split(separator: "/")
            if components.count > 1,
               let directoryURL = findDirectory(in: rootURL, named: String(components[0])) {
                resourceBaseURL = directoryURL.deletingLastPathComponent()
            }
            resourceURL = resourceBaseURL.appendingPathComponent(resourcePath)
        }

        guard fileManager.fileExists(atPath: resourceURL.path) else { return nil }
        let resolvedURL = resourceURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootComponents = rootURL.pathComponents
        let resourceComponents = resolvedURL.pathComponents
        guard resourceComponents.count > rootComponents.count,
              Array(resourceComponents.prefix(rootComponents.count)) == rootComponents
        else {
            return nil
        }
        return resolvedURL
    }

    private func findDirectory(in rootURL: URL, named directoryName: String) -> URL? {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        ) else {
            return nil
        }

        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(
                forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
            ) else {
                continue
            }
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            if values.isDirectory == true, url.lastPathComponent == directoryName {
                return url
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
