//
//  AcknowListView.swift
//  Easydict
//
//  Created by tisfeng on 2024/11/5.
//  Copyright © 2024 izual. All rights reserved.
//

import AcknowList
import SwiftUI

// MARK: - AcknowListView

struct AcknowListView: View {
    // MARK: Lifecycle

    init() {
        loadPackageInfo()
    }

    // MARK: Internal

    var body: some View {
        NavigationStack {
            AcknowListSwiftUIView(acknowList: acknowList)
        }
        .hideWindowToolbarBackground()
        .thickMaterialWindowBackground()
    }

    // MARK: Private

    @State private var acknowList: AcknowList?

    private mutating func loadPackageInfo() {
        var acknowList = AcknowParser.defaultAcknowList()

        // Manual acknow list
        let manualAcknowList: [Acknow] = [
            .init(
                title: "DictionaryKit",
                repository: URL(string: "https://github.com/NSHipster/DictionaryKit.git")!
            ),
            .init(
                title: "ArgumentParser",
                repository: URL(string: "https://github.com/mysteriouspants/ArgumentParser")!
            ),
            .init(
                title: "CoolToast",
                repository: URL(string: "https://github.com/socoolby/CoolToast")!
            ),
            .init(
                title: "Snip",
                repository: URL(string: "https://github.com/isee15/Capture-Screen-For-Multi-Screens-On-Mac")!
            ),
        ]

        acknowList?.acknowledgements += manualAcknowList

        // Update state
        _acknowList = State(initialValue: acknowList)
    }
}

// MARK: - AcknowListView_Previews

struct AcknowListView_Previews: PreviewProvider {
    static var previews: some View {
        AcknowListView()
    }
}
