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
            AcknowListSwiftUIView(acknowledgements: acknowledgements)
        }
    }

    // MARK: Private

    @State private var acknowledgements: [Acknow] = []

    private mutating func loadPackageInfo() {
        var allAcknowledgements: [Acknow] = []

        // Load SPM dependencies
        if let url = Bundle.main.url(forResource: "Package", withExtension: "resolved"),
           let data = try? Data(contentsOf: url),
           let spmList = try? AcknowPackageDecoder().decode(from: data) {
            allAcknowledgements.append(contentsOf: spmList.acknowledgements)
        }

        // Load CocoaPods dependencies
        if let url = Bundle.main.url(
            forResource: "Pods-Easydict-acknowledgements", withExtension: "plist"
        ),
            let data = try? Data(contentsOf: url),
            let podList = try? AcknowPodDecoder().decode(from: data) {
            allAcknowledgements.append(contentsOf: podList.acknowledgements)
        }

        // Sort by name
        allAcknowledgements.sort { $0.title.lowercased() < $1.title.lowercased() }

        // Update state
        _acknowledgements = State(initialValue: allAcknowledgements)
    }
}

// MARK: - AcknowListView_Previews

struct AcknowListView_Previews: PreviewProvider {
    static var previews: some View {
        AcknowListView()
    }
}
