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
                    List(
                        selection: Binding(
                            get: { viewModel.selectedItems },
                            set: { viewModel.selectItems($0) }
                        )
                    ) {
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

    @Published private(set) var selectedItems: Set<ServiceTabSelection> = [
        .windowConfiguration,
    ]

    var canRemoveSelectedServices: Bool {
        let selectedCount = selectedServiceItems.count
        return selectedCount > 0 && selectedCount < serviceItems.count
    }

    /// Refresh services when the window type changes.
    func handleWindowTypeChange() {
        setSelection([.windowConfiguration])
        updateServices()
    }

    func updateServices() {
        serviceItems = Self.loadServiceItems(windowType)
        availableServiceItems = Self.loadAvailableServiceItems(windowType)

        let availableSelections = Set(
            serviceItems.map { ServiceTabSelection.service($0.id) }
        )
        let validSelections = selectedItems.filter {
            $0 == .windowConfiguration || availableSelections.contains($0)
        }
        setSelection(Set(validSelections), preferred: selectedItem)
    }

    func moveServices(fromOffsets: IndexSet, toOffset: Int) {
        var serviceItems = serviceItems
        serviceItems.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = serviceItems.map(\.id)
        LocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)

        postUpdateServiceNotification()
        updateServices()
    }

    func addServices(_ items: [ServiceListItem]) {
        var addedTypeIds: [String] = []
        var addedItems: [ServiceListItem] = []

        for item in items {
            let serviceTypeId = item.createsNewInstance
                ? "\(item.type.rawValue)#\(UUID().uuidString)"
                : item.id
            guard LocalStorage.shared().addServiceType(
                serviceTypeId,
                windowType: windowType
            ) else {
                continue
            }
            addedTypeIds.append(serviceTypeId)
            addedItems.append(item)
        }

        guard let selectedTypeId = addedTypeIds.last else { return }
        setSelection([.service(selectedTypeId)])
        postUpdateServiceNotification()
        reloadLLMSubscribersIfNeeded(for: addedItems)
        updateServices()
    }

    func removeSelectedServices() {
        let selectedItems = selectedServiceItems
        guard !selectedItems.isEmpty, selectedItems.count < serviceItems.count else { return }

        let selectedTypeIds = Set(selectedItems.map(\.id))
        let remainingTypeIds = serviceItems
            .map(\.id)
            .filter { !selectedTypeIds.contains($0) }
        LocalStorage.shared().setAllServiceTypes(
            remainingTypeIds,
            windowType: windowType
        )

        setSelection([.windowConfiguration])
        postUpdateServiceNotification()
        reloadLLMSubscribersIfNeeded(for: selectedItems)
        updateServices()
    }

    func selectItems(_ items: Set<ServiceTabSelection>) {
        let addedItems = items.subtracting(selectedItems)
        var selection = items

        if addedItems.contains(.windowConfiguration) {
            selection = [.windowConfiguration]
        } else {
            selection.remove(.windowConfiguration)
        }

        let preferredItem = orderedSelection(in: addedItems)
            ?? selectedItem
        setSelection(selection, preferred: preferredItem)
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
        reloadLLMSubscribersIfNeeded(for: [item])
        updateServices()
    }

    func postUpdateServiceNotification() {
        NotificationCenter.default.postServiceUpdateNotification(windowType: windowType)
    }

    // MARK: Private

    private var selectedItem: ServiceTabSelection? = .windowConfiguration

    private var selectedServiceItems: [ServiceListItem] {
        serviceItems.filter {
            selectedItems.contains(.service($0.id))
        }
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

    private func orderedSelection(
        in selections: Set<ServiceTabSelection>
    )
        -> ServiceTabSelection? {
        if selections.contains(.windowConfiguration) {
            return .windowConfiguration
        }
        return serviceItems.reversed().lazy
            .map { ServiceTabSelection.service($0.id) }
            .first { selections.contains($0) }
    }

    private func setSelection(
        _ selection: Set<ServiceTabSelection>,
        preferred: ServiceTabSelection? = nil
    ) {
        let selection = selection.isEmpty
            ? Set([ServiceTabSelection.windowConfiguration])
            : selection
        selectedItems = selection
        selectedItem = preferred.flatMap {
            selection.contains($0) ? $0 : nil
        } ?? orderedSelection(in: selection)
        updateSelectedService()
    }

    private func reloadLLMSubscribersIfNeeded(for items: [ServiceListItem]) {
        // Stream configuration observers cover all window memberships, so any
        // window can add or remove a service that changes the observed union.
        guard items.contains(where: { $0.isStream }) else { return }
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
