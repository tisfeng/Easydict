//
//  MenuItemView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SettingsAccess
import SFSafeSymbols
import Sparkle
import SwiftUI
import Vision
import ZipArchive

// MARK: - MenuItemStore

final class MenuItemStore: ObservableObject {
    // MARK: Lifecycle

    init() {
        Configuration.shared.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    // MARK: Internal

    @Published var canCheckForUpdates = false
}

// MARK: - MenuItemView

struct MenuItemView: View {
    // MARK: Internal

    var body: some View {
        // .menuBarExtraStyle为 .menu 时某些控件可能会失效，只能显示内容（按照菜单项高度、图像以 template 方式渲染）无法交互
        // 比如 Stepper、Slider 等，像基本的 Button、Text、Divider、Image 等还是能正常显示的。
        // Button 和Label的systemImage是不会渲染的
        Group {
            versionItem
            Divider()
            inputItem.keyboardShortcut(.inputTranslate)
            screenshotItem.keyboardShortcut(.snipTranslate)
            selectWordItem.keyboardShortcut(.selectTranslate)
            pasteboardTranslateItem
            miniWindowItem.keyboardShortcut(.showMiniWindow)

            Divider()

            silentScreenshotOCRItem.keyboardShortcut(.silentScreenshotOCR)

            if showOCRMenuItems {
                screenshotOCRItem
                pasteboardOCRItem
                showOCRWindowItem
            }

            Divider()

            settingItem.keyboardShortcut(.init(","))
            checkUpdateItem
            helpItem

            Divider()

            quitItem.keyboardShortcut(.init("q"))
        }
        .task {
            latestVersion = await fetchRepoLatestVersion(EZGithubRepoEasydict)
        }
    }

    // MARK: Private

    @ObservedObject private var store = MenuItemStore()
    @Default(.showOCRMenuItems) private var showOCRMenuItems

    @State private var currentVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    @State private var latestVersion: String?

    @Environment(\.openURL) private var openURL

    private var versionString: String {
        let defaultLabel = "Easydict  \(currentVersion)"
        if let latestVersion,
           currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending {
            return defaultLabel + "  (✨\(latestVersion) )"
        } else {
            return defaultLabel
        }
    }

    @ViewBuilder private var versionItem: some View {
        Button(versionString) {
            guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/releases") else {
                return
            }
            openURL(versionURL)
        }
    }

