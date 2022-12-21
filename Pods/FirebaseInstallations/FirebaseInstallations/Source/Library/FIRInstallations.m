/*
 * Copyright 2019 Google
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

#import "FirebaseInstallations/Source/Library/Public/FirebaseInstallations/FIRInstallations.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "FirebaseCore/Extension/FirebaseCoreInternal.h"

#import "FirebaseInstallations/Source/Library/FIRInstallationsAuthTokenResultInternal.h"

#import "FirebaseInstallations/Source/Library/Errors/FIRInstallationsErrorUtil.h"
#import "FirebaseInstallations/Source/Library/FIRInstallationsItem.h"
#import "FirebaseInstallations/Source/Library/FIRInstallationsLogger.h"
#import "FirebaseInstallations/Source/Library/InstallationsIDController/FIRInstallationsIDController.h"
#import "FirebaseInstallations/Source/Library/InstallationsStore/FIRInstallationsStoredAuthToken.h"

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger kExpectedAPIKeyLength = 39;

@protocol FIRInstallationsInstanceProvider <FIRLibrary>
@end

@interface FIRInstallations () <FIRInstallationsInstanceProvider>
@property(nonatomic, readonly) FIROptions *appOptions;
@property(nonatomic, readonly) NSString *appName;

@property(nonatomic, readonly) FIRInstallationsIDController *installationsIDController;

@end

@implementation FIRInstallations

#pragma mark - Firebase component

+ (void)load {
  [FIRApp registerInternalLibrary:(Class<FIRLibrary>)self withName:@"fire-install"];
}

+ (nonnull NSArray<FIRComponent *> *)componentsToRegister {
  FIRComponentCreationBlock creationBlock =
      ^id _Nullable(FIRComponentContainer *container, BOOL *isCacheable) {
    *isCacheable = YES;
    FIRInstallations *installations = [[FIRInstallations alloc] initWithApp:container.app];
    return installations;
  };

  FIRComponent *installationsProvider =
      [FIRComponent componentWithProtocol:@protocol(FIRInstallationsInstanceProvider)
                      instantiationTiming:FIRInstantiationTimingAlwaysEager
                             dependencies:@[]
                            creationBlock:creationBlock];
  return @[ installationsProvider ];
}

- (instancetype)initWithApp:(FIRApp *)app {
  FIRInstallationsIDController *IDController =
      [[FIRInstallationsIDController alloc] initWithApp:app];

  // `prefetchAuthToken` is disabled due to b/156746574.
  return [self initWithAppOptions:app.options
                          appName:app.name
        installationsIDController:IDController
                prefetchAuthToken:NO];
}

/// This designated initializer can be exposed for testing.
- (instancetype)initWithAppOptions:(FIROptions *)appOptions
                           appName:(NSString *)appName
         installationsIDController:(FIRInstallationsIDController *)installationsIDController
                 prefetchAuthToken:(BOOL)prefetchAuthToken {
  self = [super init];
  if (self) {
    [[self class] validateAppOptions:appOptions appName:appName];
    [[self class] assertCompatibleIIDVersion];

    _appOptions = [appOptions copy];
    _appName = [appName copy];
    _installationsIDController = installationsIDController;

    // Pre-fetch auth token.
    if (prefetchAuthToken) {
      [self authTokenWithCompletion:^(FIRInstallationsAuthTokenResult *_Nullable tokenResult,
                                      NSError *_Nullable error){
      }];
    }
  }
  return self;
}

+ (void)validateAppOptions:(FIROptions *)appOptions appName:(NSString *)appName {
  NSMutableArray *missingFields = [NSMutableArray array];
  if (appName.length < 1) {
    [missingFields addObject:@"`FirebaseApp.name`"];
  }
  if (appOptions.APIKey.length < 1) {
    [missingFields addObject:@"`FirebaseOptions.APIKey`"];
  }
  if (appOptions.googleAppID.length < 1) {
    [missingFields addObject:@"`FirebaseOptions.googleAppID`"];
  }

  if (appOptions.projectID.length < 1) {
    [missingFields addObject:@"`FirebaseOptions.projectID`"];
  }

  if (missingFields.count > 0) {
    [NSException
         raise:kFirebaseInstallationsErrorDomain
        format:
            @"%@[%@] Could not configure Firebase Installations due to invalid FirebaseApp "
            @"options. The following parameters are nil or empty: %@. If you use "
            @"GoogleServices-Info.plist please download the most recent version from the Firebase "
            @"Console. If you configure Firebase in code, please make sure you specify all "
            @"required parameters.",
            kFIRLoggerInstallations, kFIRInstallationsMessageCodeInvalidFirebaseAppOptions,
            [missingFields componentsJoinedByString:@", "]];
  }

  [self validateAPIKey:appOptions.APIKey];
}

+ (void)validateAPIKey:(nullable NSString *)APIKey {
  NSMutableArray<NSString *> *validationIssues = [[NSMutableArray alloc] init];

  if (APIKey.length != kExpectedAPIKeyLength) {
    [validationIssues addObject:[NSString stringWithFormat:@"API Key length must be %lu characters",
                                                           (unsigned long)kExpectedAPIKeyLength]];
  }

  if (![[APIKey substringToIndex:1] isEqualToString:@"A"]) {
    [validationIssues addObject:@"API Key must start with `A`"];
  }

  NSMutableCharacterSet *allowedCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
  [allowedCharacters
      formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]];

  NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:APIKey];
  if (![allowedCharacters isSupersetOfSet:characters]) {
    [validationIssues addObject:@"API Key must contain only base64 url-safe characters characters"];
  }

  if (validationIssues.count > 0) {
    [NSException
         raise:kFirebaseInstallationsErrorDomain
        format:
            @"%@[%@] Could not configure Firebase Installations due to invalid FirebaseApp "
            @"options. `FirebaseOptions.APIKey` doesn't match the expected format: %@. If you use "
            @"GoogleServices-Info.plist please download the most recent version from the Firebase "
            @"Console. If you configure Firebase in code, please make sure you specify all "
            @"required parameters.",
            kFIRLoggerInstallations, kFIRInstallationsMessageCodeInvalidFirebaseAppOptions,
            [validationIssues componentsJoinedByString:@", "]];
  }
}

#pragma mark - Public

+ (FIRInstallations *)installations {
  FIRApp *defaultApp = [FIRApp defaultApp];
  if (!defaultApp) {
    [NSException raise:kFirebaseInstallationsErrorDomain
                format:@"The default FirebaseApp instance must be configured before the default"
                       @"FirebaseApp instance can be initialized. One way to ensure this is to "
                       @"call `FirebaseApp.configure()` in the App  Delegate's "
                       @"`application(_:didFinishLaunchingWithOptions:)` "
                       @"(or the `@main` struct's initializer in SwiftUI)."];
  }

  return [self installationsWithApp:defaultApp];
}

+ (FIRInstallations *)installationsWithApp:(FIRApp *)app {
  id<FIRInstallationsInstanceProvider> installations =
      FIR_COMPONENT(FIRInstallationsInstanceProvider, app.container);
  return (FIRInstallations *)installations;
}

- (void)installationIDWithCompletion:(FIRInstallationsIDHandler)completion {
  [self.installationsIDController getInstallationItem]
      .then(^id(FIRInstallationsItem *installation) {
        completion(installation.firebaseInstallationID, nil);
        return nil;
      })
      .catch(^(NSError *error) {
        completion(nil, [FIRInstallationsErrorUtil publicDomainErrorWithError:error]);
      });
}

- (void)authTokenWithCompletion:(FIRInstallationsTokenHandler)completion {
  [self authTokenForcingRefresh:NO completion:completion];
}

- (void)authTokenForcingRefresh:(BOOL)forceRefresh
                     completion:(FIRInstallationsTokenHandler)completion {
  [self.installationsIDController getAuthTokenForcingRefresh:forceRefresh]
      .then(^FIRInstallationsAuthTokenResult *(FIRInstallationsItem *installation) {
        FIRInstallationsAuthTokenResult *result = [[FIRInstallationsAuthTokenResult alloc]
             initWithToken:installation.authToken.token
            expirationDate:installation.authToken.expirationDate];
        return result;
      })
      .then(^id(FIRInstallationsAuthTokenResult *token) {
        completion(token, nil);
        return nil;
      })
      .catch(^void(NSError *error) {
        completion(nil, [FIRInstallationsErrorUtil publicDomainErrorWithError:error]);
      });
}

- (void)deleteWithCompletion:(void (^)(NSError *__nullable error))completion {
  [self.installationsIDController deleteInstallation]
      .then(^id(id result) {
        completion(nil);
        return nil;
      })
      .catch(^void(NSError *error) {
        completion([FIRInstallationsErrorUtil publicDomainErrorWithError:error]);
      });
}

#pragma mark - IID version compatibility

+ (void)assertCompatibleIIDVersion {
  // We use this flag to disable IID compatibility exception for unit tests.
#ifdef FIR_INSTALLATIONS_ALLOWS_INCOMPATIBLE_IID_VERSION
  return;
#else
  if (![self isIIDVersionCompatible]) {
    [NSException
         raise:kFirebaseInstallationsErrorDomain
        format:@"Firebase Instance ID is not compatible with Firebase 8.x+. Please remove the "
               @"dependency from the app. See the documentation at "
               @"https://firebase.google.com/docs/cloud-messaging/ios/"
               @"client#fetching-the-current-registration-token."];
  }
#endif
}

+ (BOOL)isIIDVersionCompatible {
  Class IIDClass = NSClassFromString(@"FIRInstanceID");
  if (IIDClass == nil) {
    // It is OK if there is no IID at all.
    return YES;
  }
  // We expect a compatible version having the method `+[FIRInstanceID usesFIS]` defined.
  BOOL isCompatibleVersion = [IIDClass respondsToSelector:NSSelectorFromString(@"usesFIS")];
  return isCompatibleVersion;
}

@end

NS_ASSUME_NONNULL_END
