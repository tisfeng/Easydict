//
//  BaiduTranslateResponse.m
//  Bob
//
//  Created by ripper on 2019/11/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "BaiduTranslateResponse.h"

@implementation BaiduTranslateResponsePart

@end

@implementation BaiduTranslateResponseSymbol

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"parts": BaiduTranslateResponsePart.class,
    };
}

@end

@implementation BaiduTranslateResponseExchange

@end

@implementation BaiduTranslateResponseSimpleMean

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"symbols": BaiduTranslateResponseSymbol.class,
    };
}

@end

@implementation BaiduTranslateResponseDictResult

@end

@implementation BaiduTranslateResponseData

@end

@implementation BaiduTranslateResponseTransResult

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"data" : BaiduTranslateResponseData.class,
    };
}

@end

@implementation BaiduTranslateResponse

@end
