//
//  AppleDictionary.swift
//  Easydict
//
//  Created by tisfeng on 2023/7/29.
//  Copyright © 2023 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - Constants

private let kHTMLDirectory = "Dict HTML"
private let kHTMLDictFilePath = "all_dict.html"

// MARK: - AppleDictionary

@objc(EZAppleDictionary)
@objcMembers
class AppleDictionary: QueryService {
    // MARK: Lifecycle

    override init() {
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

    // MARK: - Public Properties

    var htmlFilePath: String = ""

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

    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary, .sentence]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        [.dictionary, .sentence]
    }

    override func wordLink(_ queryModel: EZQueryModel) -> String? {
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

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> Void
    ) {
        let noResultError = QueryError(type: .noResult)

        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self else { return }

            // Note: this method may cost long time(>1.0s), if the html is very large.
            let htmlString = queryAllIframeHTMLResult(
                ofWord: text,
                fromToLanguages: [from, to],
                inDictionaries: appleDictionaries
            )
            result.htmlString = htmlString

            let error: QueryError? = htmlString?.isEmpty != false ? noResultError : nil
            completion(result, error)
        }
    }

    override func detectText(
        _ text: String,
        completion: @escaping (Language, (any Error)?) -> Void
    ) {
        let languageDict = TTTDictionary.languageToDictionaryNameMap
        let supportedLanguages = languageDict.allKeys() as? [Language] ?? []

        if let matchedLanguage = supportedLanguages.first(where: {
            queryDictionary(forText: text, language: $0)
        }) {
            completion(matchedLanguage, nil)
        } else {
            completion(.auto, nil)
        }
    }

    override func ocr(
        _ queryModel: EZQueryModel,
        completion: @escaping (EZOCRResult?, (any Error)?) -> Void
    ) {
        logError("Apple Dictionary does not support ocr")
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
        -> String?
    {
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
        -> String?
    {
        let startTime = CFAbsoluteTimeGetCurrent()

        let fromLanguage = languages?.first

        guard let baseHtmlPath = Bundle.main.path(forResource: "apple-dictionary", ofType: "html"),
            let baseHtmlString = try? String(contentsOfFile: baseHtmlPath, encoding: .utf8)
        else {
            return nil
        }

        let lightTextColorString = NSColor.mm_hexString(from: NSColor.ez_resultTextLight())
        let lightBackgroundColorString = NSColor.mm_hexString(from: NSColor.ez_resultViewBgLight())
        let darkBackgroundColorString = NSColor.mm_hexString(from: NSColor.ez_resultViewBgDark())

        let bigWordTitleH2Class = "big-word-title"
        let customIframeContainerClass = "custom-iframe-container"

        let customCSS = """
            <style>\
            .\(customIframeContainerClass) { margin-top: 0px; margin-bottom: 0px; width: 100%; }\
            body { margin: 10px; color: \(lightTextColorString); background-color: \(lightBackgroundColorString
        ); font-family: 'system-ui'; }\
            @media (prefers-color-scheme: dark) { \
            body {\
            background-color: \(darkBackgroundColorString);\
            filter: invert(0.85) hue-rotate(185deg) saturate(200%) brightness(120%);\
            }\
            }\
            </style>
            """

        var iframesHtmlString = ""
        var bigWordHtml = "<h2 class=\"\(bigWordTitleH2Class)\">\(word)</h2>"

        for dictionary in dictionaries {
            var wordHtmlString = ""

            // ~/Library/Dictionaries/Apple.dictionary/Contents/
            let contentsURL = dictionary.dictionaryURL.appendingPathComponent("Contents")

            let entryHTMLs = queryEntryHTMLs(
                ofWord: word, inDictionary: dictionary, language: fromLanguage
            )
            result.htmlStrings = entryHTMLs

            for html in entryHTMLs {
                let absolutePathHTML = replacedAudioPath(
                    ofHTML: html, withBasePath: contentsURL.path
                )
                wordHtmlString += absolutePathHTML
            }

            if !wordHtmlString.isEmpty {
                let dictHTML = "\(customCSS)\n\n\(wordHtmlString)"

                // Create an iframe for each HTML content
                let escapedDictHTML = (dictHTML as NSString).escapedXML()
                let iframeHTML =
                    "<iframe class=\"\(customIframeContainerClass)\" srcdoc=\"\(escapedDictHTML)\"></iframe>"

                let dictName = dictionary.shortName
                let detailsSummaryHtml =
                    "\(bigWordHtml)<details open><summary>\(dictName)</summary> \(iframeHTML) </details>"

                bigWordHtml = ""
                iframesHtmlString += detailsSummaryHtml

                // Save dict HTML to file
                saveDictHTML(dictHTML, dictName: dictName)
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        logInfo("Query all dicts cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

        var htmlString: String?
        if !iframesHtmlString.isEmpty {
            let replacedString = "\(iframesHtmlString) </body>"
            htmlString = baseHtmlString.replacingOccurrences(of: "</body>", with: replacedString)

            // Save all dict HTML
            let dictionaryURL = TTTDictionary.userDictionaryDirectoryURL()
            let htmlDirectory = dictionaryURL.appendingPathComponent(kHTMLDirectory).path
            let filePath = "\(htmlDirectory)/\(kHTMLDictFilePath)"
            htmlFilePath = filePath
            try? htmlString?.write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        return htmlString
    }

    // MARK: Private

    private func queryEntryHTMLs(
        ofWord word: String,
        inDictionaryName name: String,
        language: Language?
    )
        -> [String]
    {
        let dictionary = TTTDictionary(named: name)
        return queryEntryHTMLs(ofWord: word, inDictionary: dictionary, language: language)
    }

    private func queryEntryHTMLs(
        ofWord word: String,
        inDictionary dictionary: TTTDictionary,
        language: Language?
    )
        -> [String]
    {
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

        result.innerTexts = texts

        return entryHTMLs
    }

    private func saveDictHTML(_ dictHTML: String, dictName: String) {
        let dictionaryURL = TTTDictionary.userDictionaryDirectoryURL()
        let htmlDirectory = dictionaryURL.appendingPathComponent(kHTMLDirectory).path

        // Create if not exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: htmlDirectory) {
            do {
                try fileManager.createDirectory(
                    atPath: htmlDirectory, withIntermediateDirectories: true
                )
            } catch {
                logError("createDirectoryAtPath error: \(error)")
            }
        }

        let htmlFilePath = "\(htmlDirectory)/\(dictName).html"
        do {
            try dictHTML.write(toFile: htmlFilePath, atomically: true, encoding: .utf8)
        } catch {
            logError("writeToFile error: \(error)")
        }
    }
}

// MARK: - Path Replacement Methods

extension AppleDictionary {
    // MARK: Private

    /// Replace HTML all audio relative path with absolute path
    ///
    /// &quot; is " in HTML
    ///
    /// javascript:new Audio(&quot;uk/apple__gb_1.mp3&quot;) -->
    /// javascript:new Audio('/Users/tisfeng/Library/Contents/uk/apple__gb_1.mp3')
    private func replacedAudioPath(ofHTML html: String, withBasePath basePath: String) -> String {
        let pattern = "new Audio\\((.*?)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return html
        }

        var mutableHTML = html
        let matches = regex.matches(
            in: mutableHTML, range: NSRange(mutableHTML.startIndex..., in: mutableHTML)
        )

        // Process matches in reverse order to preserve indices
        for match in matches.reversed() {
            guard let matchRange = Range(match.range(at: 1), in: mutableHTML) else { continue }

            let filePath = String(mutableHTML[matchRange])
            let relativePath = filePath.replacingOccurrences(of: "&quot;", with: "")

            var fileBasePath = basePath

            let components = relativePath.components(separatedBy: "/")
            let isDirectoryPath = components.count > 1
            if isDirectoryPath, let directoryName = components.first {
                if let directoryPath = findFilePath(
                    inDirectory: basePath, withTargetDirectory: directoryName
                ) {
                    fileBasePath = (directoryPath as NSString).deletingLastPathComponent
                }
            }

            let absolutePath = (fileBasePath as NSString).appendingPathComponent(relativePath)
            let replacement = "new Audio('\(absolutePath)')"

            if let fullMatchRange = Range(match.range, in: mutableHTML) {
                mutableHTML.replaceSubrange(fullMatchRange, with: replacement)
            }
        }

        return mutableHTML
    }

    /// Find file path in directory.
    private func findFilePath(
        inDirectory directoryPath: String,
        withTargetDirectory targetDirectory: String
    )
        -> String?
    {
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(atPath: directoryPath) else {
            return nil
        }

        for content in contents {
            let fullPath = (directoryPath as NSString).appendingPathComponent(content)

            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory)

            if isDirectory.boolValue {
                if content == targetDirectory {
                    return fullPath
                }

                if let subDirectoryPath = findFilePath(
                    inDirectory: fullPath, withTargetDirectory: targetDirectory
                ) {
                    return subDirectoryPath
                }
            }
        }

        return nil
    }
}

// MARK: - Headword Validation

extension AppleDictionary {
    // MARK: Private

    private func isValidHeadword(_ headword: String, queryWord word: String, language: Language?)
        -> Bool
    {
        // Convert to case-insensitive and accent-insensitive normalized string
        let normalizedWord = (word as NSString).folded()
        let normalizedHeadword = (headword as NSString).folded()

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

            let simplifiedWord = (normalizedWord as NSString).toSimplifiedChineseText()
            let simplifiedHeadword = (normalizedHeadword as NSString).toSimplifiedChineseText()

            let pureChineseHeadwords =
                ((simplifiedHeadword as NSString).removeAlphabet() as NSString).trim()
            let hasWordSubstring = pureChineseHeadwords.contains(simplifiedWord as String)
            return hasWordSubstring
        }

        // If text is not Chinese
        let isQueryDictionary: Bool
        if let language {
            isQueryDictionary = (word as NSString).shouldQueryDictionary(
                withLanguage: language, maxWordCount: 1
            )
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
                    splitWord.contains(splitHeadword)
                {
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
