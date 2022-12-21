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

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULKeychainUtils.h"

NSString *const kGULKeychainUtilsErrorDomain = @"com.gul.keychain.ErrorDomain";

@implementation GULKeychainUtils

+ (nullable NSData *)getItemWithQuery:(NSDictionary *)query
                                error:(NSError *_Nullable *_Nullable)outError {
  NSMutableDictionary *mutableGetItemQuery =
      [[[self class] multiplatformQueryWithQuery:query] mutableCopy];

  mutableGetItemQuery[(__bridge id)kSecReturnData] = @YES;
  mutableGetItemQuery[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

  CFDataRef result = NULL;
  OSStatus status =
      SecItemCopyMatching((__bridge CFDictionaryRef)mutableGetItemQuery, (CFTypeRef *)&result);

  if (status == errSecSuccess && result != NULL) {
    if (outError) {
      *outError = nil;
    }

    return (__bridge_transfer NSData *)result;
  }

  if (status == errSecItemNotFound) {
    if (outError) {
      *outError = nil;
    }
  } else {
    if (outError) {
      *outError = [self keychainErrorWithFunction:@"SecItemCopyMatching" status:status];
    }
  }
  return nil;
}

+ (BOOL)setItem:(NSData *)item
      withQuery:(NSDictionary *)query
          error:(NSError *_Nullable *_Nullable)outError {
  NSDictionary *multiplatformQuery = [[self class] multiplatformQueryWithQuery:query];

  NSData *existingItem = [self getItemWithQuery:multiplatformQuery error:outError];
  if (outError && *outError) {
    return NO;
  }

  OSStatus status;
  if (!existingItem) {
    NSMutableDictionary *mutableAddItemQuery = [multiplatformQuery mutableCopy];
    mutableAddItemQuery[(__bridge id)kSecAttrAccessible] =
        (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    mutableAddItemQuery[(__bridge id)kSecValueData] = item;

    status = SecItemAdd((__bridge CFDictionaryRef)mutableAddItemQuery, NULL);
  } else {
    NSDictionary *attributes = @{(__bridge id)kSecValueData : item};
    status = SecItemUpdate((__bridge CFDictionaryRef)multiplatformQuery,
                           (__bridge CFDictionaryRef)attributes);
  }

  if (status == noErr) {
    if (outError) {
      *outError = nil;
    }
    return YES;
  }

  NSString *function = existingItem ? @"SecItemUpdate" : @"SecItemAdd";
  if (outError) {
    *outError = [self keychainErrorWithFunction:function status:status];
  }
  return NO;
}

+ (BOOL)removeItemWithQuery:(NSDictionary *)query error:(NSError *_Nullable *_Nullable)outError {
  NSDictionary *deleteItemQuery = [[self class] multiplatformQueryWithQuery:query];

  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)deleteItemQuery);

  if (status == noErr || status == errSecItemNotFound) {
    if (outError) {
      *outError = nil;
    }
    return YES;
  }

  if (outError) {
    *outError = [self keychainErrorWithFunction:@"SecItemDelete" status:status];
  }
  return NO;
}

#pragma mark - Private

/// Returns a `NSDictionary` query that behaves the same across all platforms.
/// - Note: In practice, this API only makes a difference to keychain queries on macOS.
/// See go/firebase-macos-keychain-popups for details.
/// - Parameter query: A query to create the protected keychain query with.
+ (NSDictionary *)multiplatformQueryWithQuery:(NSDictionary *)query {
  NSMutableDictionary *multiplatformQuery = [query mutableCopy];
  if (@available(iOS 13.0, macOS 10.15, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, *)) {
    multiplatformQuery[(__bridge id)kSecUseDataProtectionKeychain] = (__bridge id)kCFBooleanTrue;
  }
  return [multiplatformQuery copy];
}

#pragma mark - Errors

+ (NSError *)keychainErrorWithFunction:(NSString *)keychainFunction status:(OSStatus)status {
  NSString *failureReason = [NSString stringWithFormat:@"%@ (%li)", keychainFunction, (long)status];
  NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : failureReason};
  return [NSError errorWithDomain:kGULKeychainUtilsErrorDomain code:0 userInfo:userInfo];
}

@end
