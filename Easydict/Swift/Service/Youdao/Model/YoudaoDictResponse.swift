//
//  YoudaoModel.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - YoudaoDictResponse

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let youdaoDictResponse = try? JSONDecoder().decode(YoudaoDictResponse.self, from: jsonData)

// swiftlint:disable all
@available(*, deprecated)
struct YoudaoDictResponse: Codable {
    // MARK: - Baike

    struct Baike: Codable {
        let summarys: [SummaryElement]?
        let source: Source?
    }

    // MARK: - BaikeSource

    struct BaikeSource: Codable {
        let name: String?
        let url: String?
    }

    // MARK: - Source

    struct Source: Codable {
        let name: String?
        let url: String?
    }

    // MARK: - SummaryElement

    struct SummaryElement: Codable {
        let summary, key: String?
    }

    // MARK: - Ec

    struct Ec: Codable {
        enum CodingKeys: String, CodingKey {
            case examType = "exam_type"
            case source, word
        }

        let examType: [String]?
        let source: Source?
        let word: [EcWord]?
    }

    // MARK: - EcWord

    struct EcWord: Codable {
        enum CodingKeys: String, CodingKey {
            case usphone, ukphone, ukspeech, trs, wfs
            case returnPhrase = "return-phrase"
            case usspeech
        }

        let usphone: String?
        let ukphone: String?

        let ukspeech: String?
        let usspeech: String?

        let trs: [WordTr]?
        let wfs: [WfElement]?
        let returnPhrase: ReturnPhrase?
    }

    // MARK: - ReturnPhrase

    struct ReturnPhrase: Codable {
        let l: ReturnPhraseL?
    }

    // MARK: - ReturnPhraseL

    struct ReturnPhraseL: Codable {
        let i: String?
    }

    // MARK: - WordTr

    struct WordTr: Codable {
        let tr: [TrTr]?
    }

    // MARK: - TrTr

    struct TrTr: Codable {
        let l: TrL?
    }

    // MARK: - TrL

    struct TrL: Codable {
        let i: [String]?
    }

    // MARK: - WfElement

    struct WfElement: Codable {
        let wf: WfWf?
    }

    // MARK: - WfWf

    struct WfWf: Codable {
        let name, value: String?
    }

    // MARK: - Meta

    struct Meta: Codable {
        /**
         "input": "美",
         "guessLanguage": "zh",
         "isHasSimpleDict": "1",
         "le": "en",
         "lang": "eng",
         */
        let input: String
        let guessLanguage: String
        let isHasSimpleDict: String
        let le: String
        let lang: String

        let dicts: [String]?
    }

    // MARK: - Simple

    struct Simple: Codable {
        let query: String?
        let word: [SimpleWord]?
    }

    // MARK: - SimpleWord

    struct SimpleWord: Codable {
        enum CodingKeys: String, CodingKey {
            case usphone, ukphone, ukspeech
            case returnPhrase = "return-phrase"
            case usspeech, collegeExamVoice
        }

        let usphone, ukphone, ukspeech, returnPhrase: String?
        let usspeech: String?
        let collegeExamVoice: CollegeExamVoice?
    }

    // MARK: - CollegeExamVoice

    struct CollegeExamVoice: Codable {
        let speechWord: String?
    }

    // MARK: - WebTrans

    struct WebTrans: Codable {
        enum CodingKeys: String, CodingKey {
            case webTranslation = "web-translation"
        }

        let webTranslation: [WebTranslation]?
    }

    // MARK: - WebTranslation

    struct WebTranslation: Codable {
        enum CodingKeys: String, CodingKey {
            case same = "@same"
            case key
            case keySpeech = "key-speech"
            case trans
        }

        let same: String?
        let key: String
        let keySpeech: String?
        let trans: [Tran]?
    }

    // MARK: - Tran

    struct Tran: Codable {
        let summary: TranSummary?
        let value: String?
        let support: Int?
        let url: String?
    }

    // MARK: - TranSummary

    struct TranSummary: Codable {
        let line: [String]?
    }

    // EC dict

    // MARK: - BlngSentsPart

    struct BlngSentsPart: Codable {
        enum CodingKeys: String, CodingKey {
            case sentenceCount = "sentence-count"
            case sentencePair = "sentence-pair"
            case more
            case trsClassify = "trs-classify"
        }

