//
//  ServiceTabListViews.swift
//  Easydict
//
//  Created by MoonMao on 2026/5/27.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SFSafeSymbols
import SwiftUI

// MARK: - ServiceItems

struct ServiceItems: View {
    // MARK: Internal

    var body: some View {
        ForEach(viewModel.serviceItems) { item in
            ServiceItemView(item: item)
                .tag(ServiceTabSelection.service(item.id))
        }
        .onMove { source, destination in
            viewModel.moveServices(fromOffsets: source, toOffset: destination)
        }
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel
}

// MARK: - ServiceItemView

private struct ServiceItemView: View {
    // MARK: Internal

    let item: ServiceListItem

    var body: some View {
        HStack(spacing: 4) {
            HStack {
                ServiceIcon(type: item.type, iconSize: 18, containerSize: 22)
                Text(verbatim: item.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            ServiceRequirementBadge(requirement: item.requirement)

            // Magnet can trigger a SwiftUI List(selection:) edge case where the
            // first click on an unselected row selects the row before Toggle sees it.
            // The Button handles clicks while Toggle only renders the switch.
            Button {
                toggleEnabled()
            } label: {
                Toggle(item.name, isOn: .constant(item.enabled))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .allowsHitTesting(false)
            }
            .buttonStyle(.borderless)
            .frame(width: 40, alignment: .center)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(.init())
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .alert(
            "service.claude_code.enable_risk_alert.title",
            isPresented: $showClaudeCodeRiskAlert
        ) {
            Button("cancel", role: .cancel) {
                showClaudeCodeRiskAlert = false
            }
            Button("ok") {
                showClaudeCodeRiskAlert = false
                viewModel.setServiceEnabled(true, for: item)
            }
        } message: {
            Text("service.claude_code.enable_risk_alert.message")
        }
        .alert(
            "service.codex_cli.enable_risk_alert.title",
            isPresented: $showCodexCLIRiskAlert
        ) {
            Button("cancel", role: .cancel) {
                showCodexCLIRiskAlert = false
            }
            Button("ok") {
                showCodexCLIRiskAlert = false
                viewModel.setServiceEnabled(true, for: item)
            }
        } message: {
            Text("service.codex_cli.enable_risk_alert.message")
        }
    }

    // MARK: Private

    @State private var showClaudeCodeRiskAlert = false
    @State private var showCodexCLIRiskAlert = false

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    /// Toggles the service on or off. Enabling Claude Code or Codex CLI first
    /// prompts a risk confirmation; other services enable directly.
    private func toggleEnabled() {
        guard !item.enabled else {
            viewModel.setServiceEnabled(false, for: item)
            return
        }

        if item.type == .claudeCode {
            showClaudeCodeRiskAlert = true
        } else if item.type == .codexCLI {
            showCodexCLIRiskAlert = true
        } else {
            viewModel.setServiceEnabled(true, for: item)
        }
    }
}

// MARK: - ServiceListControls

struct ServiceListControls: View {
    // MARK: Internal

    var body: some View {
        ServiceListControl(
            canRemove: viewModel.canRemoveSelectedServices,
            addAction: {
                isShowingAddServiceSheet = true
            },
            removeAction: {
                viewModel.removeSelectedServices()
            }
        )
        .frame(width: 112, height: 24)
        .sheet(isPresented: $isShowingAddServiceSheet) {
            AddServiceSheet()
                .environmentObject(viewModel)
        }
    }

    // MARK: Private

    @State private var isShowingAddServiceSheet = false

    @EnvironmentObject private var viewModel: ServiceTabViewModel
}

// MARK: - ServiceListControl

private struct ServiceListControl: NSViewRepresentable {
    final class Coordinator: NSObject {
        // MARK: Lifecycle

        init(addAction: @escaping () -> (), removeAction: @escaping () -> ()) {
            self.addAction = addAction
            self.removeAction = removeAction
        }

        // MARK: Internal

        var addAction: () -> ()
        var removeAction: () -> ()

        @objc
        func selectSegment(_ sender: NSSegmentedControl) {
            switch sender.selectedSegment {
            case 0:
                addAction()
            case 1:
                removeAction()
            default:
                break
            }
            sender.selectedSegment = -1
        }
    }

    let canRemove: Bool
    let addAction: () -> ()
    let removeAction: () -> ()

    func makeCoordinator() -> Coordinator {
        Coordinator(addAction: addAction, removeAction: removeAction)
    }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl()
        control.segmentCount = 2
        control.segmentStyle = .smallSquare
        control.trackingMode = .momentary
        control.controlSize = .small
        control.target = context.coordinator
        control.action = #selector(Coordinator.selectSegment(_:))
        control.setImage(NSImage(systemSymbol: .plus), forSegment: 0)
        control.setImage(NSImage(systemSymbol: .minus), forSegment: 1)
        control.setWidth(55, forSegment: 0)
        control.setWidth(55, forSegment: 1)
        control.setToolTip(String(localized: "setting.service.add"), forSegment: 0)
        control.setToolTip(String(localized: "setting.service.remove"), forSegment: 1)
        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.addAction = addAction
        context.coordinator.removeAction = removeAction
        control.setEnabled(canRemove, forSegment: 1)
    }
}

// MARK: - AddServiceSheet

private struct AddServiceSheet: View {
    // MARK: Internal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("setting.service.add")
                .font(.headline)

            Divider()

            if viewModel.availableServiceItems.isEmpty {
                Text("setting.service.add.empty")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(requirementGroups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(verbatim: group.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                                    ForEach(group.items) { item in
                                        AddServiceTile(
                                            item: item,
                                            isSelected: selectedTypeIds.contains(item.id)
                                        ) {
                                            toggleSelection(item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 2)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .frame(width: 76)

                Button("ok") {
                    addSelectedServices()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedServiceItems.isEmpty)
                .frame(width: 76)
            }
        }
        .padding(18)
        .frame(width: 640, height: 540)
    }

    // MARK: Private

    @State private var selectedTypeIds: Set<String> = []

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 142, maximum: 180), spacing: 12),
        ]
    }

