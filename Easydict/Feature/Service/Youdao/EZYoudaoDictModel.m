//
//  EZYoudaoDictModel.m
//  Easydict
//
//  Created by tisfeng on 2022/12/31.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZYoudaoDictModel.h"

@implementation EZYoudaoDictModel

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"webTrans" : @"web_trans",
    };
}

@end


@implementation EZBaike

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"summarys" : [EZSummaryElement class],
    };
}

@end


@implementation EZEc

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"word" : [EZEcWord class],
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"examType" : @"exam_type",
    };
}

@end


@implementation EZEcWord

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"trs" : [EZWordTr class],
        @"wfs" : [EZWfElement class],
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"returnPhrase" : @"return-phrase",
    };
}

@end


@implementation EZWordTr

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"tr" : [EZTrTr class],
    };
}

@end


@implementation EZSimple

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"word" : [EZSimpleWord class],
    };
}

@end


@implementation EZWebTrans

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"webTranslation" : [EZWebTranslation class],
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"webTranslation" : @"web-translation",
    };
}

@end


@implementation EZWebTranslation

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"trans" : [EZTran class],
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"keySpeech" : @"key-speech",
        @"same" : @"@same",
    };
}

@end

@implementation EZSimpleWord

@end


@implementation EZSummaryElement

@end


@implementation EZTrTr

@end

@implementation EZTran

@end

@implementation EZWfElement

@end
