//
//  EZBingConfig.m
//  Easydict
//
//  Created by tisfeng on 2023/9/5.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZBingConfig.h"

@implementation EZBingConfig

- (NSString *)translatorURLString {
    return [NSString stringWithFormat:@"https://%@/translator", self.host];
}

- (NSString *)ttranslatev3URLString {
    return [self urlStringWithPath:@"ttranslatev3"];
}

- (NSString *)tlookupv3URLString {
    return [self urlStringWithPath:@"tlookupv3"];
}

- (NSString *)tfetttsURLString {
    return [self urlStringWithPath:@"tfettts"];
}

- (NSString *)urlStringWithPath:(NSString *)path {
    NSString *urlString = [NSString stringWithFormat:@"https://%@/%@?isVertical=1&IG=%@&IID=%@", self.host, path, self.IG, self.IID];
    return urlString;
}

- (NSString *)dictTranslateURLString {
    return [NSString stringWithFormat:@"https://%@/api/v7/dictionarywords/search?appid=371E7B2AF0F9B84EC491D731DF90A55719C7D209&mkt=zh-cn&pname=bingdict", self.host];
}

- (NSString *)cookie {
    NSString *cookie = [NSUserDefaults mm_readString:EZBingCookieKey defaultValue:@""];
    return cookie;
}

#pragma mark -

- (BOOL)isBingTokenExpired {
    if (self.token == nil) {
        return YES;
    }
    
    NSTimeInterval tokenStart = self.key.doubleValue;
    
    // Conver to millisecond
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000;

    /**
     expirationInterval is 3600000 ms, 3600000/1000/60 = 60 mins
     
     Default expiration is 60 mins, for better experience, we get a new token after 30 min.
     */
    NSTimeInterval tokenUsedTime = now - tokenStart;
    BOOL isExpired = tokenUsedTime > self.expirationInterval.doubleValue / 2;
    NSLog(@"is Bing token expired: %@", isExpired ? @"YES" : @"NO");
    
    return isExpired;
}

- (void)resetToken {
    self.IID = nil;
    self.IG = nil;
    self.key = nil;
    self.expirationInterval = nil;
    self.token = nil;
}

@end
