//
//  ServiceTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import SwiftUI

// MARK: - ServiceTab

struct ServiceTab: View {
    // MARK: Internal

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                WindowTypePicker(windowType: $viewModel.windowType)
                    .padding()
                List(selection: $viewModel.selectedService) {
                    ServiceItems()
                }
                .listStyle(.plain)
                .scrollIndicators(.never)
                .borderedCard()
                .padding(.bottom)
                .padding(.horizontal)
                .frame(minWidth: 260)
                .onReceive(serviceHasUpdatedNotification) { _ in
                    Task { @MainActor in
                        viewModel.updateServices()
                    }
                }
            }

            Group {
                if let service = viewModel.selectedService {
                    VStack(alignment: .leading) {
                        Button("setting.service.back") {
                            viewModel.selectedService = nil
                        }
                        .padding()

                        if let view = service.configurationListItems() as? (any View) {
                            Form {
                                AnyView(view)
                            }
                            .formStyle(.grouped)
                        } else {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("setting.service.detail.no_configuration \(service.name())")
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                } else {
                    WindowConfigurationView(windowType: viewModel.windowType)
                }
            }
            .layoutPriority(1)
        }
        .environmentObject(viewModel)
        .onChange(of: viewModel.windowType) { _ in
            Task { @MainActor in
                viewModel.handleWindowTypeChange()
            }
        }
    }

    // MARK: Private

    @StateObject private var viewModel: ServiceTabViewModel = .init()

    private let serviceHasUpdatedNotification = NotificationCenter.default
        .publisher(for: .serviceHasUpdated)
}

// MARK: - ServiceTabViewModel

@MainActor
private class ServiceTabViewModel: ObservableObject {
    // MARK: Lifecycle

    init(windowType: EZWindowType = .fixed) {
        self.windowType = windowType
        self.services = LocalStorage.shared().allServices(windowType)
    }

    // MARK: Internal

    @Published var selectedService: QueryService?

    @Published private(set) var services: [QueryService]

    @Published var windowType: EZWindowType

    /// Refresh services when the window type changes.
    func handleWindowTypeChange() {
        selectedService = nil
        updateServices()
    }

    func updateServices() {
        services = LocalStorage.shared().allServices(windowType)

        let isSelectedExist =
            services
                .contains {
                    $0.serviceTypeWithUniqueIdentifier()
                        == selectedService?.serviceTypeWithUniqueIdentifier()
                }
        if !isSelectedExist {
            selectedService = nil
        }
    }

    func onServiceItemMove(fromOffsets: IndexSet, toOffset: Int) {
        var services = services
        services.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = services.map { $0.serviceTypeWithUniqueIdentifier() }
        LocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)

        postUpdateServiceNotification()
        updateServices()
    }

    func postUpdateServiceNotification() {
        NotificationCenter.default.postServiceUpdateNotification(windowType: windowType)
    }
}

// MARK: - ServiceItems

private struct ServiceItems: View {
    // MARK: Internal

    var body: some View {
        Section {
            ForEach(servicesWithID, id: \.1) { service, _ in
                ServiceItemView(service: service, viewModel: viewModel)
                    .tag(service)
            }
            .onMove { source, destination in
                viewModel.onServiceItemMove(fromOffsets: source, toOffset: destination)
            }
        }
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var servicesWithID: [(QueryService, String)] {
        viewModel.services.map { service in
            (service, service.serviceTypeWithUniqueIdentifier())
        }
    }
}

// MARK: - ServiceItemViewModel

@MainActor
private class ServiceItemViewModel: ObservableObject {
    // MARK: Lifecycle

    init(_ service: QueryService, viewModel: ServiceTabViewModel) {
        self.service = service
        self.name = service.name()
        self.viewModel = viewModel

        cancellables.append(
            serviceUpdatePublisher
                .sink { [weak self] notification in
                    self?.didReceive(notification)
                }
        )
    }

    // MARK: Public

    /// Try to enable the service, if the service is StreamService, we need to validate it first.
    public func tryEnableService() {
        // If service is not StreamService, we can enable it directly
        if !service.isKind(of: StreamService.self) {
            updateServiceStatus(enabled: true)
            return
        }

        isValidating = true

        Task {
            do {
                defer { isValidating = false }

                let result = await service.validate()
                if let error = result.error {
                    throw error
                }
                updateServiceStatus(enabled: true)
            } catch {
                logError("\(self.service.serviceType().rawValue) validate error: \(error)")
                self.error = error
                self.showErrorAlert = true
            }
        }
    }

