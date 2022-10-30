//
//  RACTuple.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 4/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RACmetamacros.h"

@class RACSequence;

/// Creates a new tuple with the given values. At least one value must be given.
/// Values can be nil.
#define RACTuplePack(...) \
    RACTuplePack_(__VA_ARGS__)

/// Declares new object variables and unpacks a RACTuple into them.
///
/// This macro should be used on the left side of an assignment, with the
/// tuple on the right side. Nothing else should appear on the same line, and the
/// macro should not be the only statement in a conditional or loop body.
///
/// If the tuple has more values than there are variables listed, the excess
/// values are ignored.
///
/// If the tuple has fewer values than there are variables listed, the excess
/// variables are initialized to nil.
///
/// Examples
///
///   RACTupleUnpack(NSString *string, NSNumber *num) = [RACTuple tupleWithObjects:@"foo", @5, nil];
///   NSLog(@"string: %@", string);
///   NSLog(@"num: %@", num);
///
///   /* The above is equivalent to: */
///   RACTuple *t = [RACTuple tupleWithObjects:@"foo", @5, nil];
///   NSString *string = t[0];
///   NSNumber *num = t[1];
///   NSLog(@"string: %@", string);
///   NSLog(@"num: %@", num);
#define RACTupleUnpack(...) \
        RACTupleUnpack_(__VA_ARGS__)

@class RACTwoTuple<__covariant First, __covariant Second>;
@class RACThreeTuple<__covariant First, __covariant Second, __covariant Third>;
@class RACFourTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth>;
@class RACFiveTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth, __covariant Fifth>;

NS_ASSUME_NONNULL_BEGIN

/// A sentinel object that represents nils in the tuple.
///
/// It should never be necessary to create a tuple nil yourself. Just use
/// +tupleNil.
@interface RACTupleNil : NSObject <NSCopying, NSCoding>
/// A singleton instance.
+ (RACTupleNil *)tupleNil;
@end


/// A tuple is an ordered collection of objects. It may contain nils, represented
/// by RACTupleNil.
@interface RACTuple : NSObject <NSCoding, NSCopying, NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger count;

/// These properties all return the object at that index or nil if the number of 
/// objects is less than the index.
@property (nonatomic, readonly, nullable) id first;
@property (nonatomic, readonly, nullable) id second;
@property (nonatomic, readonly, nullable) id third;
@property (nonatomic, readonly, nullable) id fourth;
@property (nonatomic, readonly, nullable) id fifth;
@property (nonatomic, readonly, nullable) id last;

/// Creates a new tuple out of the array. Does not convert nulls to nils.
+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array;

/// Creates a new tuple out of the array. If `convert` is YES, it also converts
/// every NSNull to RACTupleNil.
+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array convertNullsToNils:(BOOL)convert;

/// Creates a new tuple with the given objects. Use RACTupleNil to represent
/// nils.
+ (instancetype)tupleWithObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

/// Returns the object at `index` or nil if the object is a RACTupleNil. Unlike
/// NSArray and friends, it's perfectly fine to ask for the object at an index
/// past the tuple's count - 1. It will simply return nil.
- (nullable id)objectAtIndex:(NSUInteger)index;

/// Returns an array of all the objects. RACTupleNils are converted to NSNulls.
- (NSArray *)allObjects;

/// Appends `obj` to the receiver.
///
/// obj - The object to add to the tuple. This argument may be nil.
///
/// Returns a new tuple.
- (__kindof RACTuple *)tupleByAddingObject:(nullable id)obj;

@end

@interface RACTuple (RACSequenceAdditions)

/// Returns a sequence of all the objects. RACTupleNils are converted to NSNulls.
@property (nonatomic, copy, readonly) RACSequence *rac_sequence;

@end

@interface RACTuple (ObjectSubscripting)
/// Returns the object at that index or nil if the number of objects is less
/// than the index.
- (nullable id)objectAtIndexedSubscript:(NSUInteger)idx;
@end

/// A tuple with exactly one generic value.
@interface RACOneTuple<__covariant First> : RACTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack: instead.")));

