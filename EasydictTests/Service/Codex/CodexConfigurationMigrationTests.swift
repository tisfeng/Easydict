//
//  CodexConfigurationMigrationTests.swift
//  EasydictTests
//
//  Created by Alfred on 2026/09/07.
//

@testable import Easydict
import Foundation
import Testing

// MARK: - CodexConfigurationMigrationTests

@Suite("Codex configuration migration")
struct CodexConfigurationMigrationTests {
    @Test("does not treat factory defaults as persisted Codex history")
    func ignoresEmptyAndUnrelatedSnapshots() {
        #expect(CodexConfigurationMigration.legacyUUIDs(in: [:]).isEmpty)

        let snapshot: [String: Any] = [
            "kAllServiceTypesKey-window-a": ["OpenAI", "DeepSeek"],
            "EZOpenAIModel_orphaned_Key": "",
        ]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot).isEmpty)
    }

    @Test("finds default and custom Codex instances persisted by separate windows")
    func findsPersistedInstancesAcrossWindowLists() {
        let snapshot: [String: Any] = [
            "kAllServiceTypesKey-window-a": ["CodexCLI", "CodexCLI#first"],
            "kAllServiceTypesKey-window-b": ["CodexCLI#second"],
        ]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot) == Set(["", "first", "second"]))
    }

    @Test("finds disabled legacy instance from archived service info data")
    func findsDisabledInstanceFromServiceInfoData() {
        let uuid = "disabled-instance"
        let snapshot: [String: Any] = [
            "kServiceInfoStorageKey-CodexCLI-\(uuid)-serviceUsageStatus": Data(),
        ]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot) == Set([uuid]))
    }

    @Test("finds removed Codex instance when empty model settings remain")
    func findsRemovedInstanceFromEmptyConfiguration() {
        let uuid = "removed-instance"
        let snapshot: [String: Any] = [
            "EZCodexCLIModel_\(uuid)_Key": "",
            "EZCodexCLIReasoningEffort_\(uuid)_Key": "",
        ]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot) == Set([uuid]))
    }

    @Test("recognizes retired managed settings without normalizing their values")
    func recognizesLegacySelectionsAsMigrationEvidence() {
        let uuid = "retired-managed-selection"
        let modelKey = "EZCodexCLIModel_\(uuid)_Key"
        let effortKey = "EZCodexCLIReasoningEffort_\(uuid)_Key"
        let snapshot: [String: Any] = [
            modelKey: "gpt-5.4-mini",
            effortKey: "ultra",
        ]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot) == Set([uuid]))
        #expect(snapshot[modelKey] as? String == "gpt-5.4-mini")
        #expect(snapshot[effortKey] as? String == "ultra")
    }

    @Test("does not infer migration from an unread default model")
    func ignoresDefaultModelThatWasNeverPersisted() {
        let snapshot: [String: Any] = ["kQueryServiceRecordKey": queryRecord(service: "OpenAI", count: 1)]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot).isEmpty)
    }

    @Test("retains explicit current and future access-mode values")
    func excludesInstancesThatAlreadyHaveAnyModeValue() {
        let managedUUID = "managed"
        let localUUID = "local"
        let futureUUID = "future"
        let snapshot: [String: Any] = [
            "kAllServiceTypesKey-window": [
                "CodexCLI#\(managedUUID)",
                "CodexCLI#\(localUUID)",
                "CodexCLI#\(futureUUID)",
            ],
            CodexAccessMode.key(uuid: managedUUID).name: CodexAccessMode.managed.rawValue,
            CodexAccessMode.key(uuid: localUUID).name: CodexAccessMode.localCLI.rawValue,
            CodexAccessMode.key(uuid: futureUUID).name: "a-future-mode",
        ]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot).isEmpty)
    }

    @Test("uses only a positive persisted Codex query count as legacy evidence")
    func requiresPositiveCodexQueryCount() {
        let noQueries: [String: Any] = ["kQueryServiceRecordKey": queryRecord(service: "CodexCLI", count: 0)]
        let negativeQueries: [String: Any] = ["kQueryServiceRecordKey": queryRecord(service: "CodexCLI", count: -1)]
        let positiveQueries: [String: Any] = ["kQueryServiceRecordKey": queryRecord(service: "CodexCLI", count: 1)]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: noQueries).isEmpty)
        #expect(CodexConfigurationMigration.legacyUUIDs(in: negativeQueries).isEmpty)
        #expect(CodexConfigurationMigration.legacyUUIDs(in: positiveQueries) == Set([""]))
    }

    @Test("becomes a no-op after the caller writes the migrated mode")
    func isIdempotentAfterModeWrite() {
        let uuid = "legacy-instance"
        var snapshot: [String: Any] = [
            "kAllServiceTypesKey-window": ["CodexCLI#\(uuid)"],
        ]

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot) == Set([uuid]))

        snapshot[CodexAccessMode.key(uuid: uuid).name] = CodexAccessMode.localCLI.rawValue

        #expect(CodexConfigurationMigration.legacyUUIDs(in: snapshot).isEmpty)
    }
}

private func queryRecord(service: String, count: Int) -> [String: [String: Any]] {
    [service: ["queryCount": NSNumber(value: count)]]
}
