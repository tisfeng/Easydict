// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef MSAC_EVENT_LOG_H
#define MSAC_EVENT_LOG_H

#if __has_include(<AppCenterAnalytics/MSACLogWithNameAndProperties.h>)
#import <AppCenterAnalytics/MSACLogWithNameAndProperties.h>
#else
#import "MSACLogWithNameAndProperties.h"
#endif

@class MSACEventProperties;
@class MSACMetadataExtension;

NS_SWIFT_NAME(EventLog)
@interface MSACEventLog : MSACLogWithNameAndProperties

/**
 * Unique identifier for this event.
 */
@property(nonatomic, copy) NSString *eventId;

/**
 * Event properties.
 */
@property(nonatomic, strong) MSACEventProperties *typedProperties;

@end

#endif