    // MARK: Internal

    let service: QueryService

    @Published var isValidating = false
    @Published var name = ""

    @Published var showErrorAlert = false
    @Published var showClaudeCodeRiskAlert = false
    @Published var error: (any Error)?

    unowned var viewModel: ServiceTabViewModel

    var isEnable: Bool {
        get {
            service.enabled
        }
        set {
            // turn on service
            if newValue {
                if service.serviceType() == .claudeCode {
                    showClaudeCodeRiskAlert = true
                } else {
                    tryEnableService()
                }
            } else {
                // turn off service
                updateServiceStatus(enabled: false)
            }
        }
    }

    // MARK: Private

    @EnvironmentObject private var serviceTabViewModel: ServiceTabViewModel

    private var cancellables: [AnyCancellable] = []

    private var serviceUpdatePublisher: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: .serviceHasUpdated)
            .eraseToAnyPublisher()
    }

    private func didReceive(_ notification: Notification) {
        guard let info = notification.userInfo as? [String: Any] else { return }
        guard let serviceType = info[UserInfoKey.serviceType] as? String else { return }
        guard serviceType == service.serviceType().rawValue else { return }
        name = service.name()
    }

    /// Update service enabled status, and post update service notification.
    private func updateServiceStatus(enabled: Bool) {
        service.enabled = enabled
        LocalStorage.shared().setService(service, windowType: viewModel.windowType)
        viewModel.postUpdateServiceNotification()
    }
}

// MARK: - ServiceItemView

private struct ServiceItemView: View {
    // MARK: Lifecycle

    init(service: QueryService, viewModel: ServiceTabViewModel) {
        self.service = service
        self.serviceItemViewModel = ServiceItemViewModel(service, viewModel: viewModel)
    }

    // MARK: Internal

    let service: QueryService

    var body: some View {
        Group {
            HStack(spacing: 8) {
                HStack {
                    Image(service.serviceType().rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0, height: 20.0)
                    Text(verbatim: serviceItemViewModel.name)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)
                
                ServiceRequirementBadge(requirement: service.apiKeyRequirement())
                
                // Use a fixed width container for both controls, to make sure they are center aligned.
                ZStack {
                    if serviceItemViewModel.isValidating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Toggle(
                            serviceItemViewModel.service.name(),
                            isOn: $serviceItemViewModel.isEnable
                        )
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small) // size: 32*18
                    }
                }
                .frame(width: 32)
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(.init())
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .alert(
            "setting.service.failed_to_enable_service \(serviceItemViewModel.service.name())",
            isPresented: $serviceItemViewModel.showErrorAlert
        ) {
            Button("ok") {
                serviceItemViewModel.showErrorAlert = false
            }
        } message: {
            Text(serviceItemViewModel.error?.localizedDescription ?? "unknown_error")
        }
        .alert(
            "service.claude_code.enable_risk_alert.title",
            isPresented: $serviceItemViewModel.showClaudeCodeRiskAlert
        ) {
            Button("cancel", role: .cancel) {
                serviceItemViewModel.showClaudeCodeRiskAlert = false
            }
            Button("ok") {
                serviceItemViewModel.showClaudeCodeRiskAlert = false
                serviceItemViewModel.tryEnableService()
            }
        } message: {
            Text("service.claude_code.enable_risk_alert.message")
        }
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    @ObservedObject private var serviceItemViewModel: ServiceItemViewModel
}

// MARK: - ServiceRequirementBadge

/// Renders the short API credential category shown beside each service row.
private struct ServiceRequirementBadge: View {
    // MARK: Internal

    let requirement: ServiceAPIKeyRequirement

    var body: some View {
        Text(verbatim: title)
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

    // MARK: Private

    private var title: String {
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

// MARK: - WindowTypePicker

private struct WindowTypePicker: View {
    @Binding var windowType: EZWindowType

    var body: some View {
        Picker(selection: $windowType) {
            ForEach([EZWindowType]([.fixed, .mini, .main]), id: \.rawValue) { windowType in
                Text(windowType.localizedStringResource)
                    .tag(windowType)
            }
        } label: {
            EmptyView()
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }
}
