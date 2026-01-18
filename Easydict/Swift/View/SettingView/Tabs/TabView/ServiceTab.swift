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

    private let serviceHasUpdatedNotification = NotificationCenter.default
        .publisher(for: .serviceHasUpdated)

    @StateObject private var viewModel: ServiceTabViewModel = .init()
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
        Group {
            // Free services section
            if !freeServices.isEmpty {
                Section {
                    ForEach(freeServicesWithID, id: \.1) { service, _ in
                        ServiceItemView(service: service, viewModel: viewModel)
                            .tag(service)
                    }
                    .onMove { source, destination in
                        handleMove(source: source, destination: destination, inSection: freeServices)
                    }
                } header: {
                    Text("setting.service.section.free")
                        .font(.headline)
                }
            }

            // Pro services section (require API key)
            if !proServices.isEmpty {
                Section {
                    ForEach(proServicesWithID, id: \.1) { service, _ in
                        ServiceItemView(service: service, viewModel: viewModel)
                            .tag(service)
                    }
                    .onMove { source, destination in
                        handleMove(source: source, destination: destination, inSection: proServices)
                    }
                } header: {
                    Text("setting.service.section.pro")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var freeServices: [QueryService] {
        viewModel.services.filter { !requiresAPIKey($0) }
    }

    private var proServices: [QueryService] {
        viewModel.services.filter { requiresAPIKey($0) }
    }

    private var freeServicesWithID: [(QueryService, String)] {
        freeServices.map { service in
            (service, service.serviceTypeWithUniqueIdentifier())
        }
    }

    private var proServicesWithID: [(QueryService, String)] {
        proServices.map { service in
            (service, service.serviceTypeWithUniqueIdentifier())
        }
    }

    /// Determines if a service requires an API key to use.
    private func requiresAPIKey(_ service: QueryService) -> Bool {
        // BuiltInAI uses built-in API keys, so it's free for users
        if service.serviceType() == .builtInAI {
            return false
        }

        // StreamService (AI services) generally require API keys
        if service.isKind(of: StreamService.self) {
            return true
        }

        // Check if service explicitly requires private API key
        if service.needPrivateAPIKey() {
            return true
        }

        // Check if service has API key configuration by checking configuration view type
        if let configView = service.configurationListItems() as? (any View) {
            let typeName = String(describing: type(of: configView))
            // Services with secret sections or stream configuration likely need API keys
            if typeName.contains("StreamConfigurationView") ||
                typeName.contains("ServiceConfigurationSecretSectionView") {
                return true
            }
        }

        return false
    }

    /// Handles move operation within a specific section.
    private func handleMove(source: IndexSet, destination: Int, inSection sectionServices: [QueryService]) {
        // Create a mapping of section services to their indices in the full services array
        var sectionToFullIndexMap: [Int: Int] = [:]
        var sectionIndex = 0

        for (fullIndex, service) in viewModel.services.enumerated() where sectionServices
            .contains(where: { $0.serviceTypeWithUniqueIdentifier() == service.serviceTypeWithUniqueIdentifier()
            }) {
            sectionToFullIndexMap[sectionIndex] = fullIndex
            sectionIndex += 1
        }

        // Convert section source indices to full array indices
        var actualSourceIndices = IndexSet()
        for sectionIdx in source {
            if let fullIdx = sectionToFullIndexMap[sectionIdx] {
                actualSourceIndices.insert(fullIdx)
            }
        }

        // Find destination index in full services array
        let actualDestination = sectionToFullIndexMap[destination] ?? destination

        viewModel.onServiceItemMove(fromOffsets: actualSourceIndices, toOffset: actualDestination)
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
    @Published var error: (any Error)?

    unowned var viewModel: ServiceTabViewModel

    var isEnable: Bool {
        get {
            service.enabled
        }
        set {
            // turn on service
            if newValue {
                tryEnableService()
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
            HStack {
                HStack {
                    Image(service.serviceType().rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0, height: 20.0)
                    Text(service.name())
                        .lineLimit(1)
                }
                Spacer()
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
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    @ObservedObject private var serviceItemViewModel: ServiceItemViewModel
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
