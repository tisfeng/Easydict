//
//  NSData+EZMD5.m
//  Easydict
//
//  Created by tisfeng on 2023/5/2.
//  Copyright © 2023 izual. All rights reserved.
//

#import "NSData+EZMD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (EZMD5)

//- (NSString *)md5 {
//    unsigned char digest[CC_MD5_DIGEST_LENGTH];
//
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    CC_MD5(self.bytes, (CC_LONG)self.length, digest);
//#pragma clang diagnostic pop
//
//    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
//    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
//        [result appendFormat:@"%02x", digest[i]];
//    }
//    return result;
//}

- (NSData *)md5 {
    unsigned char hash[CC_MD5_DIGEST_LENGTH];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5([self bytes], (CC_LONG)[self length], hash);
#pragma clang diagnostic pop
    
    return [NSData dataWithBytes:hash length:CC_MD5_DIGEST_LENGTH];
}

@end
