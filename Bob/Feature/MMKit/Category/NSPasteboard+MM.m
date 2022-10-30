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
    [[NSPasteboard generalPasteboard] clearContents];
    if (!string.length) return NO;
    return [[NSPasteboard generalPasteboard] setString:string forType:NSPasteboardTypeString];
}

@end
