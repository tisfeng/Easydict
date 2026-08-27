//
//  SystemUtility+Selection.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/9.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SelectedTextKit

extension SystemUtility {
    @objc
    public func getSelectedText(strategy: TextStrategy) async throws -> String? {
        switch strategy {
        case .accessibility:
            return try await getSelectedTextByAccessibility()
        default:
            return try await selectedTextManager.getSelectedText(strategy: strategy)
        }
    }

    /// Falls back to Zen's text-marker API when regular Accessibility text is unavailable.
    private func getSelectedTextByAccessibility() async throws -> String? {
        do {
            let selectedText = try await selectedTextManager.getSelectedText(strategy: .accessibility)
            if selectedText?.isEmpty == false {
                return selectedText
            }
        } catch {
            if let selectedText = selectedTextByZenTextMarkerRange(),
               !selectedText.isEmpty {
                return selectedText
            }
            throw error
        }

        return selectedTextByZenTextMarkerRange()
    }
}
