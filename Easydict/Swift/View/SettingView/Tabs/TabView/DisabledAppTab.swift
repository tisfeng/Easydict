//
//  DisabledAppTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import SwiftUI

// MARK: - DisabledAppViewModel

private class DisabledAppViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        fetchDisabledApps()
    }

    // MARK: Internal

    @Published var appModelList: [EZAppModel] = []
    @Published var selectedAppModels: Set<EZAppModel> = []
    @Published var isShowImportErrorAlert = false

    @Published var isImporting = false {
        didSet {
            // https://github.com/tisfeng/Easydict/issues/346
            Configuration.shared.disabledAutoSelect = isImporting
        }
    }

    func fetchDisabledApps() {
        let allAppModelList = EZLocalStorage.shared().selectTextTypeAppModelList

        appModelList = allAppModelList.compactMap { appModel in
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appModel.appBundleID)
            return url == nil ? nil : appModel
        }
    }

    func saveDisabledApps() {
        EZLocalStorage.shared().selectTextTypeAppModelList = appModelList
    }

    func removeDisabledApp() {
        appModelList = appModelList.filter { !selectedAppModels.contains($0) }
        saveDisabledApps()
        selectedAppModels = []
    }

    func newAppURLsSelected(from urls: [URL]) {
        urls.forEach { url in
            let gotAccess = url.startAccessingSecurityScopedResource()
            if !gotAccess { return }
            appendNewDisabledApp(for: url)
            url.stopAccessingSecurityScopedResource()
        }
    }

    func appendNewDisabledApp(for url: URL) {
        guard let selectAppModel = disabledAppModel(from: url) else { return }
        guard !appModelList.contains(selectAppModel) else { return }
        appModelList.append(selectAppModel)
        saveDisabledApps()
    }

    func disabledAppModel(from url: URL) -> EZAppModel? {
        let appModel = EZAppModel()
        guard let bundle = Bundle(url: url) else { return nil }
        appModel.appBundleID = bundle.bundleIdentifier ?? ""
        appModel.triggerType = []
        return appModel
    }
}

// MARK: - DisabledAppTab

struct DisabledAppTab: View {
    // MARK: Internal

    var listToolbar: some View {
        ListToolbar()
            .fileImporter(
                isPresented: $disabledAppViewModel.isImporting,
                allowedContentTypes: [.application],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case let .success(urls):
                    disabledAppViewModel.newAppURLsSelected(from: urls)
                case let .failure(error):
                    logError("fileImporter error: \(error)")
                    disabledAppViewModel.isShowImportErrorAlert.toggle()
                }
            }
            .alert(isPresented: $disabledAppViewModel.isShowImportErrorAlert) {
                Alert(
                    title: Text(""),
                    message: Text("setting.disabled.import_app_error.message"),
                    dismissButton: .default(Text("ok"))
                )
            }
    }

    var appListView: some View {
        List(selection: $disabledAppViewModel.selectedAppModels) {
            ForEach(disabledAppViewModel.appModelList, id: \.self) { app in
                BlockAppItemView(with: app)
                    .tag(app)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollIndicators(.never)
    }

    var appListViewWithToolbar: some View {
        VStack(spacing: 0) {
            appListView

            listToolbar
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(content: {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("list_border_color"), lineWidth: 0.5)
        })
        .padding(.horizontal, 25)
        .padding(.bottom, 25)
        .onTapGesture {
            disabledAppViewModel.selectedAppModels = []
        }
    }

    var body: some View {
        VStack {
            Text("disabled_title")
                .padding(.horizontal)
                .padding(.top, 18)
                .padding(.bottom, 8)

            appListViewWithToolbar
        }
        .environmentObject(disabledAppViewModel)
    }

    // MARK: Private

    @StateObject private var disabledAppViewModel = DisabledAppViewModel()
}

// MARK: - ListToolbar

private struct ListToolbar: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ListButton(systemName: "plus") {
                    disabledAppViewModel.isImporting.toggle()
                }
                .disabled(false)
                Divider()
                    .padding(.vertical, 1)
                ListButton(systemName: "minus") {
                    disabledAppViewModel.removeDisabledApp()
                }
                .disabled(disabledAppViewModel.selectedAppModels.isEmpty)
                Spacer()
            }
            .padding(2)
        }
        .frame(height: 28)
        .background(Color("add_minus_bg_color"))
    }

    // MARK: Private

    @EnvironmentObject private var disabledAppViewModel: DisabledAppViewModel
}

// MARK: - ListButton

private struct ListButton: View {
    @Environment(\.isEnabled) private var isEnabled: Bool
    var systemName: String
    var action: () -> ()

    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
                .foregroundStyle(isEnabled ? Color(.secondaryLabelColor) : Color(.tertiaryLabelColor))
                .font(.system(size: 14, weight: .semibold))
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

// MARK: - BlockAppItemView

private struct BlockAppItemView: View {
    // MARK: Lifecycle

    init(with appModel: EZAppModel) {
        _appItemViewModel = StateObject(wrappedValue: AppItemViewModel(appModel: appModel))
    }

    // MARK: Internal

    @EnvironmentObject var disabledAppViewModel: DisabledAppViewModel

    var body: some View {
        HStack(alignment: .center) {
            Image(nsImage: appItemViewModel.appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text(appItemViewModel.appName)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .padding(.leading, 6)
    }

    // MARK: Private

    @StateObject private var appItemViewModel: AppItemViewModel
}

// MARK: - AppItemViewModel

private class AppItemViewModel: ObservableObject {
    // MARK: Lifecycle

    init(appModel: EZAppModel) {
        self.appModel = appModel
        getAppBundleInfo()
    }

    // MARK: Internal

    @Published var appIcon = NSImage()

    @Published var appName = ""

    var appModel: EZAppModel

    func getAppBundleInfo() {
        let appBundleId = appModel.appBundleID
        let workspace = NSWorkspace.shared
        let appURL = workspace.urlForApplication(withBundleIdentifier: appBundleId)
        guard let appURL else { return }

        let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleId)
        guard let appPath else { return }
        appIcon = workspace.icon(forFile: appPath.path(percentEncoded: false))

        guard let appBundle = Bundle(url: appURL) else { return }
        appName = appBundle.applicationName
    }
}

#Preview {
    DisabledAppTab()
}
