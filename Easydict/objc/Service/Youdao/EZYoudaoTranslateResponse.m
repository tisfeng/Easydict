//
//  EZYoudaoTranslateResponse.m
//  Easydict
//
//  Created by tisfeng on 2022/12/1.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZYoudaoTranslateResponse.h"

@implementation EZYoudaoTranslateResponseWeb

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"value" : NSString.class,
    };
}

@end


@implementation EZYoudaoTranslateResponseBasic

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"explains" : NSString.class,
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"us_phonetic" : @"us-phonetic",
        @"uk_phonetic" : @"uk-phonetic",
        @"us_speech" : @"us-speech",
        @"uk_speech" : @"uk-speech",
    };
}

@end


@implementation EZYoudaoTranslateResponse

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"translation" : NSString.class,
        @"web" : EZYoudaoTranslateResponseWeb.class,
    };
}

@end
