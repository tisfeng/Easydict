// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSACAnalyticsAuthenticationProvider;

/**
 * Completion handler that returns the authentication token and the expiry date.
 */
typedef void (^MSACAnalyticsAuthenticationProviderCompletionBlock)(NSString *token, NSDate *expiryDate)
    NS_SWIFT_NAME(AnalyticsAuthenticationProviderCompletionBlock);

NS_SWIFT_NAME(AnalyticsAuthenticationProviderDelegate)
@protocol MSACAnalyticsAuthenticationProviderDelegate <NSObject>

/**
 * Required method that needs to be called from within your authentication flow to provide the authentication token and expiry date.
 *
 * @param authenticationProvider The authentication provider.
 * @param completionHandler The completion handler.
 */
- (void)authenticationProvider:(MSACAnalyticsAuthenticationProvider *)authenticationProvider
    acquireTokenWithCompletionHandler:(MSACAnalyticsAuthenticationProviderCompletionBlock)completionHandler;

@end
