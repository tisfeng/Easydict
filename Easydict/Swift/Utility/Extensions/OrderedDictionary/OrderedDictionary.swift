//
//  OrderedDictionary.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/// An ordered dictionary that maintains the insertion order of keys.
///
/// Inspired by http://www.cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html
@objc
public class MMOrderedDictionary: NSObject, NSMutableCopying {
    // MARK: Lifecycle

    // MARK: - Initialization

    @objc
    public required override init() {
        self.internalDictionary = NSMutableDictionary()
        self.internalArray = NSMutableArray()
        super.init()
    }

    @objc(initWithCapacity:)
    public init(capacity: Int) {
        self.internalDictionary = NSMutableDictionary(capacity: capacity)
        self.internalArray = NSMutableArray(capacity: capacity)
        super.init()
    }

    @objc(initWithSortedKeys:keysAndObjects:)
    public init(sortedKeys: NSArray, keysAndObjects: NSDictionary) {
        assert(
            sortedKeys.count == keysAndObjects.count,
            "OrderedDictionary: sortedKeys must match keysAndObjects keys"
        )
        self.internalDictionary = NSMutableDictionary(dictionary: keysAndObjects)
        self.internalArray = NSMutableArray(array: sortedKeys as! [Any])
        super.init()
    }

    // MARK: Public

    // MARK: - Description

    public override var description: String {
        description(withLocale: nil)
    }

    /// If true, updating an existing key moves it to the end; defaults to false
    @objc public var moveToLastWhenUpdateValue: Bool = false

    // MARK: - Access

    @objc public var count: Int {
        internalArray.count
    }

    public override func copy() -> Any {
        let reason = "-[\(type(of: self)) copy] not supported, please use mutableCopy!"
        NSException(
            name: NSExceptionName.internalInconsistencyException,
            reason: reason,
            userInfo: nil
        ).raise()
        fatalError(reason)
    }

    @objc(dictionary)
    public static func dictionary() -> Self {
        self.init()
    }

    @objc(dictionaryWithCapacity:)
    public static func dictionary(withCapacity capacity: Int) -> MMOrderedDictionary {
        MMOrderedDictionary(capacity: capacity)
    }