        let sentenceCount: Int?
        let sentencePair: [SentencePair]?
        let more: String?
        let trsClassify: [TrsClassify]?
    }

    // MARK: - SentencePair

    struct SentencePair: Codable {
        enum CodingKeys: String, CodingKey {
            case sentence
            case sentenceTranslationSpeech = "sentence-translation-speech"
            case sentenceEng = "sentence-eng"
            case sentenceTranslation = "sentence-translation"
            case speechSize = "speech-size"
            case alignedWords = "aligned-words"
            case source, url
        }

        let sentence, sentenceTranslationSpeech, sentenceEng, sentenceTranslation: String?
        let speechSize: String?
        let alignedWords: AlignedWords?
        let source: String?
        let url: String?
    }

    // MARK: - AlignedWords

    struct AlignedWords: Codable {
        let src, tran: Src?
    }

    // MARK: - Src

    struct Src: Codable {
        let chars: [Char]?
    }

    // MARK: - Char

    struct Char: Codable {
        enum CodingKeys: String, CodingKey {
            case s = "@s"
            case e = "@e"
            case aligns
            case id = "@id"
        }

        let s, e: String?
        let aligns: Aligns?
        let id: String?
    }

    // MARK: - Aligns

    struct Aligns: Codable {
        let sc, tc: [Sc]?
    }

    // MARK: - Sc

    struct Sc: Codable {
        enum CodingKeys: String, CodingKey {
            case id = "@id"
        }

        let id: String?
    }

    // MARK: - TrsClassify

    struct TrsClassify: Codable {
        let proportion, tr: String?
    }

    // MARK: - Ce

    struct Ce: Codable {
        let source: BaikeSource?
        let word: [CeWord]?
    }

    // MARK: - CeWord

    struct CeWord: Codable {
        enum CodingKeys: String, CodingKey {
            case trs, phone
            case returnPhrase = "return-phrase"
        }

        let trs: [PurpleTr]?
        let phone: String?
        let returnPhrase: ReturnPhrase?
    }

    // MARK: - PurpleTr

    struct PurpleTr: Codable {
        let tr: [FluffyTr]?
    }

    // MARK: - FluffyTr

    struct FluffyTr: Codable {
        let l: PurpleL?
    }

    // MARK: - PurpleL

    struct PurpleL: Codable {
        enum CodingKeys: String, CodingKey {
            case pos, i
            case tran = "#tran"
        }

        let pos: String?
        let i: [IElement]?
        let tran: String?
    }

    enum IElement: Codable {
        case ii(TextWord)
        case string(String)

