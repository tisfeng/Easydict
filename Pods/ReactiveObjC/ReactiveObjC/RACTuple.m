//
//  RACTuple.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 4/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACTuple.h"
#import <ReactiveObjC/RACEXTKeyPathCoding.h>
#import "RACTupleSequence.h"

@implementation RACTupleNil

+ (RACTupleNil *)tupleNil {
	static dispatch_once_t onceToken;
	static RACTupleNil *tupleNil = nil;
	dispatch_once(&onceToken, ^{
		tupleNil = [[self alloc] init];
	});
	
	return tupleNil;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
	// Always return the singleton.
	return self.class.tupleNil;
}

- (void)encodeWithCoder:(NSCoder *)coder {
}

@end


@interface RACTuple ()

- (instancetype)initWithBackingArray:(NSArray *)backingArray NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSArray *backingArray;

@end


@implementation RACTuple

- (instancetype)init {
	return [self initWithBackingArray:@[]];
}

- (instancetype)initWithBackingArray:(NSArray *)backingArray {
	self = [super init];
	
	_backingArray = [backingArray copy];
	
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, self.allObjects];
}

- (BOOL)isEqual:(RACTuple *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:self.class]) return NO;
	
	return [self.backingArray isEqual:object.backingArray];
}

- (NSUInteger)hash {
	return self.backingArray.hash;
}

#pragma mark NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
	return [self.backingArray countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	// we're immutable, bitches!
	return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [self init];
	
	_backingArray = [coder decodeObjectForKey:@keypath(self.backingArray)];

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	if (self.backingArray != nil) [coder encodeObject:self.backingArray forKey:@keypath(self.backingArray)];
}

#pragma mark API

+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array {
	return [self tupleWithObjectsFromArray:array convertNullsToNils:NO];
}

+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array convertNullsToNils:(BOOL)convert {
	if (!convert) {
		return [[self alloc] initWithBackingArray:array];
	}

	NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
	for (id object in array) {
		[newArray addObject:(object == NSNull.null ? RACTupleNil.tupleNil : object)];
	}

	return [[self alloc] initWithBackingArray:newArray];
}

+ (instancetype)tupleWithObjects:(id)object, ... {
	va_list args;
	va_start(args, object);

	NSUInteger count = 0;
	for (id currentObject = object; currentObject != nil; currentObject = va_arg(args, id)) {
		++count;
	}

	va_end(args);

	if (count == 0) {
		return [[self alloc] init];
	}
	
	NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:count];
	
	va_start(args, object);
	for (id currentObject = object; currentObject != nil; currentObject = va_arg(args, id)) {
		[objects addObject:currentObject];
	}

	va_end(args);

	return [[self alloc] initWithBackingArray:objects];
}

- (id)objectAtIndex:(NSUInteger)index {
	if (index >= self.count) return nil;
	
	id object = self.backingArray[index];
	return (object == RACTupleNil.tupleNil ? nil : object);
}

- (NSArray *)allObjects {
	NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:self.backingArray.count];
	for (id object in self.backingArray) {
		[newArray addObject:(object == RACTupleNil.tupleNil ? NSNull.null : object)];
	}
	
	return newArray;
}

- (instancetype)tupleByAddingObject:(id)obj {
	NSArray *newArray = [self.backingArray arrayByAddingObject:obj ?: RACTupleNil.tupleNil];
	return [self.class tupleWithObjectsFromArray:newArray];
}

- (NSUInteger)count {
	return self.backingArray.count;
}

- (id)first {
	return self[0];
}

- (id)second {
	return self[1];
}

- (id)third {
	return self[2];
}

- (id)fourth {
	return self[3];
}

- (id)fifth {
	return self[4];
}

- (id)last {
	return self[self.count - 1];
}

@end


@implementation RACTuple (RACSequenceAdditions)

- (RACSequence *)rac_sequence {
	return [RACTupleSequence sequenceWithTupleBackingArray:self.backingArray offset:0];
}

@end

@implementation RACTuple (ObjectSubscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
	return [self objectAtIndex:idx];
}

@end

@implementation RACOneTuple

- (instancetype)init {
	return [self initWithBackingArray:@[ RACTupleNil.tupleNil ]];
}

- (instancetype)initWithBackingArray:(NSArray *)backingArray {
	NSParameterAssert(backingArray.count == 1);
	return [super initWithBackingArray:backingArray];
}

- (RACTwoTuple *)tupleByAddingObject:(id)obj {
	NSArray *newArray = [self.backingArray arrayByAddingObject:obj ?: RACTupleNil.tupleNil];
	return [RACTwoTuple tupleWithObjectsFromArray:newArray];
}

+ (instancetype)pack:(id)first {
	return [self tupleWithObjectsFromArray:@[
		first ?: RACTupleNil.tupleNil,
	]];
}

- (BOOL)isEqual:(RACTuple *)object {
	if (object == self) return YES;

	// We consider a RACTuple with an identical backing array as equal.
	if (![object isKindOfClass:RACTuple.class]) return NO;
	
	return [self.backingArray isEqual:object.backingArray];
}

@dynamic first;

@end

@implementation RACTwoTuple

- (instancetype)init {
	return [self initWithBackingArray:@[ RACTupleNil.tupleNil, RACTupleNil.tupleNil ]];
}

- (instancetype)initWithBackingArray:(NSArray *)backingArray {
	NSParameterAssert(backingArray.count == 2);
	return [super initWithBackingArray:backingArray];
}

