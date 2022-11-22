/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

/**
 This macro ensures that key path exists at compile time.
 Given a real receiver with a key path as you would call it, it verifies at compile time that the key path exists, without calling it.

 For example:

 FBKVOKeyPath(string.length) => @"length"

 Or even the complex case:

 FBKVOKeyPath(string.lowercaseString.length) => @"lowercaseString.length".
 */
#define FBKVOKeyPath(KEYPATH) \
@(((void)(NO && ((void)KEYPATH, NO)), \
({ const char *fbkvokeypath = strchr(#KEYPATH, '.'); NSCAssert(fbkvokeypath, @"Provided key path is invalid."); fbkvokeypath + 1; })))

/**
 This macro ensures that key path exists at compile time.
 Given a receiver type and a key path, it verifies at compile time that the key path exists, without calling it.

 For example:

 FBKVOClassKeyPath(NSString, length) => @"length"
 FBKVOClassKeyPath(NSString, lowercaseString.length) => @"lowercaseString.length"
 */
#define FBKVOClassKeyPath(CLASS, KEYPATH) \
@(((void)(NO && ((void)((CLASS *)(nil)).KEYPATH, NO)), #KEYPATH))

NS_ASSUME_NONNULL_BEGIN

/**
 Key provided in the @c change dictionary of @c FBKVONotificationBlock that's value represents the key-path being observed
 */
extern NSString *const FBKVONotificationKeyPathKey;

/**
 @abstract Block called on key-value change notification.
 @param observer The observer of the change.
 @param object The object changed.
 @param change The change dictionary which also includes @c FBKVONotificationKeyPathKey
 */
typedef void (^FBKVONotificationBlock)(id _Nullable observer, id object, NSDictionary<NSString *, id> *change);

/**
 @abstract FBKVOController makes Key-Value Observing simpler and safer.
 @discussion FBKVOController adds support for handling key-value changes with blocks and custom actions, as well as the NSKeyValueObserving callback. Notification will never message a deallocated observer. Observer removal never throws exceptions, and observers are removed implicitly on controller deallocation. FBKVOController is also thread safe. When used in a concurrent environment, it protects observers from possible resurrection and avoids ensuing crash. By default, the controller maintains a strong reference to objects observed.
 */
@interface FBKVOController : NSObject

///--------------------------------------
#pragma mark - Initialize
///--------------------------------------

/**
 @abstract Creates and returns an initialized KVO controller instance.
 @param observer The object notified on key-value change.
 @return The initialized KVO controller instance.
 */
+ (instancetype)controllerWithObserver:(nullable id)observer;

/**
 @abstract The designated initializer.
 @param observer The object notified on key-value change. The specified observer must support weak references.
 @param retainObserved Flag indicating whether observed objects should be retained.
 @return The initialized KVO controller instance.
 @discussion Use retainObserved = NO when a strong reference between controller and observee would create a retain loop. When not retaining observees, special care must be taken to remove observation info prior to observee dealloc.
 */
- (instancetype)initWithObserver:(nullable id)observer retainObserved:(BOOL)retainObserved NS_DESIGNATED_INITIALIZER;

/**
 @abstract Convenience initializer.
 @param observer The object notified on key-value change. The specified observer must support weak references.
 @return The initialized KVO controller instance.
 @discussion By default, KVO controller retains objects observed.
 */
- (instancetype)initWithObserver:(nullable id)observer;

/**
 @abstract Initializes a new instance.

 @warning This method is unavaialble. Please use `initWithObserver:` instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 @abstract Allocates memory and initializes a new instance into it.

 @warning This method is unavaialble. Please use `controllerWithObserver:` instead.
 */
+ (instancetype)new NS_UNAVAILABLE;

///--------------------------------------
#pragma mark - Observe
///--------------------------------------

/**
 The observer notified on key-value change. Specified on initialization.
 */
@property (nullable, nonatomic, weak, readonly) id observer;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPath The key path to observe.
 @param options The NSKeyValueObservingOptions to use for observation.
 @param block The block to execute on notification.
 @discussion On key-value change, the specified block is called. In order to avoid retain loops, the block must avoid referencing the KVO controller or an owner thereof. Observing an already observed object key path or nil results in no operation.
 */
- (void)observe:(nullable id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(FBKVONotificationBlock)block;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPath The key path to observe.
 @param options The NSKeyValueObservingOptions to use for observation.
 @param action The observer selector called on key-value change.
 @discussion On key-value change, the observer's action selector is called. The selector provided should take the form of -propertyDidChange, -propertyDidChange: or -propertyDidChange:object:, where optional parameters delivered will be KVO change dictionary and object observed. Observing nil or observing an already observed object's key path results in no operation.
 */
- (void)observe:(nullable id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options action:(SEL)action;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPath The key path to observe.
 @param options The NSKeyValueObservingOptions to use for observation.
 @param context The context specified.
 @discussion On key-value change, the observer's -observeValueForKeyPath:ofObject:change:context: method is called. Observing an already observed object key path or nil results in no operation.
 */
- (void)observe:(nullable id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;


/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPaths The key paths to observe.
 @param options The NSKeyValueObservingOptions to use for observation.
 @param block The block to execute on notification.
 @discussion On key-value change, the specified block is called. Inorder to avoid retain loops, the block must avoid referencing the KVO controller or an owner thereof. Observing an already observed object key path or nil results in no operation.
 */
- (void)observe:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options block:(FBKVONotificationBlock)block;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPaths The key paths to observe.
 @param options The NSKeyValueObservingOptions to use for observation.
 @param action The observer selector called on key-value change.
 @discussion On key-value change, the observer's action selector is called. The selector provided should take the form of -propertyDidChange, -propertyDidChange: or -propertyDidChange:object:, where optional parameters delivered will be KVO change dictionary and object observed. Observing nil or observing an already observed object's key path results in no operation.
 */
- (void)observe:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options action:(SEL)action;

/**
 @abstract Registers observer for key-value change notification.
 @param object The object to observe.
 @param keyPaths The key paths to observe.
 @param options The NSKeyValueObservingOptions to use for observation.
 @param context The context specified.
 @discussion On key-value change, the observer's -observeValueForKeyPath:ofObject:change:context: method is called. Observing an already observed object key path or nil results in no operation.
 */
- (void)observe:(nullable id)object keyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options context:(nullable void *)context;

///--------------------------------------
#pragma mark - Unobserve
///--------------------------------------

/**
 @abstract Unobserve object key path.
 @param object The object to unobserve.
 @param keyPath The key path to observe.
 @discussion If not observing object key path, or unobserving nil, this method results in no operation.
 */
- (void)unobserve:(nullable id)object keyPath:(NSString *)keyPath;

/**
 @abstract Unobserve all object key paths.
 @param object The object to unobserve.
 @discussion If not observing object, or unobserving nil, this method results in no operation.
 */
- (void)unobserve:(nullable id)object;

/**
 @abstract Unobserve all objects.
 @discussion If not observing any objects, this method results in no operation.
 */
- (void)unobserveAll;

@end

NS_ASSUME_NONNULL_END
