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

#import "FirebaseInstallations/Source/Library/InstallationsAPI/FIRInstallationsAPIService.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "FirebaseCore/Extension/FirebaseCoreInternal.h"
#import "FirebaseInstallations/Source/Library/Errors/FIRInstallationsErrorUtil.h"
#import "FirebaseInstallations/Source/Library/Errors/FIRInstallationsHTTPError.h"
#import "FirebaseInstallations/Source/Library/FIRInstallationsLogger.h"
#import "FirebaseInstallations/Source/Library/InstallationsAPI/FIRInstallationsItem+RegisterInstallationAPI.h"

NSString *const kFIRInstallationsAPIBaseURL = @"https://firebaseinstallations.googleapis.com";
NSString *const kFIRInstallationsAPIKey = @"X-Goog-Api-Key";
NSString *const kFIRInstallationsBundleId = @"X-Ios-Bundle-Identifier";
NSString *const kFIRInstallationsIIDMigrationAuthHeader = @"x-goog-fis-ios-iid-migration-auth";
NSString *const kFIRInstallationsHeartbeatKey = @"X-firebase-client";

NS_ASSUME_NONNULL_BEGIN

@interface FIRInstallationsURLSessionResponse : NSObject
@property(nonatomic) NSHTTPURLResponse *HTTPResponse;
@property(nonatomic) NSData *data;

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response data:(nullable NSData *)data;
@end

@implementation FIRInstallationsURLSessionResponse

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response data:(nullable NSData *)data {
  self = [super init];
  if (self) {
    _HTTPResponse = response;
    _data = data ?: [NSData data];
  }
  return self;
}

@end

@interface FIRInstallationsAPIService ()
@property(nonatomic, readonly) NSURLSession *URLSession;
@property(nonatomic, readonly) NSString *APIKey;
@property(nonatomic, readonly) NSString *projectID;
@property(readonly) id<FIRHeartbeatLoggerProtocol> heartbeatLogger;
@end

NS_ASSUME_NONNULL_END

@implementation FIRInstallationsAPIService

