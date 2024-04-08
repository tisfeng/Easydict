//
//  NSViewController+EZWindow.m
//  Easydict
//
//  Created by tisfeng on 2023/4/19.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSViewController+EZWindow.h"

@implementation NSViewController (EZWindow)

- (nullable NSWindow *)window {
    NSResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[NSWindow class]]) {
            return (NSWindow *)responder;
        }
    }
    return nil;
}

@end
