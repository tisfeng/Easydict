//
//  ServiceTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// MARK: - ServiceTab

struct ServiceTab: View {
    // MARK: Internal

    var body: some View {
        HSplitView {
            VStack(spacing: 16) {
                WindowTypePicker(windowType: $viewModel.windowType)
                    .padding(.horizontal, 12)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    List(selection: $viewModel.selectedItem) {
                        WindowConfigurationItem()
                            .tag(ServiceTabSelection.windowConfiguration)

                        ServiceItems()
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.never)
                    .borderedCard()
                    .onReceive(serviceHasUpdatedNotification) { _ in
                        viewModel.updateServices()
                    }

                    ServiceListControls()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(minWidth: 270, maxWidth: 320, maxHeight: .infinity)

            ServiceDetailView()
                .layoutPriority(1)
        }
        .environmentObject(viewModel)
        .onChange(of: viewModel.windowType) { _ in
            viewModel.handleWindowTypeChange()
        }
    }

    // MARK: Private

    @StateObject private var viewModel: ServiceTabViewModel = .init()

    private let serviceHasUpdatedNotification = NotificationCenter.default
        .publisher(for: .serviceHasUpdated)
}

// MARK: - ServiceTabSelection

enum ServiceTabSelection: Hashable {
    case windowConfiguration
    case service(String)
}

// MARK: - ServiceTabViewModel

@MainActor
class ServiceTabViewModel: ObservableObject {
    // MARK: Lifecycle

    init(windowType: EZWindowType = .fixed) {
        self.windowType = windowType
        self.serviceItems = Self.loadServiceItems(windowType)
        self.availableServiceItems = Self.loadAvailableServiceItems(windowType)
    }

    // MARK: Internal

    @Published private(set) var serviceItems: [ServiceListItem]

    @Published private(set) var availableServiceItems: [ServiceListItem]

    @Published private(set) var selectedService: QueryService?

    @Published var windowType: EZWindowType

    @Published var selectedItem: ServiceTabSelection? = .windowConfiguration {
        didSet {
            DispatchQueue.main.async { [self] in
                updateSelectedService()
            }
        }
    }

    var canRemoveSelectedService: Bool {
        guard let selectedServiceItem else { return false }
        return canRemoveService(selectedServiceItem)
    }

    /// Refresh services when the window type changes.
    func handleWindowTypeChange() {
        selectedItem = .windowConfiguration
        selectedService = nil
        updateServices()
    }

    func updateServices() {
        serviceItems = Self.loadServiceItems(windowType)
        availableServiceItems = Self.loadAvailableServiceItems(windowType)

        guard case let .service(selectedServiceID) = selectedItem else { return }

        let isSelectedServiceAvailable = serviceItems.contains { $0.id == selectedServiceID }
        if !isSelectedServiceAvailable {
            selectedItem = .windowConfiguration
            selectedService = nil
        } else {
            updateSelectedService()
        }
    }

    func moveServices(fromOffsets: IndexSet, toOffset: Int) {
        var serviceItems = serviceItems
        serviceItems.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = serviceItems.map(\.id)
        LocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)

        postUpdateServiceNotification()
        updateServices()
    }

    func addService(_ item: ServiceListItem) {
        let serviceTypeId = item.createsNewInstance
            ? "\(item.type.rawValue)#\(UUID().uuidString)"
            : item.id
        guard LocalStorage.shared().addServiceType(serviceTypeId, windowType: windowType) else {
            return
        }

        selectedItem = .service(serviceTypeId)
        postUpdateServiceNotification()
        reloadLLMSubscribersIfNeeded(for: item)
        updateServices()
    }

    func canRemoveService(_ item: ServiceListItem) -> Bool {
        serviceItems.contains { $0.id == item.id } && serviceItems.count > 1
    }

    func removeService(_ item: ServiceListItem) {
        guard LocalStorage.shared().removeServiceType(item.id, windowType: windowType) else {
            return
        }

        if selectedItem == .service(item.id) {
            selectedItem = .windowConfiguration
            selectedService = nil
        }

        postUpdateServiceNotification()
        reloadLLMSubscribersIfNeeded(for: item)
        updateServices()
    }

    func removeSelectedService() {
        guard let selectedServiceItem else {
            return
        }
        removeService(selectedServiceItem)
    }

    func setServiceEnabled(_ enabled: Bool, for item: ServiceListItem) {
        if selectedService?.serviceTypeWithUniqueIdentifier() == item.id {
            selectedService?.enabled = enabled
            if let selectedService {
                LocalStorage.shared().setService(selectedService, windowType: windowType)
            }
        } else {
            LocalStorage.shared().setServiceEnabled(
                enabled,
                serviceTypeId: item.id,
                windowType: windowType
            )
        }

        postUpdateServiceNotification()
        reloadLLMSubscribersIfNeeded(for: item)
        updateServices()
    }

