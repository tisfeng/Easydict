//
//  AboutTab.swift
//  Easydict
//
//  Created by Kyle on 2023/10/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - AboutTab

struct AboutTab: View {
    // MARK: Internal

    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            Image(.logo)
                .resizable()
                .renderingMode(.original)
                .frame(width: 100, height: 100)
                .shadow(color: .gray, radius: 1, x: 0, y: 0.8)
                .padding(.bottom, 2)
                .padding(.leading, 16)
                .padding(.trailing, 16)

            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(appName)
                        .font(.system(size: 35, weight: .medium))
                        .padding(.bottom, 3)

                    Text("current_version \(version)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.bottom, 29)

                    Text(copyrightInfo)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }

                HStack(spacing: 15) {
                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "https://github.com/tisfeng/Easydict")!
                        )
                    } label: {
                        Label("setting.about.github_link", systemSymbol: .starFill)
                    }

                    Button {
                        NSWorkspace.shared
                            .open(
                                URL(
                                    string:
                                    "https://github.com/tisfeng/Easydict/graphs/contributors"
                                )!
                            )
                    } label: {
                        Label("setting.about.contributor_link", systemSymbol: .person3Fill)
                    }

                    Button {
                        HostWindowManager.shared.showAcknowWindow()
                    } label: {
                        Label("setting.about.acknowledgements", systemSymbol: .checkmarkSealFill)
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: Private

    @Environment(\.openWindow) private var openWindow

    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private var copyrightInfo: String {
        Bundle.main.localizedString(
            forKey: "NSHumanReadableCopyright",
            value: "Copyright © 2023-2025 tisfeng. All rights reserved.",
            table: "InfoPlist"
        )
    }
}

#Preview {
    AboutTab()
}
