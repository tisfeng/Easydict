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

/// Remove extra LineBreaks.
- (NSString *)removeExtraLineBreaks;

- (NSString *)encode;

- (void)copyToPasteboard;

/// Check if the string is a valid URL. eg. https://www.google.com
- (BOOL)isURL;

// Use NSDataDetector to check if the string is a link. eg. eudic://dict/good
- (BOOL)containsLink;

- (NSString *)md5;

@end

NS_ASSUME_NONNULL_END
