//
//  Selection.m
//  Bob
//
//  Created by ripper on 2019/10/19.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "Selection.h"
#include <Carbon/Carbon.h>

@implementation Selection

+ (void)getText:(void (^)(NSString * _Nullable))completion {
    [[NSPasteboard generalPasteboard] clearContents];
    
    CGEventRef push = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_C, true);
    CGEventSetFlags(push, kCGEventFlagMaskCommand);
    CGEventPost(kCGHIDEventTap, push);
    CFRelease(push);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *string = [[[[NSPasteboard generalPasteboard] pasteboardItems] firstObject] stringForType:NSPasteboardTypeString];
        completion(string);
    });
}

@end
