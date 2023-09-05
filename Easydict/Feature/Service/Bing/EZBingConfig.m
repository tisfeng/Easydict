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

#pragma mark -

- (BOOL)isBingTokenExpired {
    if (self.token == nil) {
        return YES;
    }
    
    NSTimeInterval tokenStartTime = self.key.doubleValue;
    
    // Conver to millisecond
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000;
    
    // Default expiration is 10 min, for better experience, we get a new token after 5 min.
    NSTimeInterval tokenUsedTime = now - tokenStartTime;
    BOOL isExpired = tokenUsedTime > self.expirationInterval.doubleValue / 2;
    return isExpired;
}

- (void)resetToken {
    self.IID = nil;
    self.IG = nil;
    self.key = nil;
    self.expirationInterval = nil;
}

@end
