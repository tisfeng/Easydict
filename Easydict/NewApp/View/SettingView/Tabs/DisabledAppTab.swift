//
//  DisabledAppTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import SwiftUI

class DisabledAppViewModel: ObservableObject {
    @Published var appModelList: [EZAppModel] = []

    @Published var selectedAppModels: Set<EZAppModel> = []

    @Published var isImporting = false

    func fetchDisabledApps() {
        appModelList = EZLocalStorage.shared().selectTextTypeAppModelList
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

@available(macOS 13.0, *)
struct DisabledAppTab: View {
    @ObservedObject var disabledAppViewModel = DisabledAppViewModel()

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
                    print("fileImporter error: \(error)")
                }
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
        .padding(.bottom)
        .padding(.horizontal, 35)
        .onTapGesture {
            disabledAppViewModel.selectedAppModels = []
        }
    }

    var body: some View {
        VStack {
            Text("disabled_title")
                .padding()

            appListViewWithToolbar
        }
        .frame(maxWidth: 500)
        .environmentObject(disabledAppViewModel)
        .onAppear {
            disabledAppViewModel.fetchDisabledApps()
        }
    }
}

@available(macOS 13.0, *)
struct ListToolbar: View {
    @EnvironmentObject private var disabledAppViewModel: DisabledAppViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ListButton(imageName: "plus") {
                    disabledAppViewModel.isImporting.toggle()
                }
                Divider()
                ListButton(imageName: "minus") {
                    disabledAppViewModel.removeDisabledApp()
                }
                .disabled(disabledAppViewModel.selectedAppModels.isEmpty)
                Spacer()
            }
            .padding(2)
        }
        .frame(height: 28)
        .background(Color(.controlBackgroundColor))
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
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

@available(macOS 13.0, *)
struct BlockAppItemView: View {
    @StateObject private var appFetcher: AppFetcher

    @EnvironmentObject var disabledAppViewModel: DisabledAppViewModel

    private var listRowBgColor: Color {
        disabledAppViewModel.selectedAppModels.contains {
            $0.appBundleID == appFetcher.appModel.appBundleID
        } ? Color("service_cell_highlight") : .clear
    }

    init(with appModel: EZAppModel) {
        _appFetcher = StateObject(wrappedValue: AppFetcher(appModel: appModel))
    }

    var body: some View {
        HStack(alignment: .center) {
            Image(nsImage: appFetcher.appIcon ?? NSImage())
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text(appFetcher.appName)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .listRowBackground(listRowBgColor)
        .padding(.vertical, 4)
        .padding(.leading, 6)
        .task {
            appFetcher.getAppBundleInfo()
        }
    }
}

@available(macOS 13.0, *)
class AppFetcher: ObservableObject {
    @Published var appIcon: NSImage? = nil

    @Published var appName = ""

    var appModel: EZAppModel

    init(appModel: EZAppModel) {
        self.appModel = appModel
    }

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

@available(macOS 13.0, *)
#Preview {
    DisabledAppTab()
}
