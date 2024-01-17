//
//  DisabledTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import SwiftUI

class DisableViewModel: ObservableObject {
    @Published var appModelList: [EZAppModel] = []

    @Published var selectedAppModel: EZAppModel? = nil

    @Published var isImporting = false

    func fetchDisabledApps() {
        appModelList = EZLocalStorage.shared().selectTextTypeAppModelList
    }

    func removeDisabledApp() {
        appModelList = appModelList.filter { $0.appBundleID != selectedAppModel?.appBundleID }
        EZLocalStorage.shared().selectTextTypeAppModelList = appModelList
    }

    func newAppSelected(for url: URL) {
        guard let newSelectApp = newBlockApps(url: url) else { return }

        appModelList.append(newSelectApp)
        EZLocalStorage.shared().selectTextTypeAppModelList = appModelList
    }

    func newBlockApps(url: URL) -> EZAppModel? {
        let appModel = EZAppModel()
        guard let bundle = Bundle(url: url) else { return nil }
        appModel.appBundleID = bundle.bundleIdentifier ?? ""
        appModel.triggerType = []
        return appModel
    }
}

@available(macOS 13.0, *)
struct DisabledTab: View {

    @ObservedObject var viewModel = DisableViewModel()

    var appListView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.appModelList, id: \.self) { app in
                    BlockAppItemView(with: app)
                        .tag(app)
                        .environmentObject(viewModel)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)

            ListToolbar()
                .environmentObject(viewModel)
                .fileImporter(
                    isPresented: $viewModel.isImporting,
                    allowedContentTypes: [.application],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case let .success(urls):
                        urls.forEach { url in
                            let gotAccess = url.startAccessingSecurityScopedResource()
                            if !gotAccess { return }
                            viewModel.newAppSelected(for: url)
                            url.stopAccessingSecurityScopedResource()
                        }
                    case let .failure(error):
                        print("error: \(error)")
                    }
                }
        }
        .frame(maxWidth: 420)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding([.bottom])
    }

    var body: some View {
        VStack {
            Text("disabled_title")
                .padding()

            appListView
        }
        .task {
            viewModel.fetchDisabledApps()
        }
    }
}

@available(macOS 13.0, *)
struct ListToolbar: View {
    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject var viewModel: DisableViewModel

    var bgColor: Color {
        Color(nsColor: colorScheme == .light ? NSColor.controlBackgroundColor : NSColor.controlBackgroundColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ListButton(imageName: "plus") {
                    viewModel.isImporting.toggle()
                }
                Divider()
                ListButton(imageName: "minus") {
                    viewModel.removeDisabledApp()
                }
                Spacer()
            }
            .padding(2)
        }
        .frame(height: 28)
        .background(bgColor)
    }
}

@available(macOS 13.0, *)
struct ListButton: View {
    var imageName: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: imageName)
        }
        .buttonStyle(BorderlessButtonStyle())
        .contentShape(Rectangle())
        .frame(width: 24, height: 24)
    }
}

@available(macOS 13.0, *)
struct BlockAppItemView: View {
    var app: EZAppModel

    @ObservedObject var appFetcher: AppFetcher

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject var viewModel: DisableViewModel

    private var tableColor: Color {
        Color(nsColor: colorScheme == .light ? .ez_tableRowViewBgLight() : .ez_tableRowViewBgDark())
    }

    init(with appModel: EZAppModel) {
        app = appModel
        appFetcher = AppFetcher(appBundleId: app.appBundleID)
    }

    var body: some View {
        HStack(alignment: .center) {
            Image(nsImage: appFetcher.appIcon ?? NSImage())
                .resizable()
                .frame(width: 24, height: 24)

            Text(appFetcher.appName)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .overlay {
            TapHandler {
                let selectedAppModel = viewModel.selectedAppModel
                if selectedAppModel == nil || selectedAppModel != app {
                    viewModel.selectedAppModel = app
                } else {
                    viewModel.selectedAppModel = nil
                }
            }
        }
        .listRowBackground(viewModel.selectedAppModel == app ? Color("service_cell_highlight") : .clear)
    }
}

@available(macOS 13.0, *)
class AppFetcher: ObservableObject {
    @Published var appIcon: NSImage? = nil
    @Published var appName = ""

    init(appBundleId: String) {
        let workspace = NSWorkspace.shared
        guard let appURL = workspace.urlForApplication(withBundleIdentifier: appBundleId) else {
            return
        }
        print("path: \(appURL.path())")
        appIcon = getApplicationIcon(forAppBundleIdentifier: appBundleId)

        guard let appBundle = Bundle(url: appURL) else {
            return
        }
        appName = appBundle.applicationName
    }

    func getApplicationIcon(forAppBundleIdentifier bundleIdentifier: String) -> NSImage? {
        let workspace = NSWorkspace.shared

        // If the app is not running, try to get the icon from the app bundle
        if let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = workspace.icon(forFile: appPath.path(percentEncoded: false))
            return icon
        }

        return nil
    }
}

extension Bundle {
    var applicationName: String {
        if let displayName: String = infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        } else if let name: String = infoDictionary?["CFBundleName"] as? String {
            return name
        }
        if let executableURL {
            return executableURL.deletingLastPathComponent().lastPathComponent
        }
        return ""
    }
}

@available(macOS 13.0, *)
#Preview {
    DisabledTab()
}