- (RACThreeTuple *)tupleByAddingObject:(id)obj {
	NSArray *newArray = [self.backingArray arrayByAddingObject:obj ?: RACTupleNil.tupleNil];
	return [RACThreeTuple tupleWithObjectsFromArray:newArray];
}

+ (instancetype)pack:(id)first :(id)second {
	return [self tupleWithObjectsFromArray:@[
		first ?: RACTupleNil.tupleNil,
		second ?: RACTupleNil.tupleNil,
	]];
}

- (BOOL)isEqual:(RACTuple *)object {
	if (object == self) return YES;

	// We consider a RACTuple with an identical backing array as equal.
	if (![object isKindOfClass:RACTuple.class]) return NO;
	
	return [self.backingArray isEqual:object.backingArray];
}

@dynamic first;
@dynamic second;

@end

@implementation RACThreeTuple

- (instancetype)init {
	return [super initWithBackingArray:@[ RACTupleNil.tupleNil, RACTupleNil.tupleNil, RACTupleNil.tupleNil ]];
}

- (instancetype)initWithBackingArray:(NSArray *)backingArray {
	NSParameterAssert(backingArray.count == 3);
	return [super initWithBackingArray:backingArray];
}

- (RACFourTuple *)tupleByAddingObject:(id)obj {
	NSArray *newArray = [self.backingArray arrayByAddingObject:obj ?: RACTupleNil.tupleNil];
	return [RACFourTuple tupleWithObjectsFromArray:newArray];
}

+ (instancetype)pack:(id)first :(id)second :(id)third {
	return [self tupleWithObjectsFromArray:@[
		first ?: RACTupleNil.tupleNil,
		second ?: RACTupleNil.tupleNil,
		third ?: RACTupleNil.tupleNil,
	]];
}

- (BOOL)isEqual:(RACTuple *)object {
	if (object == self) return YES;

	// We consider a RACTuple with an identical backing array as equal.
	if (![object isKindOfClass:RACTuple.class]) return NO;
	
	return [self.backingArray isEqual:object.backingArray];
}

@dynamic first;
@dynamic second;
@dynamic third;

@end

@implementation RACFourTuple

- (instancetype)init {
	return [self initWithBackingArray:@[ RACTupleNil.tupleNil, RACTupleNil.tupleNil, RACTupleNil.tupleNil, RACTupleNil.tupleNil ]];
}

- (instancetype)initWithBackingArray:(NSArray *)backingArray {
	NSParameterAssert(backingArray.count == 4);
	return [super initWithBackingArray:backingArray];
}

- (RACFiveTuple *)tupleByAddingObject:(id)obj {
	NSArray *newArray = [self.backingArray arrayByAddingObject:obj ?: RACTupleNil.tupleNil];
	return [RACFiveTuple tupleWithObjectsFromArray:newArray];
}

+ (instancetype)pack:(id)first :(id)second :(id)third :(id)fourth {
	return [self tupleWithObjectsFromArray:@[
		first ?: RACTupleNil.tupleNil,
		second ?: RACTupleNil.tupleNil,
		third ?: RACTupleNil.tupleNil,
		fourth ?: RACTupleNil.tupleNil,
	]];
}

- (BOOL)isEqual:(RACTuple *)object {
	if (object == self) return YES;

	// We consider a RACTuple with an identical backing array as equal.
	if (![object isKindOfClass:RACTuple.class]) return NO;
	
	return [self.backingArray isEqual:object.backingArray];
}

@dynamic first;
@dynamic second;
@dynamic third;
@dynamic fourth;

@end

@implementation RACFiveTuple

- (instancetype)init {
	return [self initWithBackingArray:@[ RACTupleNil.tupleNil, RACTupleNil.tupleNil, RACTupleNil.tupleNil, RACTupleNil.tupleNil, RACTupleNil.tupleNil ]];
}

- (instancetype)initWithBackingArray:(NSArray *)backingArray {
	NSParameterAssert(backingArray.count == 5);
	return [super initWithBackingArray:backingArray];
}

+ (instancetype)pack:(id)first :(id)second :(id)third :(id)fourth :(id)fifth {
	return [self tupleWithObjectsFromArray:@[
		first ?: RACTupleNil.tupleNil,
		second ?: RACTupleNil.tupleNil,
		third ?: RACTupleNil.tupleNil,
		fourth ?: RACTupleNil.tupleNil,
		fifth ?: RACTupleNil.tupleNil,
	]];
}

- (BOOL)isEqual:(RACTuple *)object {
	if (object == self) return YES;

	// We consider a RACTuple with an identical backing array as equal.
	if (![object isKindOfClass:RACTuple.class]) return NO;
	
	return [self.backingArray isEqual:object.backingArray];
}

@dynamic first;
@dynamic second;
@dynamic third;
@dynamic fourth;
@dynamic fifth;

@end

@implementation RACTupleUnpackingTrampoline

#pragma mark Lifecycle

+ (instancetype)trampoline {
	static dispatch_once_t onceToken;
	static id trampoline = nil;
	dispatch_once(&onceToken, ^{
		trampoline = [[self alloc] init];
	});
	
	return trampoline;
}

- (void)setObject:(RACTuple *)tuple forKeyedSubscript:(NSArray *)variables {
	NSCParameterAssert(variables != nil);
	
	[variables enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger index, BOOL *stop) {
		__strong id *ptr = (__strong id *)value.pointerValue;
		*ptr = tuple[index];
	}];
}

@end
