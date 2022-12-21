#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FIRAnalytics+AppDelegate.h"
#import "FIRAnalytics+Consent.h"
#import "FIRAnalytics+OnDevice.h"
#import "FIRAnalytics.h"
#import "FirebaseAnalytics.h"
#import "FIREventNames.h"
#import "FIRParameterNames.h"
#import "FIRUserPropertyNames.h"

FOUNDATION_EXPORT double FirebaseAnalyticsVersionNumber;
FOUNDATION_EXPORT const unsigned char FirebaseAnalyticsVersionString[];

