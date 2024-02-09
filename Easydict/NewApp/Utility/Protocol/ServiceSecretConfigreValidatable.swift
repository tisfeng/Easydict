//
//  ServiceSecretConfigreValidatable.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

protocol ServiceSecretConfigreValidatable {
    func validate(completion: @escaping (EZQueryResult, Error?) -> Void)
}

extension ServiceSecretConfigreValidatable {
    func validate(completion _: @escaping (EZQueryResult, Error?) -> Void) {}
}

extension QueryService: ServiceSecretConfigreValidatable {
    func validate(completion: @escaping (EZQueryResult, Error?) -> Void) {
        resetServiceResult()
        /**
         To reduce output text, save cost, a simple translation example is enough.
         
         1. use zh -> en to avoid analyze English sentence.
         2. if Chinese text length > 5, it won't query dict.
         */
        translate("曾经沧海难为水", from: .simplifiedChinese, to: .english, completion: completion)
    }
}
