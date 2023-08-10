//
//  NSString+EZConvenience.h
//  Easydict
//
//  Created by tisfeng on 2023/1/1.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (EZConvenience)

- (NSString *)trim;

- (NSString *)trimNewLine;

- (NSString *)trimToMaxLength:(NSUInteger)maxLength;

/// Remove invisible char "\U0000fffc"
- (NSString *)removeInvisibleChar;

/// Remove extra LineBreaks.
- (NSString *)removeExtraLineBreaks;

/// Just separate by "\n"
- (NSArray<NSString *> *)toParagraphs;

/// Remove extra line breaks, and separate by "\n"
- (NSArray<NSString *> *)removeExtraLineBreaksAndToParagraphs;


- (NSString *)encode;

/// Replace \" with &quot;
- (NSString *)escapedHTMLString;


- (void)copyToPasteboard;
- (void)copyToPasteboardSafely;

- (void)copyAndShowToast:(BOOL)showToast;

/// Check if the string is a valid URL. eg. https://www.google.com
- (BOOL)isURL;

/// Check if the string is a valid link, www.google.com
- (BOOL)isLink;

// Use NSDataDetector to detect link. eg. eudic://dict/good
- (nullable NSURL *)detectLink;

- (NSString *)md5;

@end

NS_ASSUME_NONNULL_END
