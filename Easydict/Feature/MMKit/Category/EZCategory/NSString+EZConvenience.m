//
//  NSString+EZConvenience.m
//  Easydict
//
//  Created by tisfeng on 2023/1/1.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZConvenience.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (EZConvenience)

- (NSString *)trim {
    NSString *trimText = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimText;
}

- (NSString *)trimToMaxLength:(NSUInteger)maxLength {
    NSString *trimText = [self trim];
    if (trimText.length > maxLength) {
        trimText = [self substringToIndex:maxLength];
    }
    return trimText;
}

- (NSString *)encode {
    NSString *encodedText = [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return encodedText;
}

- (void)copyToPasteboard {
    [NSPasteboard mm_generalPasteboardSetString:self];
}

/// Check if the string is a valid URL. eg. https://www.google.com
- (BOOL)isURL {
    NSURL *url = [NSURL URLWithString:self];
    if (url && url.scheme && url.host) {
        // 有 scheme 和 host 表示是一个合法的 URL
        return YES;
    } else {
        return NO;
    }
}

// Use NSDataDetector to check if the string contains a link. eg. eudic://dict/good
- (BOOL)containsLink {
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


- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
#pragma clang diagnostic pop

    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return result;
}

#pragma mark -

/// Convert Simplified Chinese to Traditional Chinese.
- (NSString *)toTraditionalChineseText {
    NSString *traditionalChinese = [self stringByApplyingTransform:@"Hans-Hant" reverse:NO];
    return traditionalChinese;
}

/// Convert Traditional Chinese to Simplified Chinese.
- (NSString *)toSimplifiedChineseText {
    NSString *simplifiedChinese = [self stringByApplyingTransform:@"Hant-Hans" reverse:NO];
    return simplifiedChinese;
}

@end