        // MARK: Lifecycle

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let x = try? container.decode(String.self) {
                self = .string(x)
                return
            }
            if let x = try? container.decode(TextWord.self) {
                self = .ii(x)
                return
            }
            throw DecodingError.typeMismatch(
                IElement.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath, debugDescription: "Wrong type for IElement"
                )
            )
        }

        // MARK: Internal

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .ii(x):
                try container.encode(x)
            case let .string(x):
                try container.encode(x)
            }
        }
    }

    // MARK: - II

    struct TextWord: Codable {
        enum CodingKeys: String, CodingKey {
            case text = "#text"
            case action = "@action"
            case href = "@href"
        }

        let text, action, href: String?
    }

    // MARK: - CeNew

    struct CeNew: Codable {
        let source: CeNewSource?
        let word: [CeNewWord]?
    }

    // MARK: - CeNewSource

    struct CeNewSource: Codable {
        let name: String?
    }

    // MARK: - CeNewWord

    struct CeNewWord: Codable {
        enum CodingKeys: String, CodingKey {
            case trs, phone
            case returnPhrase = "return-phrase"
        }

        let trs: [TentacledTr]?
        let phone: String?
        let returnPhrase: PurpleReturnPhrase?
    }

    // MARK: - PurpleReturnPhrase

    struct PurpleReturnPhrase: Codable {
        let l: FluffyL?
    }

    // MARK: - FluffyL

    struct FluffyL: Codable {
        let i: [String]?
    }

    // MARK: - TentacledTr

    struct TentacledTr: Codable {
        let pos: String?
        let tr: [StickyTr]?
    }

    // MARK: - StickyTr

    struct StickyTr: Codable {
        let exam: [Exam]?
        let l: FluffyL?
    }

    // MARK: - Exam

    struct Exam: Codable {
        let i: ExamI?
    }

    // MARK: - ExamI

    struct ExamI: Codable {
        let f, n: ReturnPhrase?
    }

    // MARK: - MediaSentsPart

    struct MediaSentsPart: Codable {
        enum CodingKeys: String, CodingKey {
            case sentenceCount = "sentence-count"
            case more, query, sent
        }

        let sentenceCount: Int?
        let more, query: String?
        let sent: [Sent]?
    }

    // MARK: - Sent

    struct Sent: Codable {
        enum CodingKeys: String, CodingKey {
            case mediatype = "@mediatype"
            case snippets, chn, eng
        }

        let mediatype: String?
        let snippets: Snippets?
        let chn, eng: String?
    }

    // MARK: - Snippets

    struct Snippets: Codable {
        let snippet: [Snippet]?
    }

    // MARK: - Snippet

    struct Snippet: Codable {
        enum CodingKeys: String, CodingKey {
            case streamURL = "streamUrl"
            case duration, swf, name, source, win8
            case sourceURL = "sourceUrl"
            case imageURL = "imageUrl"
        }

        let streamURL: String?
        let duration: String?
        let swf: String?
        let name, source: String?
        let win8: String?
        let sourceURL: String?
        let imageURL: String?
    }

    // MARK: - Newhh

    struct Newhh: Codable {
        let dataList: [NewhhDataList]?
        let source: CeNewSource?
        let word: String?
    }

    // MARK: - NewhhDataList

    struct NewhhDataList: Codable {
        let pinyin: String?
        let sense: [Sense]?
        let word: String?
    }

    // MARK: - Sense

    struct Sense: Codable {
        let examples: [String]?
        let def: [String]?
        let cat: String?
        let style: String?
    }

    // MARK: - Special

    struct Special: Codable {
        enum CodingKeys: String, CodingKey {
            case summary
            case coAdd = "co-add"
            case total, entries
        }

        let summary: SpecialSummary?
        let coAdd: String?
        let total: String?
        let entries: [EntryElement]?
    }

    // MARK: - EntryElement

    struct EntryElement: Codable {
        let entry: EntryEntry?
    }

    // MARK: - EntryEntry

    struct EntryEntry: Codable {
        let major: String?
        let trs: [EntryTr]?
        let num: Int?
    }

    // MARK: - EntryTr

    struct EntryTr: Codable {
        let tr: IndigoTr?
    }

    // MARK: - IndigoTr

    struct IndigoTr: Codable {
        let nat: String?
        let chnSent: String?
        let cite: String?
        let docTitle, engSent, url: String?
    }

    // MARK: - SpecialSummary

    struct SpecialSummary: Codable {
        let sources: Sources?
        let text: String?
    }

    // MARK: - Sources

    struct Sources: Codable {
        let source: SourcesSource?
    }

    // MARK: - SourcesSource

    struct SourcesSource: Codable {
        let site: String?
        let url: String?
    }

    // MARK: - Cls

    struct Cls: Codable {
        let cl: [String]?
    }

    // MARK: - Wuguanghua

    struct Wuguanghua: Codable {
        let dataList: [WuguanghuaDataList]?
        let source: CeNewSource?
        let word: String?
    }

    // MARK: - WuguanghuaDataList

    struct WuguanghuaDataList: Codable {
        let trs: [DataListTr]?
        let phone, speech: String?
    }

    // MARK: - DataListTr

    struct DataListTr: Codable {
        let pos: String?
        let tr: SentElement?
        let sents: [SentElement]?
        let rhetoric: String?
    }

    // MARK: - SentElement

    struct SentElement: Codable {
        let en, cn: String?
    }

    /**
     "fanyi": {
            "input": "人的一生，其实是很短暂的，但如果选择卑微地度过，却又太漫长了。《海贼法典》",
            "type": "zh-CHS2en",
            "tran": "Human life, in fact, is very short, but if you choose to spend humbly, it is too long. Seafarers Code"
        }
     */

    struct Fanyi: Codable {
        let input: String?
        let type: String?
        let tran: String?
        let voice: String?
    }

    // MARK: - AuthSentsPart

    struct AuthSentsPart: Codable {
        enum CodingKeys: String, CodingKey {
            case sentenceCount = "sentence-count"
            case more, sent
        }

        let sentenceCount: Int?
        let more: String?
        let sent: [AuthSentsPartSent]?
    }

    // MARK: - AuthSentsPartSent

    struct AuthSentsPartSent: Codable {
        enum CodingKeys: String, CodingKey {
            case score, speech
            case speechSize = "speech-size"
            case source, url, foreign
        }

        let score: Double?
        let speech, speechSize, source, url: String?
        let foreign: String?
    }

    // MARK: - Collins

    struct Collins: Codable {
        enum CodingKeys: String, CodingKey {
            case superHeadwords = "super_headwords"
            case collinsEntries = "collins_entries"
        }

        let superHeadwords: SuperHeadwords?
        let collinsEntries: [CollinsEntry]?
    }

    // MARK: - CollinsEntry

    struct CollinsEntry: Codable {
        enum CodingKeys: String, CodingKey {
            case superHeadword = "super_headword"
            case entries, phonetic
            case basicEntries = "basic_entries"
            case headword, star
        }

        let superHeadword: String?
        let entries: Entries?
        let phonetic: String?
        let basicEntries: BasicEntries?
        let headword, star: String?
    }

    // MARK: - BasicEntries

    struct BasicEntries: Codable {
        enum CodingKeys: String, CodingKey {
            case basicEntry = "basic_entry"
        }

        let basicEntry: [BasicEntry]?
    }

    // MARK: - BasicEntry

    struct BasicEntry: Codable {
        let cet: String?
        let headword: String?
        let wordforms: Wordforms?
    }

    // MARK: - Wordforms

    struct Wordforms: Codable {
        let wordform: [Wordform]?
    }

    // MARK: - Wordform

    struct Wordform: Codable {
        let word: String?
    }

    // MARK: - Entries

    struct Entries: Codable {
        let entry: [EntriesEntry]?
    }

    // MARK: - EntriesEntry

    struct EntriesEntry: Codable {
        enum CodingKeys: String, CodingKey {
            case tranEntry = "tran_entry"
        }

        let tranEntry: [TranEntry]?
    }

    // MARK: - TranEntry

    struct TranEntry: Codable {
        enum CodingKeys: String, CodingKey {
            case posEntry = "pos_entry"
            case examSents = "exam_sents"
            case tran, gram
            case boxExtra = "box_extra"
            case seeAlsos, headword, sees, loc
        }

        let posEntry: PosEntry?
        let examSents: ExamSents?
        let tran, gram, boxExtra: String?
        let seeAlsos: SeeAlsos?
        let headword: String?
        let sees: Sees?
        let loc: String?
    }

    // MARK: - ExamSents

    struct ExamSents: Codable {
        let sent: [ExamSentsSent]?
    }

    // MARK: - ExamSentsSent

    struct ExamSentsSent: Codable {
        enum CodingKeys: String, CodingKey {
            case chnSent = "chn_sent"
            case engSent = "eng_sent"
        }

        let chnSent, engSent: String?
    }

    // MARK: - PosEntry

    struct PosEntry: Codable {
        enum CodingKeys: String, CodingKey {
            case pos
            case posTips = "pos_tips"
        }

        let pos: Pos?
        let posTips: PosTips?
    }

    // MARK: - Pos

    enum Pos: String, Codable {
        case adj = "ADJ"
        case convention = "CONVENTION"
        case nSing = "N-SING"
        case nUncount = "N-UNCOUNT"
        case phrase = "PHRASE"
    }

    // MARK: - PosTips

    enum PosTips: String, Codable {
        case 不可数名词
        case 习惯表达
        case 习语
        case 单数型名词
        case 形容词
    }

    // MARK: - SeeAlsos

    struct SeeAlsos: Codable {
        let seealso: String?
        let seeAlso: [See]?
    }

    // MARK: - See

    struct See: Codable {
        let seeword: String?
    }

    // MARK: - Sees

    struct Sees: Codable {
        let see: [See]?
    }

    // MARK: - SuperHeadwords

    struct SuperHeadwords: Codable {
        enum CodingKeys: String, CodingKey {
            case superHeadword = "super_headword"
        }

        let superHeadword: [String]?
    }

    // MARK: - CollinsPrimary

    struct CollinsPrimary: Codable {
        let words: Words?
        let gramcat: [Gramcat]?
    }

    // MARK: - Gramcat

    struct Gramcat: Codable {
        let audiourl: String?
        let pronunciation: String?
        let senses: [GramcatSense]?
        let partofspeech, audio: String?
        let forms: [Form]?
        let phrases: [Phrase]?
    }

    // MARK: - Form

    struct Form: Codable {
        let form: String?
    }

    // MARK: - Phrase

    struct Phrase: Codable {
        let phrase: String?
        let senses: [PhraseSense]?
    }

    // MARK: - PhraseSense

    struct PhraseSense: Codable {
        let examples: [Example]?
        let definition: String?
        let lang: Lang?
        let word: String?
    }

    // MARK: - Example

    struct Example: Codable {
        let sense: ExampleSense?
        let example: String?
    }

    // MARK: - ExampleSense

    struct ExampleSense: Codable {
        let lang: Lang?
        let word: String?
    }

    // MARK: - Lang

    enum Lang: String, Codable {
        case zhCN = "ZH-CN"
    }

    // MARK: - GramcatSense

    struct GramcatSense: Codable {
        let sensenumber: String?
        let examples: [Example]?
        let definition: String?
        let lang: Lang?
        let word: String?
        let labelgrammar: String?
    }

    // MARK: - Words

    struct Words: Codable {
        let indexforms: [String]?
        let word: String?
    }

    // MARK: - Discriminate

    struct Discriminate: Codable {
        enum CodingKeys: String, CodingKey {
            case data
            case returnPhrase = "return-phrase"
        }

        let data: [Datum]?
        let returnPhrase: String?
    }

    // MARK: - Datum

    struct Datum: Codable {
        let source: String?
        let usages: [DatumUsage]?
        let headwords: [String]?
    }

    // MARK: - DatumUsage

    struct DatumUsage: Codable {
        let headword, usage: String?
    }

    // MARK: - SpecialElement

    struct SpecialElement: Codable {
        let nat, major: String?
    }

    // MARK: - IndividualTr

    struct IndividualTr: Codable {
        let pos: String?
        let tran: String?
    }

    // MARK: - Ee

    struct Ee: Codable {
        let source: BaikeSource?
        let word: EeWord?
    }

    // MARK: - EeWord

    struct EeWord: Codable {
        enum CodingKeys: String, CodingKey {
            case trs, phone, speech
            case returnPhrase = "return-phrase"
        }

        let trs: [PurpleTr]?
        let phone, speech, returnPhrase: String?
    }

    // MARK: - Etym

    struct Etym: Codable {
        let etyms: Etyms?
        let word: String?
    }

    // MARK: - Etyms

    struct Etyms: Codable {
        let zh: [ZhElement]?
    }

    // MARK: - ZhElement

    struct ZhElement: Codable {
        let source, word, value, url: String?
        let desc: String?
    }

    // MARK: - ExpandEc

    struct ExpandEc: Codable {
        enum CodingKeys: String, CodingKey {
            case returnPhrase = "return-phrase"
            case source, word
        }

        let returnPhrase: String?
        let source: BaikeSource?
        let word: [ExpandEcWord]?
    }

    // MARK: - ExpandEcWord

    struct ExpandEcWord: Codable {
        let transList: [TransList]?
        let pos: String?
        let wfs: [WfWf]?
    }

    // MARK: - TransList

    struct TransList: Codable {
        let content: Content?
        let trans: String?
    }

    // MARK: - Content

    struct Content: Codable {
        let detailPos: String?
        let examType: [Colloc]?
        let sents: [ContentSent]?
    }

    // MARK: - Colloc

    struct Colloc: Codable {
        let en: En?
        let zh: ZhEnum?
    }

    enum En: String, Codable {
        case cet4 = "CET4"
        case cet6 = "CET6"
        case goodJob = "Good job!"
        case goodMorningEvening = "good morning / evening"
        case graduateexam = "GRADUATEEXAM"
        case senior = "SENIOR"
    }

    // MARK: - ZhEnum

    enum ZhEnum: String, Codable {
        case 做得好 = "做得好！"
        case 六级
        case 四级
        case 早上好晚上好 = "早上好 / 晚上好"
        case 考研
        case 高考
    }

    // MARK: - ContentSent

    struct ContentSent: Codable {
        let sentOrig: String?
        let sourceType: SourceType?
        let sentSpeech, sentTrans, source: String?
        let usages: [SentUsage]?
        let type: En?
    }

    // MARK: - SourceType

    enum SourceType: String, Codable {
        case 权威
        case 真题
    }

    // MARK: - SentUsage

    struct SentUsage: Codable {
        let phrase, phraseTrans: String?
    }

    // MARK: - Individual

    struct Individual: Codable {
        enum CodingKeys: String, CodingKey {
            case trs, idiomatic, level, examInfo
            case returnPhrase = "return-phrase"
            case pastExamSents
        }

        let trs: [IndividualTr]?
        let idiomatic: [Idiomatic]?
        let level: String?
        let examInfo: ExamInfo?
        let returnPhrase: String?
        let pastExamSents: [PastExamSent]?
    }

    // MARK: - ExamInfo

    struct ExamInfo: Codable {
        let year: Int?
        let questionTypeInfo: [QuestionTypeInfo]?
        let recommendationRate, frequency: Int?
    }

    // MARK: - QuestionTypeInfo

    struct QuestionTypeInfo: Codable {
        let time: Int?
        let type: String?
    }

    // MARK: - Idiomatic

    struct Idiomatic: Codable {
        let colloc: Colloc?
    }

    // MARK: - PastExamSent

    struct PastExamSent: Codable {
        let en, source, zh: String?
    }

    // MARK: - MediaSentsPartSent

    struct MediaSentsPartSent: Codable {
        enum CodingKeys: String, CodingKey {
            case mediatype = "@mediatype"
            case snippets
            case speechSize = "speech-size"
            case eng, chn
        }

        let mediatype: String?
        let snippets: Snippets?
        let speechSize: String?
        let eng: String?
        let chn: String?
    }

    // MARK: - MusicSents

    struct MusicSents: Codable {
        enum CodingKeys: String, CodingKey {
            case sentsData = "sents_data"
            case more, word
        }

        let sentsData: [MusicSentsSentsDatum]?
        let more: Bool?
        let word: String?
    }

    // MARK: - MusicSentsSentsDatum

    struct MusicSentsSentsDatum: Codable {
        enum CodingKeys: String, CodingKey {
            case songName, lyricTranslation, singer, coverImg, supportCount, lyric, lyricList, id
            case songID = "songId"
            case playURL = "playUrl"
        }

        let songName, lyricTranslation, singer: String?
        let coverImg: String?
        let supportCount: Int?
        let lyric: String?
        let lyricList: [LyricList]?
        let id, songID: String?
        let playURL: String?
    }

    // MARK: - LyricList

    struct LyricList: Codable {
        let duration: Int?
        let lyricTranslation, lyric: String?
        let start: Int?
    }

    // MARK: - Oxford

    struct Oxford: Codable {
        let encryptedData: String?
    }

    // MARK: - Phrs

    struct Phrs: Codable {
        let word: String?
        let phrs: [Phr]?
    }

    // MARK: - Phr

    struct Phr: Codable {
        let headword, translation: String?
    }

    // MARK: - RelWordClass

    struct RelWordClass: Codable {
        let word, stem: String?
        let rels: [RelElement]?
    }

    // MARK: - RelElement

    struct RelElement: Codable {
        let rel: RelRel?
    }

    // MARK: - RelRel

    struct RelRel: Codable {
        let pos: String?
        let words: [RelWord]?
    }

    // MARK: - RelWord

    struct RelWord: Codable {
        let word, tran: String?
    }

    // MARK: - Senior

    struct Senior: Codable {
        let encryptedData: String?
        let source: SeniorSource?
    }

    // MARK: - SeniorSource

    struct SeniorSource: Codable {
        let name: String?
    }

    // MARK: - YoudaoDictResponseSpecial

    struct YoudaoDictResponseSpecial: Codable {
        enum CodingKeys: String, CodingKey {
            case summary
            case coAdd = "co-add"
            case total, entries
        }

        let summary: SpecialSummary?
        let coAdd: String?
        let total: String?
        let entries: [SpecialEntry]?
    }

    // MARK: - SpecialEntry

    struct SpecialEntry: Codable {
        let entry: EntryEntry?
    }

    // MARK: - YoudaoDictResponseSyno

    struct YoudaoDictResponseSyno: Codable {
        let synos: [SynoElement]?
        let word: String?
    }

    // MARK: - SynoElement

    struct SynoElement: Codable {
        let pos: String?
        let ws: [String]?
        let tran: String?
    }

    // MARK: - VideoSents

    struct VideoSents: Codable {
        enum CodingKeys: String, CodingKey {
            case sentsData = "sents_data"
            case wordInfo = "word_info"
        }

        let sentsData: [VideoSentsSentsDatum]?
        let wordInfo: WordInfo?
    }

    // MARK: - VideoSentsSentsDatum

    struct VideoSentsSentsDatum: Codable {
        enum CodingKeys: String, CodingKey {
            case videoCover = "video_cover"
            case contributor
            case subtitleSrt = "subtitle_srt"
            case id, video
        }

        let videoCover: String?
        let contributor, subtitleSrt: String?
        let id: Int?
        let video: String?
    }

    // MARK: - WordInfo

    struct WordInfo: Codable {
        enum CodingKeys: String, CodingKey {
            case returnPhrase = "return-phrase"
            case sense
        }

        let returnPhrase: String?
        let sense: [String]?
    }

    // MARK: - YoudaoDictResponseWordVideo

    struct YoudaoDictResponseWordVideo: Codable {
        enum CodingKeys: String, CodingKey {
            case wordVideos = "word_videos"
        }

        let wordVideos: [WordVideoElement]?
    }

    // MARK: - WordVideoElement

    struct WordVideoElement: Codable {
        let ad: Ad?
        let video: Video?
    }

    // MARK: - Ad

    struct Ad: Codable {
        let avatar: String?
        let title: String?
        let url: String?
    }

    // MARK: - Video

    struct Video: Codable {
        let cover: String?
        let image: String?
        let title: String?
        let url: String?
    }

    enum CodingKeys: String, CodingKey {
        case webTrans = "web_trans"
        case oxfordAdvanceHTML = "oxfordAdvanceHtml"
        case videoSents = "video_sents"
        case simple, phrs, oxford, syno, collins
        case wordVideo = "word_video"
        case webster, discriminate, lang, ec, ee
        case blngSentsPart = "blng_sents_part"
        case individual
        case collinsPrimary = "collins_primary"
        case relWord = "rel_word"
        case authSentsPart = "auth_sents_part"
        case mediaSentsPart = "media_sents_part"
        case expandEc = "expand_ec"
        case etym, special, senior, input
        case musicSents = "music_sents"
        case baike, meta, le, oxfordAdvance
        case ce, wuguanghua
        case ceNew = "ce_new"
        case newhh, fanyi
        case wikipediaDigest = "wikipedia_digest"
    }

    let input: String
    let meta: Meta
    let le: String // en
    let lang: String // eng

    let baike: Baike?
    let webTrans: WebTrans?
    let simple: Simple?
    let ec: Ec?

    // ec dict
    let blngSentsPart: BlngSentsPart?
    let ce: Ce?
    let wuguanghua: Wuguanghua?
    let ceNew: CeNew?
    let mediaSentsPart: MediaSentsPart?
    let special: Special?
    let newhh: Newhh?

    let fanyi: Fanyi?

    let oxfordAdvanceHTML: Oxford?
    let videoSents: VideoSents?
    let phrs: Phrs?
    let oxford: Oxford?
    let syno: YoudaoDictResponseSyno?
    let collins: Collins?
    let wordVideo: YoudaoDictResponseWordVideo?
    let webster: Oxford?
    let discriminate: Discriminate?
    let ee: Ee?
    let individual: Individual?
    let collinsPrimary: CollinsPrimary?
    let relWord: RelWordClass?
    let authSentsPart: AuthSentsPart?
    let expandEc: ExpandEc?
    let etym: Etym?
    let senior: Senior?
    let musicSents: MusicSents?
    let oxfordAdvance: Oxford?

    let wikipediaDigest: Baike?
}

// swiftlint:enable all
