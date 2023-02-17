//
//  NSPasteboard+MM.m
//  Bob
//
//  Created by ripper on 2019/12/11.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "NSPasteboard+MM.h"

@implementation NSPasteboard (MM)

+ (BOOL)mm_generalPasteboardSetString:(NSString *)string {
    if (!string.length) {
        return NO;
    }
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    return [pasteboard setString:string forType:NSPasteboardTypeString];
}

@end