- (instancetype)initWithAPIKey:(NSString *)APIKey
                     projectID:(NSString *)projectID
               heartbeatLogger:(id<FIRHeartbeatLoggerProtocol>)heartbeatLogger {
  NSURLSession *URLSession = [NSURLSession
      sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
  return [self initWithURLSession:URLSession
                           APIKey:APIKey
                        projectID:projectID
                  heartbeatLogger:heartbeatLogger];
}

/// The initializer for tests.
- (instancetype)initWithURLSession:(NSURLSession *)URLSession
                            APIKey:(NSString *)APIKey
                         projectID:(NSString *)projectID
                   heartbeatLogger:(id<FIRHeartbeatLoggerProtocol>)heartbeatLogger {
  self = [super init];
  if (self) {
    _URLSession = URLSession;
    _APIKey = [APIKey copy];
    _projectID = [projectID copy];
    _heartbeatLogger = heartbeatLogger;
  }
  return self;
}

#pragma mark - Public

- (FBLPromise<FIRInstallationsItem *> *)registerInstallation:(FIRInstallationsItem *)installation {
  return [self validateInstallation:installation]
      .then(^id _Nullable(FIRInstallationsItem *_Nullable validInstallation) {
        return [self registerRequestWithInstallation:validInstallation];
      })
      .then(^id _Nullable(NSURLRequest *_Nullable request) {
        return [self sendURLRequest:request];
      })
      .then(^id _Nullable(FIRInstallationsURLSessionResponse *response) {
        return [self registeredInstallationWithInstallation:installation serverResponse:response];
      });
}

- (FBLPromise<FIRInstallationsItem *> *)refreshAuthTokenForInstallation:
    (FIRInstallationsItem *)installation {
  return [self authTokenRequestWithInstallation:installation]
      .then(^id _Nullable(NSURLRequest *_Nullable request) {
        return [self sendURLRequest:request];
      })
      .then(^FBLPromise<FIRInstallationsStoredAuthToken *> *(
          FIRInstallationsURLSessionResponse *response) {
        return [self authTokenWithServerResponse:response];
      })
      .then(^FIRInstallationsItem *(FIRInstallationsStoredAuthToken *authToken) {
        FIRInstallationsItem *updatedInstallation = [installation copy];
        updatedInstallation.authToken = authToken;
        return updatedInstallation;
      });
}

- (FBLPromise<FIRInstallationsItem *> *)deleteInstallation:(FIRInstallationsItem *)installation {
  return [self deleteInstallationRequestWithInstallation:installation]
      .then(^id _Nullable(NSURLRequest *_Nullable request) {
        return [self sendURLRequest:request];
      })
      .then(^id _Nullable(FIRInstallationsURLSessionResponse *_Nullable value) {
        // Return the original installation on success.
        return installation;
      });
}

#pragma mark - Register Installation

- (FBLPromise<NSURLRequest *> *)registerRequestWithInstallation:
    (FIRInstallationsItem *)installation {
  NSString *URLString = [NSString stringWithFormat:@"%@/v1/projects/%@/installations/",
                                                   kFIRInstallationsAPIBaseURL, self.projectID];
  NSURL *URL = [NSURL URLWithString:URLString];

  NSDictionary *bodyDict = @{
    // `firebaseInstallationID` is validated before but let's make sure it is not `nil` one more
    // time to prevent a crash.
    @"fid" : installation.firebaseInstallationID ?: @"",
    @"authVersion" : @"FIS_v2",
    @"appId" : installation.appID,
    @"sdkVersion" : [self SDKVersion]
  };

  NSDictionary *headers;
  if (installation.IIDDefaultToken) {
    headers = @{kFIRInstallationsIIDMigrationAuthHeader : installation.IIDDefaultToken};
  }

  return [self requestWithURL:URL
                   HTTPMethod:@"POST"
                     bodyDict:bodyDict
                 refreshToken:nil
            additionalHeaders:headers];
}

- (FBLPromise<FIRInstallationsItem *> *)
    registeredInstallationWithInstallation:(FIRInstallationsItem *)installation
                            serverResponse:(FIRInstallationsURLSessionResponse *)response {
  return [FBLPromise do:^id {
    FIRLogDebug(kFIRLoggerInstallations, kFIRInstallationsMessageCodeParsingAPIResponse,
                @"Parsing server response for %@.", response.HTTPResponse.URL);
    NSError *error;
    FIRInstallationsItem *registeredInstallation =
        [installation registeredInstallationWithJSONData:response.data
                                                    date:[NSDate date]
                                                   error:&error];
    if (registeredInstallation == nil) {
      FIRLogDebug(kFIRLoggerInstallations,
                  kFIRInstallationsMessageCodeAPIResponseParsingInstallationFailed,
                  @"Failed to parse FIRInstallationsItem: %@.", error);
      return error;
    }

    FIRLogDebug(kFIRLoggerInstallations,
                kFIRInstallationsMessageCodeAPIResponseParsingInstallationSucceed,
                @"FIRInstallationsItem parsed successfully.");
    return registeredInstallation;
  }];
}

#pragma mark - Auth token

- (FBLPromise<NSURLRequest *> *)authTokenRequestWithInstallation:
    (FIRInstallationsItem *)installation {
  NSString *URLString =
      [NSString stringWithFormat:@"%@/v1/projects/%@/installations/%@/authTokens:generate",
                                 kFIRInstallationsAPIBaseURL, self.projectID,
                                 installation.firebaseInstallationID];
  NSURL *URL = [NSURL URLWithString:URLString];

  NSDictionary *bodyDict = @{@"installation" : @{@"sdkVersion" : [self SDKVersion]}};
  return [self requestWithURL:URL
                   HTTPMethod:@"POST"
                     bodyDict:bodyDict
                 refreshToken:installation.refreshToken];
}

- (FBLPromise<FIRInstallationsStoredAuthToken *> *)authTokenWithServerResponse:
    (FIRInstallationsURLSessionResponse *)response {
  return [FBLPromise do:^id {
    FIRLogDebug(kFIRLoggerInstallations, kFIRInstallationsMessageCodeParsingAPIResponse,
                @"Parsing server response for %@.", response.HTTPResponse.URL);
    NSError *error;
    FIRInstallationsStoredAuthToken *token =
        [FIRInstallationsItem authTokenWithGenerateTokenAPIJSONData:response.data
                                                               date:[NSDate date]
                                                              error:&error];
    if (token == nil) {
      FIRLogDebug(kFIRLoggerInstallations,
                  kFIRInstallationsMessageCodeAPIResponseParsingAuthTokenFailed,
                  @"Failed to parse FIRInstallationsStoredAuthToken: %@.", error);
      return error;
    }

    FIRLogDebug(kFIRLoggerInstallations,
                kFIRInstallationsMessageCodeAPIResponseParsingAuthTokenSucceed,
                @"FIRInstallationsStoredAuthToken parsed successfully.");
    return token;
  }];
}

#pragma mark - Delete Installation

- (FBLPromise<NSURLRequest *> *)deleteInstallationRequestWithInstallation:
    (FIRInstallationsItem *)installation {
  NSString *URLString = [NSString stringWithFormat:@"%@/v1/projects/%@/installations/%@/",
                                                   kFIRInstallationsAPIBaseURL, self.projectID,
                                                   installation.firebaseInstallationID];
  NSURL *URL = [NSURL URLWithString:URLString];

  return [self requestWithURL:URL
                   HTTPMethod:@"DELETE"
                     bodyDict:@{}
                 refreshToken:installation.refreshToken];
}

#pragma mark - URL Request
- (FBLPromise<NSURLRequest *> *)requestWithURL:(NSURL *)requestURL
                                    HTTPMethod:(NSString *)HTTPMethod
                                      bodyDict:(NSDictionary *)bodyDict
                                  refreshToken:(nullable NSString *)refreshToken {
  return [self requestWithURL:requestURL
                   HTTPMethod:HTTPMethod
                     bodyDict:bodyDict
                 refreshToken:refreshToken
            additionalHeaders:nil];
}

- (FBLPromise<NSURLRequest *> *)requestWithURL:(NSURL *)requestURL
                                    HTTPMethod:(NSString *)HTTPMethod
                                      bodyDict:(NSDictionary *)bodyDict
                                  refreshToken:(nullable NSString *)refreshToken
                             additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)
                                                   additionalHeaders {
  return [FBLPromise
      onQueue:dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
           do:^id _Nullable {
             __block NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
             request.HTTPMethod = HTTPMethod;
             NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
             [request addValue:self.APIKey forHTTPHeaderField:kFIRInstallationsAPIKey];
             [request addValue:bundleIdentifier forHTTPHeaderField:kFIRInstallationsBundleId];
             [self setJSONHTTPBody:bodyDict forRequest:request];
             if (refreshToken) {
               NSString *authHeader = [NSString stringWithFormat:@"FIS_v2 %@", refreshToken];
               [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
             }
             // Heartbeat Header.
             [request setValue:FIRHeaderValueFromHeartbeatsPayload(
                                   [self.heartbeatLogger flushHeartbeatsIntoPayload])
                 forHTTPHeaderField:kFIRInstallationsHeartbeatKey];

             [additionalHeaders
                 enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj,
                                                     BOOL *_Nonnull stop) {
                   [request setValue:obj forHTTPHeaderField:key];
                 }];

             return [request copy];
           }];
}

