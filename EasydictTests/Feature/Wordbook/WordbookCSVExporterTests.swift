//
//  WordbookCSVExporterTests.swift
//  EasydictTests
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - WordbookCSVExporterTests

/// Verifies the exact CSV contract for ordered wordbook and history inputs,
/// including schemas, encoding, escaping, timestamps, and the 10k-row case.
@Suite("Wordbook CSV Exporter", .tags(.wordbook, .unit))
struct WordbookCSVExporterTests {
    @Test(
        "Wordbook has exact fields, ordered rows, localized names, UTC dates, and CRLF"
    )
    func wordbookFields() {
        let group = WordbookFixture.group(name: "Study")
        let grouped = WordbookFixture.entry(
            text: "grouped",
            groupID: group.id,
            note: "note",
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 60)
        )
        let ungrouped = WordbookFixture.entry(
            text: "ungrouped",
            fromLanguage: .simplifiedChinese,
            toLanguage: .english,
            createdAt: Date(timeIntervalSince1970: 120),
            updatedAt: Date(timeIntervalSince1970: 180)
        )

        let csv = WordbookCSVExporter().makeWordbookCSV(
            entries: [grouped, ungrouped],
            groups: [group],
            ungroupedName: "Passed Ungrouped",
            languageName: { "lang:\($0.rawValue)" }
        )
        let expected = "text,fromLanguage,toLanguage,note,group,createdAt,updatedAt\r\n"
            + "grouped,lang:English,lang:Simplified-Chinese,note,Study,"
            + "1970-01-01T00:00:00Z,1970-01-01T00:01:00Z\r\n"
            + "ungrouped,lang:Simplified-Chinese,lang:English,,Passed Ungrouped,"
            + "1970-01-01T00:02:00Z,1970-01-01T00:03:00Z\r\n"
        let rows = csv.components(separatedBy: "\r\n")
        let contentWithoutRowBreaks = csv.replacingOccurrences(of: "\r\n", with: "")

        #expect(csv == expected)
        #expect(rows.count == 4)
        #expect(rows.dropLast().allSatisfy {
            $0.split(separator: ",", omittingEmptySubsequences: false).count == 7
        })
        #expect(!contentWithoutRowBreaks.contains("\r"))
        #expect(!contentWithoutRowBreaks.contains("\n"))
        #expect(csv.data(using: .utf8) != nil)
    }

    @Test("Comma, quote, CR, and LF fields are quoted and quotes are doubled")
    func escaping() {
        let entry = WordbookFixture.entry(
            text: "say \"hello\", now",
            note: "line 1\rline 2\nline 3"
        )

        let csv = WordbookCSVExporter().makeWordbookCSV(
            entries: [entry],
            groups: [],
            ungroupedName: "Ungrouped",
            languageName: { $0.rawValue }
        )

        #expect(csv.contains(#""say ""hello"", now""#))
        #expect(csv.contains("\"line 1\rline 2\nline 3\""))
    }

    @Test("A quote-only field is enclosed and doubled")
    func quoteOnly() {
        let entry = WordbookFixture.entry(text: "a\"b")

        let csv = WordbookCSVExporter().makeWordbookCSV(
            entries: [entry],
            groups: [],
            ungroupedName: "Ungrouped",
            languageName: { $0.rawValue }
        )

        #expect(csv.contains(#""a""b""#))
    }

    @Test("History keeps its exact ordered five-column schema")
    func historySchema() {
        var first = WordbookFixture.favorite(
            text: "first",
            timestamp: Date(timeIntervalSince1970: 0)
        )
        first.translatedResult = #"translation "one""#
        let second = WordbookFixture.favorite(
            text: "second",
            fromLanguage: .simplifiedChinese,
            toLanguage: .english,
            timestamp: Date(timeIntervalSince1970: 60)
        )

        let csv = WordbookCSVExporter().makeHistoryCSV(
            records: [first, second],
            languageName: { "localized:\($0.rawValue)" }
        )
        let expected = "queryText,queryFromLanguage,queryToLanguage,translatedResult,timestamp\r\n"
            + "first,localized:English,localized:Simplified-Chinese,"
            + #""translation ""one""","#
            + "1970-01-01T00:00:00Z\r\n"
            + "second,localized:Simplified-Chinese,localized:English,,"
            + "1970-01-01T00:01:00Z\r\n"
        let rows = csv.components(separatedBy: "\r\n")

        #expect(csv == expected)
        #expect(rows.dropLast().allSatisfy {
            $0.split(separator: ",", omittingEmptySubsequences: false).count == 5
        })
    }

    @Test("Ten thousand ordered rows export without truncation", .tags(.performance))
    func tenThousandRows() {
        let entries = (0 ..< 10_000).map {
            WordbookFixture.entry(text: "entry \($0)")
        }

        let csv = WordbookCSVExporter().makeWordbookCSV(
            entries: entries,
            groups: [],
            ungroupedName: "Ungrouped",
            languageName: { $0.rawValue }
        )
        let rows = csv.components(separatedBy: "\r\n")

        #expect(rows.count == 10_002)
        #expect(rows[1].hasPrefix("entry 0,"))
        #expect(rows[10_000].hasPrefix("entry 9999,"))
    }
}
