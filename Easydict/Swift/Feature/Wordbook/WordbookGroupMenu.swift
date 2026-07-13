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

/// Presents the read-only scope choices for the Wordbook browser. It keeps
/// built-in scopes ahead of user groups, marks the active scope, and exposes
/// the default destination with a localized accessibility label while leaving
/// group mutation commands to the later management surface.
struct WordbookGroupMenu: View {
    // MARK: Internal

    let groups: [WordbookGroup]
    let scope: WordbookGroupScope
    let defaultGroupID: UUID?
    let count: Int
    let onSelect: (WordbookGroupScope) -> ()

    var body: some View {
        Menu {
            scopeButton(.all, title: Text("wordbook.group.all"))
            scopeButton(
                .ungrouped,
                title: Text("wordbook.group.ungrouped"),
                isDefault: defaultGroupID == nil
            )

            Divider()

            ForEach(groups) { group in
                scopeButton(
                    .group(group.id),
                    title: Text(group.name),
                    isDefault: defaultGroupID == group.id
                )
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
