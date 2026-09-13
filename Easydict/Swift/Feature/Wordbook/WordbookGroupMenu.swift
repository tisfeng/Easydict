//
//  WordbookGroupMenu.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import SFSafeSymbols
import SwiftUI

// MARK: - WordbookGroupMenu

/// Presents scope selection and flat group management in one native macOS
/// menu. Browsing remains available during persistence, while every create,
/// default, rename, reorder, and delete command follows the supplied mutation
/// gate and reports intent to the owning view model.
struct WordbookGroupMenu: View {
    // MARK: Internal

    let groups: [WordbookGroup]
    let scope: WordbookGroupScope
    let defaultGroupID: UUID?
    let count: Int
    let canMutate: Bool
    let onSelect: (WordbookGroupScope) -> ()
    let onCreate: () -> ()
    let onSetDefault: (UUID?) -> ()
    let onRename: (WordbookGroup) -> ()
    let onMove: (WordbookGroup, Int) -> ()
    let onDelete: (WordbookGroup) -> ()

    var body: some View {
        Menu {
            scopeButton(.all, title: Text("wordbook.group.all"))
            scopeButton(
                .ungrouped,
                title: Text("wordbook.group.ungrouped"),
                isDefault: defaultGroupID == nil
            )
            ForEach(groups) { group in
                scopeButton(
                    .group(group.id),
                    title: Text(group.name),
                    isDefault: defaultGroupID == group.id
                )
            }

            Divider()

            Button(action: onCreate) {
                Label("wordbook.group.new", systemSymbol: .plus)
            }
            .disabled(!canMutate)

            Button {
                onSetDefault(nil)
            } label: {
                defaultLabel(isDefault: defaultGroupID == nil)
            }
            .disabled(!canMutate || defaultGroupID == nil)

            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                managementMenu(for: group, index: index)
            }
        } label: {
            HStack(spacing: 6) {
                currentScopeLabel
                Text(countLabel)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Private

    @Environment(\.locale) private var locale

    private var countLabel: String {
        String(
            format: String(localized: "wordbook.scope.count", locale: locale),
            locale: locale,
            arguments: [Int64(count) as CVarArg]
        )
    }

    private var defaultIcon: some View {
        Image(systemSymbol: .starFill)
            .accessibilityLabel(
                Text("wordbook.group.default.accessibility")
            )
    }

    @ViewBuilder private var currentScopeLabel: some View {
        switch scope {
        case .all:
            Text("wordbook.group.all")
        case .ungrouped:
            Text("wordbook.group.ungrouped")
        case let .group(id):
            if let group = groups.first(where: { $0.id == id }) {
                Text(group.name)
            } else {
                Text("wordbook.group.all")
            }
        }
    }

    private func managementMenu(
        for group: WordbookGroup,
        index: Int
    )
        -> some View {
        Menu {
            Button {
                onSetDefault(group.id)
            } label: {
                defaultLabel(isDefault: defaultGroupID == group.id)
            }
            .disabled(!canMutate || defaultGroupID == group.id)

            Button {
                onRename(group)
            } label: {
                Label("wordbook.group.rename", systemSymbol: .pencil)
            }
            .disabled(!canMutate)

            Button {
                onMove(group, -1)
            } label: {
                Label("wordbook.group.move_up", systemSymbol: .arrowUp)
            }
            .disabled(!canMutate || index == groups.startIndex)

            Button {
                onMove(group, 1)
            } label: {
                Label("wordbook.group.move_down", systemSymbol: .arrowDown)
            }
            .disabled(!canMutate || index == groups.index(before: groups.endIndex))

            Divider()

            Button(role: .destructive) {
                onDelete(group)
            } label: {
                Label("common.delete", systemSymbol: .trash)
            }
            .disabled(!canMutate)
        } label: {
            HStack {
                Text(group.name)
                if defaultGroupID == group.id {
                    defaultIcon
                }
            }
        }
    }

    @ViewBuilder
    private func defaultLabel(isDefault: Bool) -> some View {
        if isDefault {
            Label {
                Text("wordbook.group.set_default")
            } icon: {
                defaultIcon
            }
        } else {
            Label("wordbook.group.set_default", systemSymbol: .star)
        }
    }

    private func scopeButton(
        _ candidate: WordbookGroupScope,
        title: Text,
        isDefault: Bool = false
    )
        -> some View {
        Button {
            onSelect(candidate)
        } label: {
            HStack {
                if scope == candidate {
                    Image(systemSymbol: .checkmark)
                }
                title
                if isDefault {
                    Image(systemSymbol: .starFill)
                        .accessibilityLabel(
                            Text("wordbook.group.default.accessibility")
                        )
                }
            }
        }
    }
}
