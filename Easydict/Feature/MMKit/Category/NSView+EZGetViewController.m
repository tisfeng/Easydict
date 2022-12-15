//
//  NSView+EZGetViewController.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "NSView+EZGetViewController.h"

@implementation NSView (EZGetViewController)

- (NSViewController *)ez_getViewController {
    NSResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[NSViewController class]]) {
            return (NSViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

@end