    private var selectedServiceItems: [ServiceListItem] {
        viewModel.availableServiceItems.filter {
            selectedTypeIds.contains($0.id)
        }
    }

    private var requirementGroups: [ServiceGroup] {
        ServiceAPIKeyRequirement.addSheetOrder.compactMap { requirement in
            let items = viewModel.availableServiceItems.filter {
                $0.requirement == requirement
            }
            guard !items.isEmpty else {
                return nil
            }
            return ServiceGroup(title: ServiceRequirementBadge.title(for: requirement), items: items)
        }
    }

    private func toggleSelection(_ item: ServiceListItem) {
        if !selectedTypeIds.insert(item.id).inserted {
            selectedTypeIds.remove(item.id)
        }
    }

    private func addSelectedServices() {
        viewModel.addServices(selectedServiceItems)
        dismiss()
    }
}

// MARK: - AddServiceTile

private struct AddServiceTile: View {
    // MARK: Internal

    let item: ServiceListItem
    let isSelected: Bool
    let addAction: () -> ()

    var body: some View {
        Button(action: addAction) {
            HStack(spacing: 10) {
                ServiceIcon(type: item.type, iconSize: 26, containerSize: 32)

                Text(verbatim: item.name)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.primary.opacity(isSelected || isHovered ? 0.08 : 0))
                }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    // MARK: Private

    @State private var isHovered = false
}

// MARK: - ServiceIcon

private struct ServiceIcon: View {
    let type: ServiceType
    let iconSize: CGFloat
    let containerSize: CGFloat

    var body: some View {
        Image(type.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
            .frame(width: containerSize, height: containerSize)
    }
}

// MARK: - ServiceRequirementBadge

private struct ServiceRequirementBadge: View {
    // MARK: Internal

    let requirement: ServiceAPIKeyRequirement

    var body: some View {
        Text(verbatim: Self.title(for: requirement))
            .font(.caption2.weight(.medium))
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
                Capsule()
                    .fill(backgroundColor)
            }
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 0.5)
            }
    }

    static func title(for requirement: ServiceAPIKeyRequirement) -> String {
        switch requirement {
        case .none:
            "no-key"
        case .builtIn:
            "built-in"
        case .userProvided:
            "key"
        case .agentCLI:
            "cli"
        }
    }

    // MARK: Private

    private var foregroundColor: Color {
        switch requirement {
        case .none:
            .secondary
        case .builtIn:
            .green
        case .userProvided:
            .orange
        case .agentCLI:
            .blue
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }

    private var borderColor: Color {
        foregroundColor.opacity(0.28)
    }
}

// MARK: - ServiceGroup

private struct ServiceGroup: Identifiable {
    let title: String
    let items: [ServiceListItem]

    var id: String { title }
}

extension ServiceAPIKeyRequirement {
    fileprivate static let addSheetOrder: [ServiceAPIKeyRequirement] = [
        .builtIn,
        .userProvided,
        .agentCLI,
        .none,
    ]
}
