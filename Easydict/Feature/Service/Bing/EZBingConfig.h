//
//  EZBingConfig.h
//  Easydict
//
//  Created by tisfeng on 2023/9/5.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZBingHost = @"www.bing.com";
static NSString *const EZBingChinaHost = @"cn.bing.com";

/**
@interface BingConfig {
   IG: string; // F4D70DC299D549CE824BFCD7506749E7
   IID: string; // translator.5023
   key: string; // key is timestamp: 1663381745198
   token: string; // -2ptk6FgbTk2jgZWATe8L_VpY9A_niur
   expirationInterval: string; // 3600000, 10 min
   count: number; // current token request count, default is 1.
 }
 */
@interface EZBingConfig : NSObject

@property (nonatomic, copy, nullable) NSString *IG;
@property (nonatomic, copy, nullable) NSString *IID;
@property (nonatomic, copy, nullable) NSString *key;
@property (nonatomic, copy, nullable) NSString *token;
@property (nonatomic, copy, nullable) NSString *expirationInterval;

@property (nonatomic, copy, nullable) NSString *cookie;

@property (nonatomic, copy, nullable) NSString *host; // www.bing.com, or cn.bing.com

@property (nonatomic, copy) NSString *translatorURLString;
@property (nonatomic, copy) NSString *ttranslatev3URLString;
@property (nonatomic, copy) NSString *tlookupv3URLString;
@property (nonatomic, copy) NSString *tfetttsURLString;
@property (nonatomic, copy) NSString *dictTranslateURLString;

- (BOOL)isBingTokenExpired;

- (void)resetToken;

@end

NS_ASSUME_NONNULL_END