    func validateAndEnable(_ item: ServiceListItem) async throws {
        guard item.isStream else {
            setServiceEnabled(true, for: item)
            return
        }

        let validationWindowType = windowType
        guard let service = LocalStorage.shared().service(
            item.id,
            windowType: validationWindowType
        ) else {
            return
        }
        let result = await service.validate()
        guard LocalStorage.shared()
            .allServiceTypes(validationWindowType)
            .contains(item.id) else {
            return
        }
        if let error = result.error {
            throw error
        }
        service.enabled = true
        LocalStorage.shared().setService(service, windowType: validationWindowType)
        NotificationCenter.default.postServiceUpdateNotification(
            windowType: validationWindowType
        )
        if validationWindowType == .main {
            GlobalContext.shared.reloadLLMServicesSubscribers()
        }
        guard windowType == validationWindowType else { return }
        selectedService = selectedItem == .service(item.id) ? service : selectedService
        updateServices()
    }

    func postUpdateServiceNotification() {
        NotificationCenter.default.postServiceUpdateNotification(windowType: windowType)
    }

    // MARK: Private

    private var selectedServiceItem: ServiceListItem? {
        guard case let .service(serviceID) = selectedItem else {
            return nil
        }
        return serviceItems.first { $0.id == serviceID }
    }

    private static func loadServiceItems(_ windowType: EZWindowType) -> [ServiceListItem] {
        serviceItems(from: LocalStorage.shared().allServiceTypes(windowType), windowType: windowType)
    }

    private static func loadAvailableServiceItems(_ windowType: EZWindowType) -> [ServiceListItem] {
        serviceItems(
            from: LocalStorage.shared().availableServiceTypeIDs(windowType: windowType),
            windowType: windowType,
            forAddition: true
        )
    }

    private static func serviceItems(
        from serviceTypeIds: [String],
        windowType: EZWindowType,
        forAddition: Bool = false
    )
        -> [ServiceListItem] {
        serviceTypeIds.compactMap { typeId in
            guard let metadata = QueryServiceFactory.shared.metadata(withTypeId: typeId) else {
                return nil
            }
            let createsNewInstance = forAddition
                && metadata.allowsMultipleInstances
                && metadata.uuid.isEmpty
            let info = LocalStorage.shared().serviceInfo(
                withType: metadata.serviceType,
                serviceId: metadata.uuid,
                windowType: windowType
            )
            return ServiceListItem(
                id: typeId,
                type: metadata.serviceType,
                name: createsNewInstance
                    ? NSLocalizedString("custom_openai", comment: "")
                    : metadata.title,
                enabled: info?.enabled == true,
                requirement: metadata.apiKeyRequirement,
                isStream: metadata.isStream,
                createsNewInstance: createsNewInstance
            )
        }
    }

    private func updateSelectedService() {
        guard case let .service(serviceID) = selectedItem else {
            selectedService = nil
            return
        }
        guard serviceItems.contains(where: { $0.id == serviceID }) else {
            selectedService = nil
            return
        }
        selectedService = LocalStorage.shared().service(serviceID, windowType: windowType)
    }

    private func reloadLLMSubscribersIfNeeded(for item: ServiceListItem) {
        guard windowType == .main, item.isStream else { return }
        GlobalContext.shared.reloadLLMServicesSubscribers()
    }
}

// MARK: - ServiceListItem

struct ServiceListItem: Identifiable {
    let id: String
    let type: ServiceType
    let name: String
    let enabled: Bool
    let requirement: ServiceAPIKeyRequirement
    let isStream: Bool
    let createsNewInstance: Bool
}

// MARK: - WindowConfigurationItem

private struct WindowConfigurationItem: View {
    var body: some View {
        Text("setting.service.window_configuration")
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .listRowSeparator(.hidden)
            .listRowInsets(.init())
    }
}

// MARK: - ServiceDetailView

private struct ServiceDetailView: View {
    // MARK: Internal

    var body: some View {
        Group {
            if let service = viewModel.selectedService {
                if let view = service.configurationListItems() as? (any View) {
                    Form {
                        AnyView(view)
                    }
                    .formStyle(.grouped)
                } else {
                    VStack {
                        Spacer()

                        Text("setting.service.detail.no_configuration \(service.name())")

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                WindowConfigurationView(windowType: viewModel.windowType)
            }
        }
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel
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
