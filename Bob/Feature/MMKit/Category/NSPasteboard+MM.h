//
//  NSPasteboard+MM.h
//  Bob
//
//  Created by ripper on 2019/12/11.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSPasteboard (MM)

+ (BOOL)mm_generalPasteboardSetString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
