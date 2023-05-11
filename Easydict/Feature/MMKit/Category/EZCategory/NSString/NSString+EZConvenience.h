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

- (NSString *)trimToMaxLength:(NSUInteger)maxLength;

/// Remove invisible char "\U0000fffc"
- (NSString *)removeInvisibleChar;

/// Remove extra LineBreaks.
- (NSString *)removeExtraLineBreaks;

/// Convert joined string to paragraphs, remove extra line breaks.
- (NSArray<NSString *> *)toParagraphs;


- (NSString *)encode;

- (void)copyToPasteboard;

- (void)copyAndShowToast:(BOOL)showToast;

/// Check if the string is a valid URL. eg. https://www.google.com
- (BOOL)isURL;

// Use NSDataDetector to check if the string is a link. eg. eudic://dict/good
- (BOOL)containsLink;

- (NSString *)md5;

@end

NS_ASSUME_NONNULL_END
