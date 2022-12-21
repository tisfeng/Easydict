// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if __has_include(<AppCenterAnalytics/MSACAnalyticsAuthenticationProviderDelegate.h>)
#import <AppCenterAnalytics/MSACAnalyticsAuthenticationProviderDelegate.h>
#else
#import "MSACAnalyticsAuthenticationProviderDelegate.h"
#endif

/**
 * Different authentication types, e.g. MSA Compact, MSA Delegate, AAD,... .
 */
typedef NS_ENUM(NSUInteger, MSACAnalyticsAuthenticationType) {

  /**
   * AuthenticationType MSA Compact.
   */
  MSACAnalyticsAuthenticationTypeMsaCompact,

  /**
   * AuthenticationType MSA Delegate.
   */
  MSACAnalyticsAuthenticationTypeMsaDelegate
} NS_SWIFT_NAME(AnalyticsAuthenticationType);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AnalyticsAuthenticationProvider)
@interface MSACAnalyticsAuthenticationProvider : NSObject

/**
 * The type.
 */
@property(nonatomic, readonly, assign) MSACAnalyticsAuthenticationType type;

/**
 * The ticket key for this authentication provider.
 */
@property(nonatomic, readonly, copy) NSString *ticketKey;

/**
 * The ticket key as hash.
 */
@property(nonatomic, readonly, copy) NSString *ticketKeyHash;

@property(nonatomic, readonly, weak) id<MSACAnalyticsAuthenticationProviderDelegate> delegate;

/**
 * Create a new authentication provider.
 *
 * @param type The type for the provider, e.g. MSA.
 * @param ticketKey The ticket key for the provider.
 * @param delegate The delegate.
 *
 * @return A new authentication provider.
 */
- (instancetype)initWithAuthenticationType:(MSACAnalyticsAuthenticationType)type
                                 ticketKey:(NSString *)ticketKey
                                  delegate:(id<MSACAnalyticsAuthenticationProviderDelegate>)delegate;

/**
 * Check expiration.
 */
- (void)checkTokenExpiry;

@end

NS_ASSUME_NONNULL_END
