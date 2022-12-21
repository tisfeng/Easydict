/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <FirebaseCore/FIRApp.h>

@class FIRComponentContainer;
@class FIRHeartbeatLogger;
@protocol FIRLibrary;

/**
 * The internal interface to `FirebaseApp`. This is meant for first-party integrators, who need to
 * receive `FirebaseApp` notifications, log info about the success or failure of their
 * configuration, and access other internal functionality of `FirebaseApp`.
 */
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FIRConfigType) {
  FIRConfigTypeCore = 1,
  FIRConfigTypeSDK = 2,
};

extern NSString *const kFIRDefaultAppName;
extern NSString *const kFIRAppReadyToConfigureSDKNotification;
extern NSString *const kFIRAppDeleteNotification;
extern NSString *const kFIRAppIsDefaultAppKey;
extern NSString *const kFIRAppNameKey;
extern NSString *const kFIRGoogleAppIDKey;
extern NSString *const kFirebaseCoreErrorDomain;

/** The `UserDefaults` suite name for `FirebaseCore`, for those storage locations that use it. */
extern NSString *const kFirebaseCoreDefaultsSuiteName;

/**
 * The format string for the `UserDefaults` key used for storing the data collection enabled flag.
 * This includes formatting to append the `FirebaseApp`'s name.
 */
extern NSString *const kFIRGlobalAppDataCollectionEnabledDefaultsKeyFormat;

/**
 * The plist key used for storing the data collection enabled flag.
 */
extern NSString *const kFIRGlobalAppDataCollectionEnabledPlistKey;

/** @var FirebaseAuthStateDidChangeInternalNotification
 @brief The name of the @c NotificationCenter notification which is posted when the auth state
 changes (e.g. a new token has been produced, a user logs in or out). The object parameter of
 the notification is a dictionary possibly containing the key:
 @c FirebaseAuthStateDidChangeInternalNotificationTokenKey (the new access token.) If it does not
 contain this key it indicates a sign-out event took place.
 */
extern NSString *const FIRAuthStateDidChangeInternalNotification;

/** @var FirebaseAuthStateDidChangeInternalNotificationTokenKey
 @brief A key present in the dictionary object parameter of the
 @c FirebaseAuthStateDidChangeInternalNotification notification. The value associated with this
 key will contain the new access token.
 */
extern NSString *const FIRAuthStateDidChangeInternalNotificationTokenKey;

/** @var FirebaseAuthStateDidChangeInternalNotificationAppKey
 @brief A key present in the dictionary object parameter of the
 @c FirebaseAuthStateDidChangeInternalNotification notification. The value associated with this
 key will contain the FirebaseApp associated with the auth instance.
 */
extern NSString *const FIRAuthStateDidChangeInternalNotificationAppKey;

/** @var FirebaseAuthStateDidChangeInternalNotificationUIDKey
 @brief A key present in the dictionary object parameter of the
 @c FirebaseAuthStateDidChangeInternalNotification notification. The value associated with this
 key will contain the new user's UID (or nil if there is no longer a user signed in).
 */
extern NSString *const FIRAuthStateDidChangeInternalNotificationUIDKey;

@interface FIRApp ()

/**
 * A flag indicating if this is the default app (has the default app name).
 */
@property(nonatomic, readonly) BOOL isDefaultApp;

/**
 * The container of interop SDKs for this app.
 */
@property(nonatomic) FIRComponentContainer *container;

/**
 * The heartbeat logger associated with this app.
 *
 * Firebase apps have a 1:1 relationship with heartbeat loggers.
 */
@property(readonly) FIRHeartbeatLogger *heartbeatLogger;

/**
 * Checks if the default app is configured without trying to configure it.
 */
+ (BOOL)isDefaultAppConfigured;

/**
 * Registers a given third-party library with the given version number to be reported for
 * analytics.
 *
 * @param name Name of the library.
 * @param version Version of the library.
 */
+ (void)registerLibrary:(nonnull NSString *)name withVersion:(nonnull NSString *)version;

/**
 * Registers a given internal library to be reported for analytics.
 *
 * @param library Optional parameter for component registration.
 * @param name Name of the library.
 */
+ (void)registerInternalLibrary:(nonnull Class<FIRLibrary>)library
                       withName:(nonnull NSString *)name;

/**
 * Registers a given internal library with the given version number to be reported for
 * analytics. This should only be used for non-Firebase libraries that have their own versioning
 * scheme.
 *
 * @param library Optional parameter for component registration.
 * @param name Name of the library.
 * @param version Version of the library.
 */
+ (void)registerInternalLibrary:(nonnull Class<FIRLibrary>)library
                       withName:(nonnull NSString *)name
                    withVersion:(nonnull NSString *)version;

/**
 * A concatenated string representing all the third-party libraries and version numbers.
 */
+ (NSString *)firebaseUserAgent;

/**
 * Can be used by the unit tests in each SDK to reset `FirebaseApp`. This method is thread unsafe.
 */
+ (void)resetApps;

/**
 * Can be used by the unit tests in each SDK to set customized options.
 */
- (instancetype)initInstanceWithName:(NSString *)name options:(FIROptions *)options;

@end

NS_ASSUME_NONNULL_END
