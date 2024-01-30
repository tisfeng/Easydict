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
        translate("hello world!", from: .english, to: .simplifiedChinese, completion: completion)
    }
}
