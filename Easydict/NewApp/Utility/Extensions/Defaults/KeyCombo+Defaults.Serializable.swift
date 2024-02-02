//
//  KeyCombo+Defaults.Serializable.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/21.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import Magnet

extension KeyCombo: Defaults.Serializable {
    public static var bridge = ShortcutBridge()

    public struct ShortcutBridge: Defaults.Bridge {
        public func serialize(_ value: Magnet.KeyCombo??) -> Data? {
            guard let value else { return nil }
            return try? JSONEncoder().encode(value)
        }

        public func deserialize(_ object: Data?) -> Magnet.KeyCombo?? {
            guard let data = object else { return nil }
            return try? JSONDecoder().decode(KeyCombo.self, from: data) as Magnet.KeyCombo?
        }

        public typealias Value = KeyCombo?

        public typealias Serializable = Data
    }
}
