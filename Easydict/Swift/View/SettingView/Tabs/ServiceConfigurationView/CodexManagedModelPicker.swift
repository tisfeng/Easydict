//
//  CodexManagedModelPicker.swift
//  Easydict
//

import SFSafeSymbols
import SwiftUI

/// Keeps model selection and removal in separate controls within the opened list.
struct CodexManagedModelPicker: View {
    // MARK: Internal

    let models: [String]
    @Binding var selection: String?

    let isBusy: Bool
    let removeModel: (String) -> ()

    var body: some View {
        HStack {
            Text("service.configuration.codex_cli.model.title")
            Spacer()
            Button {
                isPresented.toggle()
            } label: {
                HStack(spacing: 8) {
                    if let selection {
                        Text(verbatim: selection)
                    } else {
                        Text("service.codex_cli.custom_models.select_model")
                    }
                    Image(systemSymbol: .chevronUpChevronDown)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("service.configuration.codex_cli.model.title")
            .accessibilityValue(Text(verbatim: selection ?? ""))
            .disabled(isBusy || models.isEmpty)
            .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(models, id: \.self) { model in
                            HStack(spacing: 8) {
                                Button {
                                    selection = model
                                    isPresented = false
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemSymbol: .checkmark)
                                            .opacity(selection == model ? 1 : 0)
                                            .accessibilityHidden(true)
                                        Text(verbatim: model)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(selection == model ? .isSelected : [])
                                Button {
                                    removeModel(model)
                                    if models.count == 1 { isPresented = false }
                                } label: {
                                    Image(systemSymbol: .xmarkCircleFill)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help(removalLabel(model))
                                .accessibilityLabel(removalLabel(model))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(6)
                }
                .frame(width: 300, height: min(CGFloat(models.count) * 32 + 12, 300))
                .disabled(isBusy)
                .onExitCommand { isPresented = false }
            }
        }
        .onChange(of: isBusy) { busy in
            if busy { isPresented = false }
        }
    }

    // MARK: Private

    @State private var isPresented = false

    private func removalLabel(_ model: String) -> String {
        String(format: String(localized: "service.codex_cli.custom_models.remove"), model)
    }
}
