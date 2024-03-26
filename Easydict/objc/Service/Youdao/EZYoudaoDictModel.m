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

- (id)mj_newValueFromOldValue:(id)oldValue property:(MJProperty *)property {
    if ([property.name isEqualToString:@"i"]) {
        NSMutableArray *textWords = [NSMutableArray array];
        for (id obj in oldValue) {
            if ([obj isEqualToString:@""]) {
                continue;
            }
            EZTextWord *textWord = [EZTextWord mj_objectWithKeyValues:obj];
            [textWords addObject:textWord];
        }
        return textWords;
    }

    return oldValue;
}

@end

@implementation EZTran

@end

@implementation EZWfElement

@end


@implementation EZWfWf

@end

@implementation EZTrL

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"tran" : @"#tran",
    };
}

@end


@implementation EZTextWord

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"action" : @"@action",
        @"href" : @"@href",
        @"text" : @"#text",
    };
}

@end


@implementation EZCe

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"word" : [EZCeWord class],
    };
}

@end

@implementation EZCeWord

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"trs" : [EZWordTr class],
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"returnPhrase" : @"return-phrase",
    };
}

@end

@implementation EZNewhh

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"dataList" : [EZDataList class],
    };
}

@end

@implementation EZDataList

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"sense" : [EZSense class],
    };
}

@end

@implementation EZSense

+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"subsense" : [EZSubsense class],
    };
}

@end

@implementation EZSubsense

@end

@implementation EZNewhhSource

@end
