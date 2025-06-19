//
//  YoudaoEntityTranslateService.swift
//  Easydict
//
//  Created by AI Agent on 2024-03-07. // Updated with actuals
//  Copyright © 2024 izual. All rights reserved. // Update if needed
//

import Foundation

@objc(EZYoudaoEntityTranslateService)
class YoudaoEntityTranslateService: YoudaoService {

    override func serviceType() -> ServiceType {
        .youdaoEntityTranslate // New service type
    }

    override func name() -> String {
        // Needs to be localized, add to Localizable.xcstrings later
        // For now, use a placeholder or direct string:
        NSLocalizedString("youdao_entity_translate", comment: "Youdao Entity Translate Service Name")
    }

    // It's good practice to have a unique icon for this service.
    // This will be used in a later step to add the actual asset.
    override func iconName() -> String {
        return "youdaoEntityTranslate" // Placeholder, will correspond to an image asset
    }

    // Override the main translate method to use the new entityTranslate
    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        Task {
            do {
                guard !text.isEmpty else {
                    throw QueryError(type: .parameter, message: "Translation text is empty")
                }
                // Call the entityTranslate method defined in YoudaoService
                let result = try await entityTranslate(text: text, from: from, to: to)
                completion(result, nil)
            } catch {
                // Ensure a EZQueryResult is always passed to the completion handler, even in case of error.
                // Create a basic EZQueryResult if 'self.result' isn't appropriate or guaranteed to be in a safe state.
                let errorResult = EZQueryResult(queryText: text, from: from, to: to)
                completion(errorResult, error)
            }
        }
    }
}
