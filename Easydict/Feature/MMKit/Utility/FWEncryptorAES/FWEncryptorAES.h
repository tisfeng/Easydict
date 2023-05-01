//
//  FWEncryptorAES.h
//  FWEncryptorAES
//
//  Created by FrankWu on 2013/12/20.
//  Copyright (c) 2013年 FrankWu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWEncryptorAES : NSObject

+ (NSData *)encrypt:(NSData *)data Key:(id)key IV:(id)iv;
+ (NSData *)decrypt:(NSData *)data Key:(id)key IV:(id)iv;

+ (NSString *)encryptToBase64:(NSData *)data Key:(id)key IV:(id)iv;
+ (NSData *)decryptFromBase64:(NSString *)data Key:(id)key IV:(id)iv;

+ (NSString *)encryptStrToBase64:(NSString *)str Key:(id)key IV:(id)iv;
+ (NSString *)decryptStrFromBase64:(NSString *)data Key:(id)key IV:(id)iv;

+ (NSData *)getKey:(NSString *)key;
+ (NSData *)getIV:(NSString *)iv;

+ (NSString*)convertHexStringFromData:(NSData*)data;

@end