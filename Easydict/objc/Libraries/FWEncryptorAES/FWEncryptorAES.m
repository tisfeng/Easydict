//
//  FWEncryptorAES.m
//  FWEncryptorAES
//
//  Created by FrankWu on 2013/12/20.
//  Copyright (c) 2013年 FrankWu. All rights reserved.
//

#import "FWEncryptorAES.h"
#import "NSData+CommonCrypto.h"
#import "NSData+Base64.h"

@implementation FWEncryptorAES

+ (NSData *)encrypt:(NSData *)data Key:(id)key IV:(id)iv
{
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert([iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSData *keyData = [self getKey:key];
    NSData *ivData = [self getIV:iv];
    
    CCCryptorStatus status = kCCSuccess;
    NSData *encrypted = [data dataEncryptedUsingAlgorithm:kCCAlgorithmAES128 key:keyData initializationVector:ivData options:kCCOptionPKCS7Padding error:&status];
    
    return encrypted;
}

+ (NSData *)decrypt:(NSData *)data Key:(id)key IV:(id)iv
{
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert([iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSData *keyData = [self getKey:key];
    NSData *ivData = [self getIV:iv];
    
    CCCryptorStatus status = kCCSuccess;
    NSData *decrypted = [data decryptedDataUsingAlgorithm:kCCAlgorithmAES128 key:keyData initializationVector:ivData options:kCCOptionPKCS7Padding error:&status];
    
    return decrypted;
}

+ (NSString *)encryptToBase64:(NSData *)data Key:(id)key IV:(id)iv
{
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert([iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSData *encrypted = [self encrypt:data Key:key IV:iv];
    return [encrypted base64EncodedString];
}

+ (NSData *)decryptFromBase64:(NSString *)str Key:(id)key IV:(id)iv
{
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert([iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSData *data = [NSData dataFromBase64String:str];
    return [self decrypt:data Key:key IV:iv];
}

+ (NSString *)encryptStrToBase64:(NSString *)str Key:(id)key IV:(id)iv
{
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert([iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return [self encryptToBase64:data Key:key IV:iv];
}

+ (NSString *)decryptStrFromBase64:(NSString *)str Key:(id)key IV:(id)iv
{
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert([iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSData *data = [NSData dataFromBase64String:str];
    NSData *decrypted = [self decrypt:data Key:key IV:iv];
    return [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
}

+ (NSData *)getKey:(id)key
{
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
    
    if ([key isKindOfClass: [NSString class]])
        return [[key dataUsingEncoding:NSUTF8StringEncoding] SHA256Hash];
	else
		return (NSData *)key;
}

+ (NSData *)getIV:(id)iv
{
	NSParameterAssert([iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    if ([iv isKindOfClass: [NSString class]])
        return [[iv dataUsingEncoding:NSUTF8StringEncoding] MD5Sum];
	else
		return (NSData *)iv;
}

+ (NSString*)convertHexStringFromData:(NSData*)data
{
    const unsigned char *result = [data bytes];
    NSMutableString *str = [NSMutableString stringWithCapacity:[data length]];
    for(int i = 0; i<[data length]; i++)
    {
        [str appendFormat:@"%02x",result[i]];
    }
    return str;
}


#pragma mark -

+ (NSString *)encryptText:(NSString *)text key:(NSString *)key {
    return [self encryptText:text key:key iv:nil];
}
+ (NSString *)decryptText:(NSString *)cipherText key:(NSString *)key {
    return [self decryptText:cipherText key:key iv:nil];
}

+ (NSString *)encryptText:(NSString *)text key:(NSString *)key iv:(nullable NSString *)iv {
    NSData *keyData = [[key dataUsingEncoding:NSUTF8StringEncoding] SHA256Hash];
    NSData *ivData = [[iv dataUsingEncoding:NSUTF8StringEncoding] MD5Sum];
    
    return [self encryptAES:text key:keyData iv:ivData];
}

+ (NSString *)decryptText:(NSString *)cipherText key:(NSString *)key iv:(nullable NSString *)iv {
    NSData *keyData = [[key dataUsingEncoding:NSUTF8StringEncoding] SHA256Hash];
    NSData *ivData = [[iv dataUsingEncoding:NSUTF8StringEncoding] MD5Sum];
    
    return [self decryptAES:cipherText key:keyData iv:ivData];
}


+ (nullable NSString *)decryptAES:(NSString *)cipherText key:(NSData *)key iv:(nullable NSData *)iv {
    NSData *cipherData = [[NSData alloc] initWithBase64EncodedString:cipherText options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSMutableData *decryptedData = [NSMutableData dataWithLength:[cipherData length] + kCCBlockSizeAES128];
    size_t decryptedLength = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [key bytes],
                                          [key length],
                                          [iv bytes],
                                          [cipherData bytes],
                                          [cipherData length],
                                          [decryptedData mutableBytes],
                                          [decryptedData length],
                                          &decryptedLength);
    if (cryptStatus == kCCSuccess) {
        [decryptedData setLength:decryptedLength];
        NSString *decryptedText = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
        return decryptedText;
    }
    
    return nil;
}

/// encrypt AES
+ (NSString *)encryptAES:(NSString *)text key:(NSData *)key iv:(NSData *)iv {
    NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *encryptedData = [NSMutableData dataWithLength:[textData length] + kCCBlockSizeAES128];
    size_t encryptedLength = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          [key bytes],
                                          [key length],
                                          [iv bytes],
                                          [textData bytes],
                                          [textData length],
                                          [encryptedData mutableBytes],
                                          [encryptedData length],
                                          &encryptedLength);
    if (cryptStatus == kCCSuccess) {
        [encryptedData setLength:encryptedLength];
        NSString *encryptedText = [encryptedData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        return encryptedText;
    }
    
    return nil;
}

@end
