//
//  MMOrderedDictionary.h
//  Debugo
//
//  GitHub https://github.com/ripperhe/Debugo
//  Created by ripper on 2018/9/1.
//  Copyright © 2018年 ripper. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An ordered dictionary.
 
 Inspired by http://www.cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html
 */

@interface MMOrderedDictionary<__covariant KeyType, __covariant ObjectType> : NSObject<NSMutableCopying>

/// 如果更新某个已经存在的Key的值，将其下标移动到最后; 默认为 NO
@property (nonatomic, assign) BOOL moveToLastWhenUpdateValue;

+ (instancetype)dictionary;
+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems;
- (instancetype)init;
- (instancetype)initWithCapacity:(NSUInteger)numItems;
/// key 和 value 必须一一对应，nil 结尾，形如key, value, key2, value2, nil
- (instancetype)initWithKeysAndObjects:(id)firstKey,...;
/// sortedKeys 数组的 key 值必须和 keysAndObjects 的 key 值一一对应
- (instancetype)initWithSortedKeys:(NSArray <KeyType>*)sortedKeys keysAndObjects:(NSDictionary <KeyType, ObjectType>*)keysAndObjects;

- (void)setObject:(ObjectType)anObject forKey:(KeyType)aKey;
- (void)setObject:(ObjectType)anObject atIndex:(NSUInteger)anIndex;
- (void)insertObject:(ObjectType)anObject forKey:(KeyType)aKey atIndex:(NSUInteger)anIndex;

- (void)removeObjectForKey:(KeyType)aKey;
- (void)removeObjectAtIndex:(NSUInteger)anIndex;
- (void)removeAllObjects;

- (NSUInteger)count;

- (NSDictionary <KeyType, ObjectType>*)keysAndObjects;

- (KeyType)keyAtIndex:(NSUInteger)anIndex;

- (ObjectType)objectForKey:(KeyType)aKey;
- (ObjectType)objectAtIndex:(NSUInteger)anIndex;

- (NSArray <KeyType>*)allKeys;
- (NSArray <ObjectType>*)allValues;

- (NSArray <KeyType>*)sortedKeys;
- (NSArray <KeyType>*)reverseSortedKeys;

- (NSArray <ObjectType>*)sortedValues;
- (NSArray <ObjectType>*)reverseSortedValues;

- (NSEnumerator <ObjectType>*)keyEnumerator;
- (NSEnumerator <ObjectType>*)reverseKeyEnumerator;

- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(KeyType key, ObjectType obj, NSUInteger idx, BOOL *stop))block;
- (void)reverseEnumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(KeyType key, ObjectType obj, NSUInteger idx, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
