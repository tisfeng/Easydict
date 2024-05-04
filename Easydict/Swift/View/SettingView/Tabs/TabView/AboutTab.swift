//
//  AboutTab.swift
//  Easydict
//
//  Created by Kyle on 2023/10/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI
import Vortex

// MARK: - SettingsAboutTab

// Use ScrollView to enable resize animation for Settings
@available(macOS 13, *)
struct SettingsAboutTab: View {
    var body: some View {
        ScrollView {
            AboutTab()
        }
    }
}

// MARK: - AboutTab

@available(macOS 13, *)
struct AboutTab: View {
    // MARK: Internal

    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            Image(.logo)
                .resizable()
                .frame(width: 100, height: 100)
                .padding()
                .shadow(color: .gray, radius: 1, x: 0, y: 0.8)

            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text(appName)
                        .font(.system(size: 35, weight: .medium))
                        .padding(.top, 25)
                        .padding(.bottom, 3)

                    Text("current_version \(version)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    Text(copyrightInfo)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.top, 25)
                        .padding(.bottom, 20)
                }

                HStack(spacing: 15) {
                    Button {
                        NSWorkspace.shared.open(URL(string: "https://github.com/tisfeng/Easydict")!)
                    } label: {
                        Label("github_link", systemImage: "star.fill")
                            .frame(width: 120, height: 20)
                    }

                    Button {
                        NSWorkspace.shared
                            .open(URL(string: "https://github.com/tisfeng/Easydict/graphs/contributors")!)
                    } label: {
                        Label("contributor_link", systemImage: "person.3.sequence.fill")
                            .frame(width: 120, height: 20)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Private

    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private var copyrightInfo: String {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
    }
}

@available(macOS 13, *)
#Preview {
    AboutTab()
}
