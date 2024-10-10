//
//  TranslationService.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/10.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI
import Translation

@available(macOS 15.0, *)
class TranslationService {
    // MARK: Lifecycle

    init() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hostingController = NSHostingController(
                rootView: TranslationView(manager: manager)
            )

            if let window = NSApplication.shared.windows.first {
                window.contentView?.addSubview(hostingController!.view)
                hostingController?.view.isHidden = true
            }
        }
    }

    // MARK: Internal

    func translate(
        text: String,
        sourceLanguage: Locale.Language?,
        targetLanguage: Locale.Language?
    ) async throws
        -> TranslationSession.Response {
        try await manager.translate(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
    }

    // MARK: Private

    private let manager = TranslationManager()
    private var hostingController: NSHostingController<TranslationView>?
}
