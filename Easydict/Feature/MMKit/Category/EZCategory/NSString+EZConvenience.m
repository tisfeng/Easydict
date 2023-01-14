//
//  NSString+EZConvenience.m
//  Easydict
//
//  Created by tisfeng on 2023/1/1.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZConvenience.h"

@implementation NSString (EZConvenience)

- (NSString *)trim {
    NSString *trimText = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimText;
}

- (NSString *)encode {
    NSString *encodedText = [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return encodedText;
}

- (void)copyToPasteboard {
    [NSPasteboard mm_generalPasteboardSetString:self];
}

// use NSDataDetector to check if the string is a valid http url
- (BOOL)isHttpURL {
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [detector matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    if (matches.count == 0) {
        return NO;
    }
    NSTextCheckingResult *result = matches.firstObject;
    if (result.resultType == NSTextCheckingTypeLink && result.URL) {
        return YES;
    }
    return NO;
}

@end
