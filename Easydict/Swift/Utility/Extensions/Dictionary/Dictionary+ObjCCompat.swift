//
//  Dictionary+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/25.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension NSDictionary {
    /// Returns a new dictionary with the keys and values inverted.
    ///
    /// Values become keys and keys become values. Returns `nil` if there are duplicate values
    /// which would cause key collisions.
    @objc(mm_reverseKeysAndObjectsDictionary)
    func inverted() -> NSDictionary? {
        let reversed = NSMutableDictionary()

        for (key, value) in self {
            // Check for duplicate values which would cause key collisions
            if reversed.object(forKey: value) != nil {
                return nil
            }
            reversed.setObject(key, forKey: value as! NSCopying)
        }

        // Ensure mapping is one-to-one
        if reversed.count == count {
            return reversed.copy() as? NSDictionary
        } else {
            return nil
        }
    }
}
