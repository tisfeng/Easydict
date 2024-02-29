//
//  ServiceSecretConfigreValidatable.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - ServiceSecretConfigreValidatable

protocol ServiceSecretConfigreValidatable {
    func validate(completion: @escaping (EZQueryResult, Error?) -> ())
}

extension ServiceSecretConfigreValidatable {
    func validate(completion _: @escaping (EZQueryResult, Error?) -> ()) {}
}

// MARK: - QueryService + ServiceSecretConfigreValidatable

extension QueryService: ServiceSecretConfigreValidatable {
    func validate(completion: @escaping (EZQueryResult, Error?) -> ()) {
        resetServiceResult()
        /**
         To reduce output text, save cost, a simple translation example is enough.

         1. use zh -> en to avoid analyze English sentence.
         2. if Chinese text length > 5, it won't query dict.
         */
        translate("曾经沧海难为水", from: .simplifiedChinese, to: .english, completion: completion)
    }
}
