//
//  NSView+EZWindowType.m
//  Easydict
//
//  Created by tisfeng on 2022/11/24.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSObject+EZWindowType.h"

static NSString *_EZWindowTypeKey = @"EZWindowTypeKey";

@implementation NSObject (EZWindowType)

- (void)setWindowType:(EZWindowType)windowType {
    objc_setAssociatedObject(self, (__bridge const void *)(_EZWindowTypeKey), @(windowType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EZWindowType)windowType {
    return [objc_getAssociatedObject(self, (__bridge const void *)(_EZWindowTypeKey)) integerValue];
}

@end
