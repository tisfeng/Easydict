//
//  EZNiuTransTranslateResponse.m
//  Easydict
//
//  Created by BigGuang97 on 2023/11/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZNiuTransTranslateResponse.h"

@implementation EZNiuTransTranslateResponse

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"srcText" : @"src_text",
        @"tgtText" : @"tgt_text",
        @"errorMsg" : @"error_msg",
        @"errorCode" : @"error_code",
    };
}

@end
