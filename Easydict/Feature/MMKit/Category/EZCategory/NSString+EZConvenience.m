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

@end