- (RACTwoTuple<First, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given values.
+ (RACOneTuple<First> *)pack:(nullable First)first;

@property (nonatomic, readonly, nullable) First first;

@end

/// A tuple with exactly two generic values.
@interface RACTwoTuple<__covariant First, __covariant Second> : RACTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack:: instead.")));

- (RACThreeTuple<First, Second, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given value.
+ (RACTwoTuple<First, Second> *)pack:(nullable First)first :(nullable Second)second;

@property (nonatomic, readonly, nullable) First first;
@property (nonatomic, readonly, nullable) Second second;

@end

/// A tuple with exactly three generic values.
@interface RACThreeTuple<__covariant First, __covariant Second, __covariant Third> : RACTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack::: instead.")));

- (RACFourTuple<First, Second, Third, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given values.
+ (instancetype)pack:(nullable First)first :(nullable Second)second :(nullable Third)third;

@property (nonatomic, readonly, nullable) First first;
@property (nonatomic, readonly, nullable) Second second;
@property (nonatomic, readonly, nullable) Third third;

@end

/// A tuple with exactly four generic values.
@interface RACFourTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth> : RACTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack:::: instead.")));

- (RACFiveTuple<First, Second, Third, Fourth, id> *)tupleByAddingObject:(nullable id)obj;

/// Creates a new tuple with the given values.
+ (instancetype)pack:(nullable First)first :(nullable Second)second :(nullable Third)third :(nullable Fourth)fourth;

@property (nonatomic, readonly, nullable) First first;
@property (nonatomic, readonly, nullable) Second second;
@property (nonatomic, readonly, nullable) Third third;
@property (nonatomic, readonly, nullable) Fourth fourth;

@end

/// A tuple with exactly five generic values.
@interface RACFiveTuple<__covariant First, __covariant Second, __covariant Third, __covariant Fourth, __covariant Fifth> : RACTuple

+ (instancetype)tupleWithObjects:(id)object, ... __attribute((unavailable("Use pack::::: instead.")));

/// Creates a new tuple with the given values.
+ (instancetype)pack:(nullable First)first :(nullable Second)second :(nullable Third)third :(nullable Fourth)fourth :(nullable Fifth)fifth;

@property (nonatomic, readonly, nullable) First first;
@property (nonatomic, readonly, nullable) Second second;
@property (nonatomic, readonly, nullable) Third third;
@property (nonatomic, readonly, nullable) Fourth fourth;
@property (nonatomic, readonly, nullable) Fifth fifth;

@end

/// This and everything below is for internal use only.
///
/// See RACTuplePack() and RACTupleUnpack() instead.
#define RACTuplePack_(...) \
    ([RACTuplePack_class_name(__VA_ARGS__) tupleWithObjectsFromArray:@[ metamacro_foreach(RACTuplePack_object_or_ractuplenil,, __VA_ARGS__) ]])

#define RACTuplePack_object_or_ractuplenil(INDEX, ARG) \
    (ARG) ?: RACTupleNil.tupleNil,

/// Returns the class that should be used to create a tuple with the provided
/// variadic arguments to RACTuplePack_(). Supports up to 20 arguments.
#define RACTuplePack_class_name(...) \
        metamacro_at(20, __VA_ARGS__, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACTuple, RACFiveTuple, RACFourTuple, RACThreeTuple, RACTwoTuple, RACOneTuple)

#define RACTupleUnpack_(...) \
    metamacro_foreach(RACTupleUnpack_decl,, __VA_ARGS__) \
    \
    int RACTupleUnpack_state = 0; \
    \
    RACTupleUnpack_after: \
        ; \
        metamacro_foreach(RACTupleUnpack_assign,, __VA_ARGS__) \
        if (RACTupleUnpack_state != 0) RACTupleUnpack_state = 2; \
        \
        while (RACTupleUnpack_state != 2) \
            if (RACTupleUnpack_state == 1) { \
                goto RACTupleUnpack_after; \
            } else \
                for (; RACTupleUnpack_state != 1; RACTupleUnpack_state = 1) \
                    [RACTupleUnpackingTrampoline trampoline][ @[ metamacro_foreach(RACTupleUnpack_value,, __VA_ARGS__) ] ]

#define RACTupleUnpack_state metamacro_concat(RACTupleUnpack_state, __LINE__)
#define RACTupleUnpack_after metamacro_concat(RACTupleUnpack_after, __LINE__)
#define RACTupleUnpack_loop metamacro_concat(RACTupleUnpack_loop, __LINE__)

#define RACTupleUnpack_decl_name(INDEX) \
    metamacro_concat(metamacro_concat(RACTupleUnpack, __LINE__), metamacro_concat(_var, INDEX))

#define RACTupleUnpack_decl(INDEX, ARG) \
    __strong id RACTupleUnpack_decl_name(INDEX);

#define RACTupleUnpack_assign(INDEX, ARG) \
    __strong ARG = RACTupleUnpack_decl_name(INDEX);

#define RACTupleUnpack_value(INDEX, ARG) \
    [NSValue valueWithPointer:&RACTupleUnpack_decl_name(INDEX)],

@interface RACTupleUnpackingTrampoline : NSObject

+ (instancetype)trampoline;
- (void)setObject:(nullable RACTuple *)tuple forKeyedSubscript:(NSArray *)variables;

@end

NS_ASSUME_NONNULL_END
