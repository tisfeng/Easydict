//
//  EZBaiduTranslateResponse.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZBaiduTranslateResponse.h"


@implementation EZBaiduTranslateResponsePart

@end


@implementation EZBaiduTranslateResponseSymbol

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"parts" : EZBaiduTranslateResponsePart.class,
    };
}

@end


@implementation EZBaiduTranslateResponseExchange

@end


@implementation EZBaiduTranslateResponseSimpleMean

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"symbols" : EZBaiduTranslateResponseSymbol.class,
    };
}

@end

@implementation EZBaiduTranslateResponseTags


@end


@implementation EZBaiduTranslateResponseDictResult

@end


@implementation EZBaiduTranslateResponseData

@end


@implementation EZBaiduTranslateResponseTransResult

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"data" : EZBaiduTranslateResponseData.class,
    };
}

@end


@implementation EZBaiduTranslateResponse

@end
