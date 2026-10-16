//
//  GlassMiniView.swift
//  Easydict
//

import AppKit
import SFSafeSymbols
import SwiftUI

@MainActor
final class GlassMiniState: ObservableObject {
    enum Phase { case ready, loading, result, failure }

    @Published var phase: Phase = .ready
    @Published var text = ""
    @Published var provider = ""
    @Published var pinned = false
    @Published var contentVisible = true
}

/// A single glass surface keeps the translation visually dominant.
struct GlassMiniView: View {
    @ObservedObject var state: GlassMiniState
    let pin: () -> Void
    let retry: () -> Void
    let copy: () -> Void
    let close: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Button(action: pin) {
                Image(systemSymbol: state.pinned ? .pinFill : .pin)
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .modifier(GlassMiniMaterial(shape: Circle()))
            .help(state.pinned ? LocalizedStringKey("glass.mini.unpin") : LocalizedStringKey("glass.mini.pin"))
            .accessibilityLabel(Text(
                state.pinned ? LocalizedStringKey("glass.mini.unpin") : LocalizedStringKey("glass.mini.pin")
            ))
            .opacity(state.phase == .loading ? 0 : 1)
            .allowsHitTesting(state.phase != .loading)

            ZStack {
                if state.phase == .loading {
                    loadingDots
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ScrollView {
                            Text(verbatim: state.text)
                                .font(.system(size: 16))
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .scrollIndicators(.automatic)

                        HStack {
                            Text(verbatim: state.provider)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            if state.phase == .failure || state.phase == .ready {
                                Button(action: retry) {
                                    Text(
                                        state.phase == .ready
                                            ? LocalizedStringKey("glass.mini.translate")
                                            : LocalizedStringKey("glass.mini.retry")
                                    )
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    .opacity(state.contentVisible ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(GlassMiniMaterial(shape: RoundedRectangle(cornerRadius: 24, style: .continuous)))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contextMenu {
                Button("glass.mini.copy", action: copy)
                    .disabled(state.phase != .result)
                Button("glass.mini.retry", action: retry)
                Button("glass.mini.close", action: close)
            }
        }
        .padding(12)
        .onExitCommand(perform: close)
    }

    private var loadingDots: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    let phase = context.date.timeIntervalSinceReferenceDate * 5 - Double(index) * 0.8
                    let pulse = reduceMotion ? 0.5 : (sin(phase) + 1) / 2
                    Circle()
                        .fill(Color.primary.opacity(0.35 + pulse * 0.5))
                        .frame(width: 5, height: 5)
                        .offset(y: reduceMotion ? 0 : -2 * pulse)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("glass.mini.loading"))
    }

}

private struct GlassMiniMaterial<S: Shape>: ViewModifier {
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            if reduceTransparency {
                content.background { shape.fill(Color(nsColor: .windowBackgroundColor)) }
                    .focusEffectDisabled()
            } else {
                content.glassEffect(.regular, in: shape)
                    .focusEffectDisabled()
            }
        } else {
            content.background { shape.fill(.regularMaterial) }
        }
    }
}