    // MARK: - NSMutableCopying

    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copy = type(of: self).init()
        copy.internalDictionary = internalDictionary.mutableCopy() as! NSMutableDictionary
        copy.internalArray = internalArray.mutableCopy() as! NSMutableArray
        copy.moveToLastWhenUpdateValue = moveToLastWhenUpdateValue
        return copy
    }

    // MARK: - Set/Insert

    @objc(setObject:forKey:)
    public func setObject(_ object: Any, forKey key: Any) {
        assert(internalArray.count == internalDictionary.count, "OrderedDictionary: internal inconsistency")

        if internalDictionary.object(forKey: key) == nil {
            internalArray.add(key)
        } else if moveToLastWhenUpdateValue {
            internalArray.remove(key)
            internalArray.add(key)
        }

        internalDictionary.setObject(object, forKey: key as! any NSCopying)
    }

    @objc(setObject:atIndex:)
    public func setObject(_ object: Any, at index: Int) {
        assert(internalArray.count == internalDictionary.count, "OrderedDictionary: internal inconsistency")
        let key = internalArray.object(at: index)
        internalDictionary.setObject(object, forKey: key as! any NSCopying)
    }

    @objc(insertObject:forKey:atIndex:)
    public func insertObject(_ object: Any, forKey key: Any, at index: Int) {
        assert(internalArray.count == internalDictionary.count, "OrderedDictionary: internal inconsistency")

        if internalDictionary.object(forKey: key) != nil {
            removeObject(forKey: key)
        }

        internalArray.insert(key, at: index)
        internalDictionary.setObject(object, forKey: key as! any NSCopying)
    }

    // MARK: - Remove

    @objc(removeObjectForKey:)
    public func removeObject(forKey key: Any) {
        internalArray.remove(key)
        internalDictionary.removeObject(forKey: key)
    }

    @objc(removeObjectAtIndex:)
    public func removeObject(at index: Int) {
        let key = internalArray.object(at: index)
        internalArray.removeObject(at: index)
        internalDictionary.removeObject(forKey: key)
    }

    @objc
    public func removeAllObjects() {
        internalArray.removeAllObjects()
        internalDictionary.removeAllObjects()
    }

    @objc
    public func keysAndObjects() -> NSDictionary {
        internalDictionary.copy() as! NSDictionary
    }

    @objc(keyAtIndex:)
    public func key(at index: Int) -> Any {
        internalArray.object(at: index)
    }

    @objc(objectForKey:)
    public func object(forKey key: Any) -> Any? {
        internalDictionary.object(forKey: key)
    }

    @objc(objectAtIndex:)
    public func object(at index: Int) -> Any {
        let key = key(at: index)
        return internalDictionary.object(forKey: key)!
    }

    @objc
    public func allKeys() -> [Any] {
        internalDictionary.allKeys
    }

    @objc
    public func allValues() -> [Any] {
        internalDictionary.allValues
    }

    @objc
    public func sortedKeys() -> NSArray {
        internalArray.copy() as! NSArray
    }

    @objc
    public func reverseSortedKeys() -> NSArray {
        let reverseKeys = NSMutableArray()
        internalArray.enumerateObjects(options: .reverse) { obj, _, _ in
            reverseKeys.add(obj)
        }
        return reverseKeys
    }

    @objc
    public func sortedValues() -> NSArray {
        let values = NSMutableArray()
        for key in internalArray {
            if let value = internalDictionary.object(forKey: key) {
                values.add(value)
            }
        }
        return values
    }

    @objc
    public func reverseSortedValues() -> NSArray {
        let reverseValues = NSMutableArray()
        internalArray.enumerateObjects(options: .reverse) { obj, _, _ in
            if let value = self.internalDictionary.object(forKey: obj) {
                reverseValues.add(value)
            }
        }
        return reverseValues
    }

    // MARK: - Enumeration

    @objc
    public func keyEnumerator() -> NSEnumerator {
        internalArray.objectEnumerator()
    }

    @objc
    public func reverseKeyEnumerator() -> NSEnumerator {
        internalArray.reverseObjectEnumerator()
    }

    @objc(enumerateKeysAndObjectsUsingBlock:)
    public func enumerateKeysAndObjects(
        using block: @escaping (Any, Any, UInt, UnsafeMutablePointer<ObjCBool>) -> ()
    ) {
        internalArray.enumerateObjects { obj, idx, stop in
            if let value = self.internalDictionary.object(forKey: obj) {
                block(obj, value, UInt(idx), stop)
            }
        }
    }

    @objc(reverseEnumerateKeysAndObjectsUsingBlock:)
    public func reverseEnumerateKeysAndObjects(
        using block: @escaping (Any, Any, UInt, UnsafeMutablePointer<ObjCBool>) -> ()
    ) {
        internalArray.enumerateObjects(options: .reverse) { obj, idx, stop in
            if let value = self.internalDictionary.object(forKey: obj) {
                block(obj, value, UInt(idx), stop)
            }
        }
    }

    @objc(descriptionWithLocale:)
    public func description(withLocale locale: Any?) -> String {
        description(withLocale: locale, indent: 0)
    }

    @objc(descriptionWithLocale:indent:)
    public func description(withLocale locale: Any?, indent level: Int) -> String {
        let indentString = String(repeating: "\t", count: level)
        var description = "\(indentString){\n"

        internalArray.enumerateObjects { obj, idx, _ in
            if let value = self.internalDictionary.object(forKey: obj) {
                let keyDesc = self.descriptionForObject(obj as AnyObject, locale: locale, indent: level + 1)
                let valueDesc = self.descriptionForObject(value as AnyObject, locale: locale, indent: level + 1)
                description += "\(indentString)\t[\(idx)] \(keyDesc) = \(valueDesc);\n"
            }
        }

        description += "\(indentString)}"
        return description
    }

    // MARK: Private

    /// Internal storage for key-value pairs
    private var internalDictionary: NSMutableDictionary

    /// Internal storage for ordered keys
    private var internalArray: NSMutableArray

    private func descriptionForObject(_ object: AnyObject, locale: Any?, indent: Int) -> String {
        if let string = object as? String {
            return string
        } else if let orderedDict = object as? MMOrderedDictionary {
            return orderedDict.description(withLocale: locale, indent: indent)
        } else if let dict = object as? NSDictionary,
                  dict.responds(to: #selector(NSDictionary.description(withLocale:indent:))) {
            return dict.description(withLocale: locale, indent: indent)
        } else if let set = object as? NSSet,
                  set.responds(to: #selector(NSSet.description(withLocale:))) {
            return set.description(withLocale: locale)
        } else {
            return object.description
        }
    }
}
