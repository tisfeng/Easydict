//
//  WordSuggestionController.swift
//  Easydict
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults

// MARK: - WordSuggestionController

/// Shows word suggestions under the query input while the user types a single English word.
///
/// `EZQueryView` forwards text changes and editing commands; the controller
/// debounces lookups, owns the suggestion panel, and reports the chosen word
/// through `selectionHandler`.
@objc(EZWordSuggestionController)
@MainActor
final class WordSuggestionController: NSObject {
    // MARK: Lifecycle

    /// - Parameter anchorView: The view the list is aligned under, usually the whole query input box.
    @objc
    init(anchorView: NSView) {
        self.anchorView = anchorView
        super.init()
        panel.listView.onClick = { [weak self] index in
            self?.choose(at: index)
        }
        panel.listView.onHover = { [weak self] index in
            self?.panel.listView.selectedIndex = index
        }
    }

    // MARK: Internal

    /// Called with the word the user picked; the caller fills the input and runs the query.
    @objc var selectionHandler: ((String) -> ())?

    /// Called with the word the user completed with Tab; the caller only fills the input.
    @objc var fillHandler: ((String) -> ())?

    /// Whether an input method is still composing; checked when the debounce fires, because
    /// right after Chinese text is committed the text view may still report marked text.
    @objc var isComposing: (() -> Bool)?

    @objc var isVisible: Bool {
        panel.isVisible
    }

    /// Schedules suggestions for the current input text, or hides the list when it does not apply.
    @objc
    func textDidChange(_ text: String) {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        lookupTask?.cancel()
        generation &+= 1

        guard Defaults[.enableWordSuggestion], provider.isSuggestible(input) else {
            hide()
            return
        }

        let currentGeneration = generation
        let delay = debounceNanoseconds
        lookupTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard let self, !Task.isCancelled, currentGeneration == generation else { return }
            if isComposing?() == true {
                hide()
                return
            }

            // Showing an empty list hides the panel, and hiding cancels this task; with no
            // local candidates (Chinese input, or a word only Youdao knows) wait for the full list.
            let localSuggestions = provider.localSuggestions(for: input)
            if !localSuggestions.isEmpty {
                show(localSuggestions)
            }
            let suggestions = await provider.suggestions(for: input)
            guard !Task.isCancelled, currentGeneration == generation else { return }
            show(suggestions)
        }
    }

    /// Handles navigation keys while the list is visible.
    /// - Returns: `true` when the command was consumed.
    @objc
    func handleCommand(_ selector: Selector) -> Bool {
        guard isVisible, !suggestions.isEmpty else { return false }

        switch selector {
        case #selector(NSResponder.moveDown(_:)):
            let next = panel.listView.selectedIndex + 1
            panel.listView.selectedIndex = next < suggestions.count ? next : 0
            return true
        case #selector(NSResponder.moveUp(_:)):
            let previous = panel.listView.selectedIndex - 1
            panel.listView.selectedIndex = previous >= 0 ? previous : suggestions.count - 1
            return true
        case #selector(NSResponder.insertNewline(_:)):
            // Without an explicit pick, Enter keeps its usual meaning: look up the typed text.
            guard suggestions.indices.contains(panel.listView.selectedIndex) else {
                hide()
                return false
            }
            choose(at: panel.listView.selectedIndex)
            return true
        case #selector(NSResponder.insertTab(_:)):
            // Like shell completion: fill the selected word, or the first one, without querying.
            let index = suggestions.indices.contains(panel.listView.selectedIndex) ? panel.listView.selectedIndex : 0
            fill(at: index)
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            hide()
            return true
        default:
            return false
        }
    }

    @objc
    func hide() {
        lookupTask?.cancel()
        generation &+= 1
        suggestions = []
        guard panel.isVisible else { return }
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
    }

    // MARK: Private

    /// Short enough to feel live, long enough to skip intermediate keystrokes.
    private let debounceNanoseconds: UInt64 = 150_000_000

    private weak var anchorView: NSView?
    private let provider = WordSuggestionProvider()
    private let panel = WordSuggestionPanel()
    private let gapBelowAnchor: CGFloat = 4
    private let noSelection = -1

    private var suggestions: [WordSuggestion] = []
    private var lookupTask: Task<(), Never>?
    private var generation: UInt = 0

    private func show(_ newSuggestions: [WordSuggestion]) {
        guard !newSuggestions.isEmpty,
              let anchorView, let window = anchorView.window, window.isVisible
        else {
            hide()
            return
        }

        let previousWord = suggestions.indices.contains(panel.listView.selectedIndex)
            ? suggestions[panel.listView.selectedIndex].word
            : nil
        suggestions = newSuggestions

        let listView = panel.listView
        listView.fontSizeRatio = MyConfiguration.shared.fontSizeRatio
        listView.suggestions = newSuggestions
        // Nothing is preselected, so Enter still looks up exactly what was typed.
        listView.selectedIndex = newSuggestions.firstIndex { $0.word == previousWord } ?? noSelection

        let anchorRect = window.convertToScreen(anchorView.convert(anchorView.bounds, to: nil))
        let height = listView.preferredHeight
        panel.setFrame(
            NSRect(
                x: anchorRect.minX,
                y: panelOriginY(below: anchorRect, height: height, screen: window.screen),
                width: anchorRect.width,
                height: height
            ),
            display: true
        )

        if panel.parent !== window {
            panel.parent?.removeChildWindow(panel)
            window.addChildWindow(panel, ordered: .above)
        }
        panel.orderFront(nil)
    }

    private func fill(at index: Int) {
        guard suggestions.indices.contains(index) else { return }
        let word = suggestions[index].word
        hide()
        fillHandler?(word)
        // Suggest again for the filled word, such as its same-root words and phrases.
        textDidChange(word)
    }

    /// Places the list under the input, or above it when a window near the bottom of the screen
    /// leaves too little room; as a last resort it is pinned to the bottom of the visible area.
    private func panelOriginY(below anchorRect: NSRect, height: CGFloat, screen: NSScreen?) -> CGFloat {
        let below = anchorRect.minY - gapBelowAnchor - height
        guard let visible = screen?.visibleFrame, below < visible.minY else { return below }
        let above = anchorRect.maxY + gapBelowAnchor
        if above + height <= visible.maxY {
            return above
        }
        return visible.minY
    }

    private func choose(at index: Int) {
        guard suggestions.indices.contains(index) else { return }
        let word = suggestions[index].word
        hide()
        selectionHandler?(word)
    }
}
