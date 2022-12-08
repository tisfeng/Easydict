//
//  SSUtils.m
//  SSWKURLDemo
//
//  Created by sgcy on 2021/1/21.
//  Copyright © 2021 sgcy. All rights reserved.
//

#import "SSUtils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation SSUtils

+ (NSString *)requestIdForRequest:(NSURLRequest *)request
{
    NSString *url = request.URL.absoluteString;
    NSDictionary *headers = request.allHTTPHeaderFields;
    if (headers) {
        if ([NSJSONSerialization isValidJSONObject:headers]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:headers options:1 error:nil];
            if (jsonData) {
                NSString *str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//                url = [url stringByAppendingString:str];
            }
        }
    }
    if (request.HTTPBody) {
        //POST BODY?
    }
    return [self md5:url];
}

+ (NSString *)md5:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02X", digest[i]];
    }
    return result;
}


@end
