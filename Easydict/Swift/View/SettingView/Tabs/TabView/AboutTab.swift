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
        VortexViewReader { proxy in
            GeometryReader { geometry in
                ZStack {
                    VortexView(.confetti) {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 16, height: 16)
                            .tag("square")

                        Circle()
                            .fill(.white)
                            .frame(width: 16)
                            .tag("circle")
                    }
                    .frame(height: 220)

                    HStack(alignment: .center, spacing: 30) {
                        Image(.logo)
                            .resizable()
                            .renderingMode(.original)
                            .frame(width: 100, height: 100)
                            .shadow(color: .gray, radius: 1, x: 0, y: 0.8)
                            .padding(.bottom, 2)
                            .padding(.leading, 16)
                            .padding(.trailing, 16)
                            .onTapGesture { location in
                                proxy.move(
                                    to:
                                    CGPoint(
                                        x: location.x + ((geometry.size.width / 2) - 222),
                                        y: location.y + 60
                                    )
                                )
                                proxy.burst()
                            }
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
                                    NSWorkspace.shared.open(URL(string: "https://github.com/tisfeng/Easydict")!)
                                } label: {
                                    Label("setting.about.github_link", systemImage: "star.fill")
                                        .frame(width: 120, height: 20)
                                }

                                Button {
                                    NSWorkspace.shared
                                        .open(URL(string: "https://github.com/tisfeng/Easydict/graphs/contributors")!)
                                } label: {
                                    Label("setting.about.contributor_link", systemImage: "person.3.sequence.fill")
                                        .frame(width: 120, height: 20)
                                }
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
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
