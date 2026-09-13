//
//  WordbookQueryTests.swift
//  EasydictTests
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - WordbookQueryTests

/// Verifies pure wordbook and history projections across scope, search, and
/// deterministic sort boundaries, including the in-memory 10k capacity case.
@Suite("Wordbook Query", .tags(.wordbook, .unit))
struct WordbookQueryTests {
    @Test("Scope and localized case-insensitive search use text and note")
    func scopeAndSearch() {
        let group = WordbookFixture.group(name: "Primary")
        let otherGroup = WordbookFixture.group(name: "Other")
        var inGroup = WordbookFixture.entry(
            text: "Résumé",
            note: "Interview"
        )
        inGroup.groupID = group.id
        let ungrouped = WordbookFixture.entry(
            text: "Other",
            note: "résumé later"
        )
        let elsewhere = WordbookFixture.entry(
            text: "Elsewhere",
            groupID: otherGroup.id
        )
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [ungrouped, elsewhere, inGroup],
            groups: [group, otherGroup],
            defaultGroupID: nil
        )
        let query = WordbookQuery()
        let locale = Locale(identifier: "en_US")

        #expect(query.entries(
            in: snapshot,
            scope: .group(group.id),
            searchText: "rÉSuMÉ",
            sortOrder: .newest,
            locale: locale
        ).map(\.id) == [inGroup.id])
        #expect(query.entries(
            in: snapshot,
            scope: .group(group.id),
            searchText: "interVIEW",
            sortOrder: .newest,
            locale: locale
        ).map(\.id) == [inGroup.id])
        #expect(query.entries(
            in: snapshot,
            scope: .ungrouped,
            searchText: "RÉSUMÉ",
            sortOrder: .newest,
            locale: locale
        ).map(\.id) == [ungrouped.id])
        let all = query.entries(
            in: snapshot,
            scope: .all,
            searchText: "",
            sortOrder: .newest,
            locale: locale
        )
        #expect(Set(all.map(\.id)) == Set([
            inGroup.id,
            ungrouped.id,
            elsewhere.id,
        ]))
    }

    @Test("Search preserves diacritic differences")
    func diacriticsMatter() {
        let accented = WordbookFixture.entry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            text: "café"
        )
        let plain = WordbookFixture.entry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            text: "cafe"
        )
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = [accented, plain]

        let results = WordbookQuery().entries(
            in: snapshot,
            scope: .all,
            searchText: "cafe",
            sortOrder: .newest,
            locale: Locale(identifier: "en_US")
        )

        #expect(results.map(\.id) == [plain.id])
    }

    @Test("Wordbook sorts use deterministic time text and identifier ties")
    func stableEntrySorts() {
        let zulu = WordbookFixture.entry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            text: "Zulu",
            createdAt: Date(timeIntervalSince1970: 1)
        )
        let lateAlpha = WordbookFixture.entry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            text: "alpha",
            createdAt: Date(timeIntervalSince1970: 2)
        )
        let lateBravo = WordbookFixture.entry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            text: "Bravo",
            createdAt: Date(timeIntervalSince1970: 2)
        )
        let earlyAlphaLow = WordbookFixture.entry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            text: "ALPHA",
            createdAt: Date(timeIntervalSince1970: 1)
        )
        let earlyAlphaHigh = WordbookFixture.entry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            text: "Alpha",
            createdAt: Date(timeIntervalSince1970: 1)
        )
        let snapshot = WordbookSnapshot(
            schemaVersion: 1,
            entries: [earlyAlphaHigh, lateBravo, zulu, earlyAlphaLow, lateAlpha],
            groups: [],
            defaultGroupID: nil
        )
        let query = WordbookQuery()
        let locale = Locale(identifier: "en_US")

        #expect(query.entries(
            in: snapshot,
            scope: .all,
            searchText: "",
            sortOrder: .newest,
            locale: locale
        ).map(\.id) == [
            lateAlpha.id,
            lateBravo.id,
            zulu.id,
            earlyAlphaLow.id,
            earlyAlphaHigh.id,
        ])
        #expect(query.entries(
            in: snapshot,
            scope: .all,
            searchText: "",
            sortOrder: .oldest,
            locale: locale
        ).map(\.id) == [
            zulu.id,
            earlyAlphaLow.id,
            earlyAlphaHigh.id,
            lateAlpha.id,
            lateBravo.id,
        ])
        #expect(query.entries(
            in: snapshot,
            scope: .all,
            searchText: "",
            sortOrder: .text,
            locale: locale
        ).map(\.id) == [
            earlyAlphaLow.id,
            earlyAlphaHigh.id,
            lateAlpha.id,
            lateBravo.id,
            zulu.id,
        ])
    }

    @Test("History search sorts both directions with identifier ties")
    func stableHistorySorts() {
        let tiedLow = WordbookFixture.favorite(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            text: "Target first",
            timestamp: Date(timeIntervalSince1970: 2)
        )
        let tiedHigh = WordbookFixture.favorite(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            text: "target second",
            timestamp: Date(timeIntervalSince1970: 2)
        )
        let old = WordbookFixture.favorite(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
            text: "TARGET old",
            timestamp: Date(timeIntervalSince1970: 1)
        )
        let excluded = WordbookFixture.favorite(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
            text: "Other",
            timestamp: Date(timeIntervalSince1970: 3)
        )
        let records = [tiedHigh, excluded, old, tiedLow]
        let query = WordbookQuery()
        let locale = Locale(identifier: "en_US")

        #expect(query.history(
            records,
            searchText: "TaRgEt",
            sortOrder: .newest,
            locale: locale
        ).map(\.id) == [tiedLow.id, tiedHigh.id, old.id])
        #expect(query.history(
            records,
            searchText: "TaRgEt",
            sortOrder: .oldest,
            locale: locale
        ).map(\.id) == [old.id, tiedLow.id, tiedHigh.id])
    }

    @Test(
        "Ten thousand entries filter and sort without storage access",
        .tags(.performance)
    )
    func tenThousandSmoke() {
        var snapshot = WordbookSnapshot.empty
        snapshot.entries = (0 ..< 10_000).map { index in
            WordbookFixture.entry(
                text: index.isMultiple(of: 100)
                    ? "target \(index)"
                    : "entry \(index)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        let results = WordbookQuery().entries(
            in: snapshot,
            scope: .all,
            searchText: "TARGET",
            sortOrder: .newest
        )

        #expect(results.count == 100)
        #expect(results.first?.text == "target 9900")
        #expect(results.last?.text == "target 0")
    }
}
