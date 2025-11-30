//
//  Array+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension NSArray {
    /// Maps each element using the provided block and returns a new array.
    ///
    /// - Parameter block: A block that transforms each element.
    /// - Returns: A new array with transformed elements.
    @objc(mm_map:)
    func mapElements(_ block: (Any, UInt, UnsafeMutablePointer<ObjCBool>) -> Any?) -> NSArray {
        let result = NSMutableArray()

        enumerateObjects { obj, idx, stop in
            if let newObj = block(obj, UInt(idx), stop) {
                result.add(newObj)
            }
        }

        return result
    }

    /// Filters elements using the provided block and returns a new array.
    ///
    /// - Parameter block: A block that determines whether to include an element.
    /// - Returns: A new array containing only the elements for which the block returns true.
    @objc(mm_where:)
    func filterElements(_ block: (Any, UInt, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSArray {
        let result = NSMutableArray()

        enumerateObjects { obj, idx, stop in
            if block(obj, UInt(idx), stop) {
                result.add(obj)
            }
        }

        return result
    }

    /// Finds the first element for which the block returns a non-nil value.
    ///
    /// - Parameter block: A block that processes each element.
    /// - Returns: The first non-nil result from the block, or nil if none found.
    @objc(mm_find:)
    func findFirst(_ block: (Any, UInt) -> Any?) -> Any? {
        var target: Any?

        enumerateObjects { obj, idx, stop in
            if let result = block(obj, UInt(idx)) {
                target = result
                stop.pointee = true
            }
        }

        return target
    }

    /// Combines arrays returned by the block into a single array.
    ///
    /// - Parameter block: A block that returns an array for each element.
    /// - Returns: A flattened array containing all elements from the returned arrays.
    @objc(mm_combine:)
    func combineElements(_ block: (Any, UInt, UnsafeMutablePointer<ObjCBool>) -> NSArray?) -> NSArray {
        let result = NSMutableArray()

        enumerateObjects { obj, idx, stop in
            if let array = block(obj, UInt(idx), stop), !array.isEmpty {
                result.addObjects(from: array as! [Any])
            }
        }

        return result
    }

    /// Creates a dictionary mapping objects to their indices in the array.
    ///
    /// - Returns: A dictionary where keys are array elements and values are their indices.
    @objc(mm_objectToIndexDictionary)
    func indexDictionary() -> NSDictionary {
        let result = NSMutableDictionary(capacity: count)

        enumerateObjects { obj, idx, _ in
            // Ensure elements are unique and can be used as dictionary keys
            if let key = obj as? NSCopying {
                result[key] = UInt(idx)
            }
        }

        return result
    }
}

extension NSArray {
    var isEmpty: Bool {
        count > 0
    }
}
