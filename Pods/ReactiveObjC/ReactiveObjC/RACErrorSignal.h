//
//  RACErrorSignal.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-10-10.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACSignal.h"

// A private `RACSignal` subclass that synchronously sends an error to any
// subscriber.
@interface RACErrorSignal : RACSignal

+ (RACSignal *)error:(NSError *)error;

@end
