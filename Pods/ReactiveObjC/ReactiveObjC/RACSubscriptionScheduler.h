//
//  RACSubscriptionScheduler.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 11/30/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACScheduler.h"

NS_ASSUME_NONNULL_BEGIN

// A private scheduler used only for subscriptions. See the private
// +[RACScheduler subscriptionScheduler] method for more information.
@interface RACSubscriptionScheduler : RACScheduler

@end

NS_ASSUME_NONNULL_END
