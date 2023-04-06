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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This class provides constant fields of Google APIs.
 */
NS_SWIFT_NAME(FirebaseOptions)
@interface FIROptions : NSObject <NSCopying>

/**
 * Returns the default options. The first time this is called it synchronously reads
 * GoogleService-Info.plist from disk.
 */
+ (nullable FIROptions *)defaultOptions NS_SWIFT_NAME(defaultOptions());

/**
 * An API key used for authenticating requests from your Apple app, e.g.
 * The key must begin with "A" and contain exactly 39 alphanumeric characters, used to identify your
 * app to Google servers.
 */
@property(nonatomic, copy, nullable) NSString *APIKey NS_SWIFT_NAME(apiKey);

/**
 * The bundle ID for the application. Defaults to `Bundle.main.bundleIdentifier` when not set
 * manually or in a plist.
 */
@property(nonatomic, copy) NSString *bundleID;

/**
 * The OAuth2 client ID for Apple applications used to authenticate Google users, for example
 * @"12345.apps.googleusercontent.com", used for signing in with Google.
 */
@property(nonatomic, copy, nullable) NSString *clientID;

/**
 * Unused.
 */
@property(nonatomic, copy, nullable) NSString *trackingID DEPRECATED_ATTRIBUTE;

/**
 * The Project Number from the Google Developer's console, for example @"012345678901", used to
 * configure Firebase Cloud Messaging.
 */
@property(nonatomic, copy) NSString *GCMSenderID NS_SWIFT_NAME(gcmSenderID);

/**
 * The Project ID from the Firebase console, for example @"abc-xyz-123".
 */
@property(nonatomic, copy, nullable) NSString *projectID;

/**
 * Unused.
 */
@property(nonatomic, copy, nullable) NSString *androidClientID DEPRECATED_ATTRIBUTE;

/**
 * The Google App ID that is used to uniquely identify an instance of an app.
 */
@property(nonatomic, copy) NSString *googleAppID;

/**
 * The database root URL, e.g. @"http://abc-xyz-123.firebaseio.com".
 */
@property(nonatomic, copy, nullable) NSString *databaseURL;

/**
 * The URL scheme used to set up Durable Deep Link service.
 */
@property(nonatomic, copy, nullable) NSString *deepLinkURLScheme;

/**
 * The Google Cloud Storage bucket name, e.g. @"abc-xyz-123.storage.firebase.com".
 */
@property(nonatomic, copy, nullable) NSString *storageBucket;

/**
 * The App Group identifier to share data between the application and the application extensions.
 * The App Group must be configured in the application and on the Apple Developer Portal. Default
 * value `nil`.
 */
@property(nonatomic, copy, nullable) NSString *appGroupID;

/**
 * Initializes a customized instance of FirebaseOptions from the file at the given plist file path.
 * This will read the file synchronously from disk.
 * For example:
 * ```swift
 *   if let path = Bundle.main.path(forResource:"GoogleServices-Info", ofType:"plist") {
 *       let options = FirebaseOptions(contentsOfFile: path)
 *   }
 * ```
 * Note that it is not possible to customize `FirebaseOptions` for Firebase Analytics which expects
 * a static file named `GoogleServices-Info.plist` -
 * https://github.com/firebase/firebase-ios-sdk/issues/230.
 * Returns `nil` if the plist file does not exist or is invalid.
 */
- (nullable instancetype)initWithContentsOfFile:(NSString *)plistPath NS_DESIGNATED_INITIALIZER;

/**
 * Initializes a customized instance of `FirebaseOptions` with required fields. Use the mutable
 * properties to modify fields for configuring specific services. Note that it is not possible to
 * customize `FirebaseOptions` for Firebase Analytics which expects a static file named
 * `GoogleServices-Info.plist` - https://github.com/firebase/firebase-ios-sdk/issues/230.
 */
- (instancetype)initWithGoogleAppID:(NSString *)googleAppID
                        GCMSenderID:(NSString *)GCMSenderID
    NS_SWIFT_NAME(init(googleAppID:gcmSenderID:))NS_DESIGNATED_INITIALIZER;

/** Unavailable. Please use `init(contentsOfFile:)` or `init(googleAppID:gcmSenderID:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
