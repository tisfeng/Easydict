//
//  XPMMutableAttributedArray.h
//  ArgumentParser
//
//  Created by Christopher R. Miller on 5/15/12.
//  Copyright (c) 2012, 2016 Christopher R. Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A very fancy way of wrapping dictionaries in an array. This is a convenience class to make other code look more clear.
 *
 * Methods that have been commented out haven't been implemented.
 */
@interface XPMMutableAttributedArray : NSObject

#pragma mark Creating and Initializing a Mutable Attributed Array

+ (id)attributedArray;
+ (id)attributedArrayWithCapacity:(NSUInteger)capacity;

- (id)initWithCapacity:(NSUInteger)capacity;

#pragma mark Querying an Array

// - (bool)containsObject:(id)object;
- (NSUInteger)count;
// - (id)lastObject;
- (id)objectAtIndex:(NSUInteger)index;
// - (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;
// - (NSEnumerator *)objectEnumerator;
// - (NSEnumerator *)reverseObjectEnumerator;
- (NSMutableDictionary *)attributesOfObjectAtIndex:(NSUInteger)index;
- (bool)hasAttribute:(id)key forObjectAtIndex:(NSUInteger)index;
- (id)valueOfAttribute:(id)key forObjectAtIndex:(NSUInteger)index;
- (bool)booleanValueOfAttribute:(id)key forObjectAtIndex:(NSUInteger)index; // note that this returns false if the attribute isn't there

#pragma mark Finding Objects in an Array

// - (NSUInteger)indexOfObject:(id)object;
// - (NSUInteger)indexOfObject:(id)object inRange:(NSRange)range;
// - (NSUInteger)indexOfObjectIdenticalTo:(id)object;
// - (NSUInteger)indexOfObjectIdenticalTo:(id)object inRange:(NSRange)range;
// - (NSUInteger)indexOfObjectPassingTest:(bool (^)(id object, NSMutableDictionary * attributes, NSUInteger idx, bool * stop))predicate;
// - (NSUInteger)indexOfObjectWithOptions:(NSEnumerationOptions)opts passingTest:(bool (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, bool *stop))predicate;
- (NSUInteger)indexOfObjectAtIndexes:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(bool (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, BOOL *stop))predicate;
// - (NSIndexSet *)indexesOfObjectsPassingTest:(bool (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, bool *stop))predicate;
// - (NSIndexSet *)indexesOfObjectsWithOptions:(NSEnumerationOptions)opts passingTest:(bool (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, bool *stop))predicate;
// - (NSIndexSet *)indexesOfObjectsAtIndexes:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts passingTest:(bool (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, bool *stop))predicate;

#pragma mark Sending Messages to Elements

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, BOOL *stop))block;
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, BOOL *stop))block;
- (void)enumerateObjectsAtIndexes:(NSIndexSet *)indexSet options:(NSEnumerationOptions)opts usingBlock:(void (^)(id obj, NSMutableDictionary * attributes, NSUInteger idx, BOOL *stop))block;

#pragma mark Adding Objects

- (void)addObject:(id)object withAttributes:(NSDictionary *)attributes;
- (void)insertObject:(id)object withAttributes:(NSDictionary *)attributes atIndex:(NSUInteger)index;

#pragma mark Replacing Objects

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object attributes:(NSDictionary *)attributes;
- (void)setValue:(id)value ofAttribute:(id)key forObjectAtIndex:(NSUInteger)index;
- (void)setBooleanValue:(bool)value ofAttribute:(id)key forObjectAtIndex:(NSUInteger)index;

#pragma mark Removing Objects

- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeLastObject;

@end
