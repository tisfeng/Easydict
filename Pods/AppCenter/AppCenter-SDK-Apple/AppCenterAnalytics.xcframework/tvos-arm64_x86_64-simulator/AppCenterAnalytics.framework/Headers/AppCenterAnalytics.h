// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if __has_include(<AppCenterAnalytics/MSACAnalytics.h>)
#import <AppCenterAnalytics/MSACAnalytics.h>
#import <AppCenterAnalytics/MSACAnalyticsAuthenticationProvider.h>
#import <AppCenterAnalytics/MSACAnalyticsAuthenticationProviderDelegate.h>
#import <AppCenterAnalytics/MSACAnalyticsTransmissionTarget.h>
#import <AppCenterAnalytics/MSACEventLog.h>
#import <AppCenterAnalytics/MSACEventProperties.h>
#else
#import "MSACAnalytics.h"
#import "MSACAnalyticsAuthenticationProvider.h"
#import "MSACAnalyticsAuthenticationProviderDelegate.h"
#import "MSACAnalyticsTransmissionTarget.h"
#import "MSACEventLog.h"
#import "MSACEventProperties.h"
#endif