- (FBLPromise<FIRInstallationsURLSessionResponse *> *)URLRequestPromise:(NSURLRequest *)request {
  return [[FBLPromise async:^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
    FIRLogDebug(kFIRLoggerInstallations, kFIRInstallationsMessageCodeSendAPIRequest,
                @"Sending request: %@, body:%@, headers: %@.", request,
                [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding],
                request.allHTTPHeaderFields);
    [[self.URLSession
        dataTaskWithRequest:request
          completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                              NSError *_Nullable error) {
            if (error) {
              FIRLogDebug(kFIRLoggerInstallations,
                          kFIRInstallationsMessageCodeAPIRequestNetworkError,
                          @"Request failed: %@, error: %@.", request, error);
              reject(error);
            } else {
              FIRLogDebug(kFIRLoggerInstallations, kFIRInstallationsMessageCodeAPIRequestResponse,
                          @"Request response received: %@, error: %@, body: %@.", request, error,
                          [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
              fulfill([[FIRInstallationsURLSessionResponse alloc]
                  initWithResponse:(NSHTTPURLResponse *)response
                              data:data]);
            }
          }] resume];
  }] then:^id _Nullable(FIRInstallationsURLSessionResponse *response) {
    return [self validateHTTPResponseStatusCode:response];
  }];
}

- (FBLPromise<FIRInstallationsURLSessionResponse *> *)validateHTTPResponseStatusCode:
    (FIRInstallationsURLSessionResponse *)response {
  NSInteger statusCode = response.HTTPResponse.statusCode;
  return [FBLPromise do:^id _Nullable {
    if (statusCode < 200 || statusCode >= 300) {
      FIRLogDebug(kFIRLoggerInstallations, kFIRInstallationsMessageCodeUnexpectedAPIRequestResponse,
                  @"Unexpected API response: %@, body: %@.", response.HTTPResponse,
                  [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding]);
      return [FIRInstallationsErrorUtil APIErrorWithHTTPResponse:response.HTTPResponse
                                                            data:response.data];
    }
    return response;
  }];
}

- (FBLPromise<FIRInstallationsURLSessionResponse *> *)sendURLRequest:(NSURLRequest *)request {
  return [FBLPromise attempts:1
      delay:1
      condition:^BOOL(NSInteger remainingAttempts, NSError *_Nonnull error) {
        return [FIRInstallationsErrorUtil isAPIError:error
                                        withHTTPCode:FIRInstallationsHTTPCodesServerInternalError];
      }
      retry:^id _Nullable {
        return [self URLRequestPromise:request];
      }];
}

- (NSString *)SDKVersion {
  return [NSString stringWithFormat:@"i:%@", FIRFirebaseVersion()];
}

#pragma mark - Validation

- (FBLPromise<FIRInstallationsItem *> *)validateInstallation:(FIRInstallationsItem *)installation {
  FBLPromise<FIRInstallationsItem *> *result = [FBLPromise pendingPromise];

  NSError *validationError;
  if ([installation isValid:&validationError]) {
    [result fulfill:installation];
  } else {
    [result reject:validationError];
  }
  return result;
}

#pragma mark - JSON

- (void)setJSONHTTPBody:(NSDictionary<NSString *, id> *)body
             forRequest:(NSMutableURLRequest *)request {
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  NSError *error;
  NSData *JSONData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
  if (JSONData == nil) {
    // TODO: Log or return an error.
  }
  request.HTTPBody = JSONData;
}

@end
