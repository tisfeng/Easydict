//
//  AboutTab.swift
//  Easydict
//
//  Created by Kyle on 2023/10/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI

// MARK: - AboutTabWrapper

@available(macOS 13, *)
@objcMembers
class AboutTabWrapper: NSObject {
    func makeNSView() -> NSView {
        NSHostingView(rootView: AboutTab())
    }
}

// MARK: - AboutTab

@available(macOS 13, *)
struct AboutTab: View {
    // MARK: Internal

    var body: some View {
        ScrollView {
            HStack(alignment: .center, spacing: 20) {
                Image(.logo)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .padding()
                    .shadow(color: .gray, radius: 1, x: 0, y: 0.8)

                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(appName)
                            .font(.system(size: 26, weight: .semibold))

                        Spacer()
                            .frame(height: 3)

                        Text("current_version \(version)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Spacer()
                            .frame(height: 20)

                        Text(copyrightInfo)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 3)

                    HStack {
                        Button {
                            NSWorkspace.shared.open(URL(string: "https://github.com/tisfeng/Easydict")!)
                        } label: {
                            Label("github_link", systemImage: "star.fill")
                                .frame(width: 120)
                        }

                        Button {
                            NSWorkspace.shared
                                .open(URL(string: "https://github.com/tisfeng/Easydict/graphs/contributors")!)
                        } label: {
                            Label("contributor_link", systemImage: "person.3.sequence.fill")
                                .frame(width: 120)
                        }
                    }
                }
            }
            .padding(.top, 20)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
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
