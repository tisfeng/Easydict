//
//  NSString+EZConvenience.m
//  Easydict
//
//  Created by tisfeng on 2023/1/1.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSString+EZConvenience.h"
#import <CommonCrypto/CommonDigest.h>
#import "EZToast.h"

@implementation NSString (EZConvenience)

- (NSString *)trim {
    NSString *trimText = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimText;
}

- (NSString *)trimNewLine {
    NSString *trimText = [self stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return trimText;
}

- (NSString *)trimToMaxLength:(NSUInteger)maxLength {
    NSString *trimText = [self trim];
    if (trimText.length > maxLength) {
        trimText = [self substringToIndex:maxLength];
    }
    return trimText;
}

/// Remove invisible char "\U0000fffc"
- (NSString *)removeInvisibleChar {
    /**
     FIX: Sometimes selected text may contain a Unicode char "\U0000fffc", empty text but length is 1 😢
     
     For example, if getting selected text using shortcut by three click the following text in Wikipedia, the selected text last char is "\U0000fffc"
     
     Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal.
     
     From: https://zh.wikipedia.org/wiki/%E8%93%8B%E8%8C%B2%E5%A0%A1%E6%BC%94%E8%AA%AA#%E6%9E%97%E8%82%AF%E7%9A%84%E8%93%8B%E8%8C%B2%E5%A0%A1%E6%BC%94%E8%AA%AA
     */
    NSString *text = [self stringByReplacingOccurrencesOfString:@"\U0000fffc" withString:@""];
    return text;
}

/// Remove extra LineBreaks.
- (NSString *)removeExtraLineBreaks {
    NSString *regex = @"(\n\\s*){2,}";
    NSString *string = [self stringByReplacingOccurrencesOfString:regex withString:@"\n" options:NSRegularExpressionSearch range:NSMakeRange(0, self.length)];
    return string;
}

/// Just separate by "\n"
- (NSArray<NSString *> *)toParagraphs {
    NSArray *paragraphs = [self componentsSeparatedByString:@"\n"];
    return paragraphs;
}

/// Remove extra line breaks, and separate by "\n"
- (NSArray<NSString *> *)removeExtraLineBreaksAndToParagraphs {
    NSString *text = [self removeExtraLineBreaks];
    NSArray *paragraphs = [text toParagraphs];
    return paragraphs;
}

- (NSString *)encode {
    NSString *encodedText = [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return encodedText;
}

/// Replace \" with &quot;
- (NSString *)escapedHTMLString {
    NSString *escapedHTMLContent = [self stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    return escapedHTMLContent;
}

- (void)copyToPasteboard {
    [NSPasteboard mm_generalPasteboardSetString:self];
}

// ???: Since I found that some other Apps also read and clear NSPasteboard content, it maybe cause write to NSPasteboard failed, such as PopClip will be triggered strangely when I use Silent Screenshot OCR.
- (void)copyToPasteboardSafely {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSPasteboard mm_generalPasteboardSetString:self];
    });
}

- (void)copyAndShowToast:(BOOL)showToast {
    [NSPasteboard mm_generalPasteboardSetString:self];
    if (self.length && showToast) {
        [EZToast showText:@"Copy Success"];
    }
}

/// Check if the string is a valid URL, must has scheme, https://www.google.com
- (BOOL)isURL {
    NSURL *URL = [self detectLink];
    BOOL isURL = URL != nil;
    return isURL;
}

/// Check if the string is a valid URL, must has scheme, https://www.google.com
- (BOOL)isValidURL {
    NSURL *url = [NSURL URLWithString:self];
    if (url && url.scheme && url.host) {
        // 有 scheme 和 host 表示是一个合法的 URL
        return YES;
    } else {
        return NO;
    }
}

/// Check if the string is a valid link, www.google.com
- (BOOL)isLink {
    NSString *urlString = self;
    NSString *urlRegEx = @"(?:https?://)?(?:www\\.)?\\w+\\.[a-z]+(?:/[^\\s]*)?";
    NSPredicate *urlPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlPredicate evaluateWithObject:urlString];
}


// Use NSDataDetector to detect link. eg. eudic://dict/good
- (nullable NSURL *)detectLink {
    NSURL *URL = nil;
    // when detect "qrbtf.com", return "http://qrbtf.com"
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [detector matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    if (matches.count > 0) {
        NSTextCheckingResult *result = matches.firstObject;
        if (result.resultType == NSTextCheckingTypeLink && result.URL && result.range.length == self.length) {
            URL = result.URL;
        }
    }
    return URL;
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



@end