    @ViewBuilder private var settingItem: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Settings...")
            } preAction: {
                logInfo("Open App Settings")
                NSApplication.shared.activateApp()
            } postAction: {
                // nothing to do
            }
        } else {
            Button("Settings...") {
                logInfo("Open App Settings")
                NSApplication.shared.activateApp()
                NSApplication.shared.sendAction(
                    Selector(("showSettingsWindow:")), to: nil, from: nil
                )
            }
        }
    }

    // MARK: - List of functions

    @ViewBuilder private var inputItem: some View {
        Button {
            logInfo("Input Translate")
            EZWindowManager.shared().inputTranslate()
        } label: {
            HStack {
                Image(systemName: "keyboard")
                Text("menu_input_translate")
            }
        }
    }

    @ViewBuilder private var screenshotItem: some View {
        Button {
            logInfo("Screenshot Translate")
            EZWindowManager.shared().snipTranslate()
        } label: {
            HStack {
                Image(systemSymbol: .cameraViewfinder)
                Text("menu_screenshot_Translate")
            }
        }
    }

    @ViewBuilder private var selectWordItem: some View {
        Button {
            logInfo("Select Text Translate")
            EZWindowManager.shared().selectTextTranslate()
        } label: {
            HStack {
                Image(systemSymbol: .highlighter)
                Text("menu_selectWord_Translate")
            }
        }
    }

    @ViewBuilder private var pasteboardTranslateItem: some View {
        Button {
            logInfo("Pasteboard Translate")
            EZWindowManager.shared().pasteboardTranslate()
        } label: {
            HStack {
                Image(systemSymbol: .docOnClipboard)
                Text("menu_pasteboard_translate")
            }
        }
    }

    @ViewBuilder private var miniWindowItem: some View {
        Button {
            logInfo("Show Mini Window")
            EZWindowManager.shared().showMiniFloatingWindow()
        } label: {
            HStack {
                Image(systemSymbol: .dockRectangle)
                Text("menu_show_mini_window")
            }
        }
    }

    @ViewBuilder private var silentScreenshotOCRItem: some View {
        Button {
            logInfo("Silent Screenshot OCR")
            EZWindowManager.shared().silentScreenshotOCR()
        } label: {
            HStack {
                Image(systemSymbol: .cameraMeteringSpot)
                Text("menu_silent_screenshot_OCR")
            }
        }
    }

    @ViewBuilder private var screenshotOCRItem: some View {
        Button {
            EZWindowManager.shared().screenshotOCR()
        } label: {
            HStack {
                Image(systemSymbol: .cameraMeteringMultispot)
                Text("menu_screenshot_OCR")
            }
        }
    }

    @ViewBuilder private var pasteboardOCRItem: some View {
        Button {
            AppleOCREngine().pasteboardOCR()
        } label: {
            HStack {
                Image(systemSymbol: .listClipboard)
                Text("menu_pasteboard_OCR")
            }
        }
    }

    @ViewBuilder private var showOCRWindowItem: some View {
        Button {
            logInfo("Show OCR Window")
            // Simply show the OCR window without updating data
            OCRWindowManager.shared.showWindow()
        } label: {
            HStack {
                Image(systemSymbol: .textAndCommandMacwindow)
                Text("menu_show_ocr_window")
            }
        }
    }

    // MARK: - Setting

    @ViewBuilder private var checkUpdateItem: some View {
        Button("check_updates") {
            logInfo("Check Updates")
            Configuration.shared.updater.checkForUpdates()
        }.disabled(!store.canCheckForUpdates)
    }

    @ViewBuilder private var quitItem: some View {
        Button("quit") {
            logInfo("Quit Application")
            NSApplication.shared.terminate(nil)
        }
    }

    @ViewBuilder private var helpItem: some View {
        Menu("Help") {
            Button("Feedback") {
                logInfo("Open Feedback")
                guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/issues") else {
                    return
                }
                openURL(versionURL)
            }
            Button("Export Log") {
                exportLogAction()
            }
            Button("Log Directory") {
                logInfo("Open Log Directory")
                let logPath = MMManagerForLog.rootLogDirectory() ?? ""
                let directoryURL = URL(fileURLWithPath: logPath)
                NSWorkspace.shared.open(directoryURL)
            }
        }
    }

    private func exportLogAction() {
        logInfo("Export Log")
        let logPath = MMManagerForLog.rootLogDirectory() ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"
        let dataString = dateFormatter.string(from: Date())
        let downloadDirectory = FileManager.default.urls(
            for: .downloadsDirectory, in: .userDomainMask
        )[0]
        let zipPath = downloadDirectory.appendingPathComponent("Easydict log \(dataString).zip")
            .path(percentEncoded: false)
        let success = SSZipArchive.createZipFile(
            atPath: zipPath,
            withContentsOfDirectory: logPath,
            keepParentDirectory: false
        )
        if success {
            NSWorkspace.shared.selectFile(zipPath, inFileViewerRootedAtPath: "")
        } else {
            logError("Export log failed")
        }
    }

    private func ocr(image: NSImage) {
        // Get the CGImage on which to perform requests.
        guard let cgImage = image.toCGImage() else { return }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        let recognizeTextHandler = { (request: VNRequest, error: Error?) in
            if let error {
                print("Error recognizing text: \(error)")
                return
            }

            // Get the results from the request.
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text recognized.")
                return
            }

            // Process the recognized text observations.
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    print("Recognized text: \(topCandidate.string)")
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            // Create a new request to recognize text.
            let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
            request.usesLanguageCorrection = true
            request.recognitionLevel = .accurate
            request.recognitionLanguages = [
                "zh-Hans",
                "zh-Hant",
                "en-US",
                "ja-JP",
                "fr-FR",
                "de-DE",
                "es-ES",
                "pt-BR",
                "it-IT",
                "ko-KR",
                "ru-RU",
                "uk-UA",
            ]

            do {
                // Perform the text-recognition request.
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform the requests: \(error).")
            }
        }
    }
}

#Preview {
    MenuItemView()
}
