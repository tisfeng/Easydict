//
//  EZQueryResult+EZYoudaoDictModel.m
//  Easydict
//
//  Created by tisfeng on 2022/12/31.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryResult+EZYoudaoDictModel.h"

@implementation EZQueryResult (EZYoudaoDictModel)

- (instancetype)setupWithYoudaoDictModel:(EZYoudaoDictModel *)model {
    self.raw = model;
    self.text = model.input;

    EZTranslateWordResult *wordResult = [[EZTranslateWordResult alloc] init];

    if (model.ec) {
        // 解析音频
        NSMutableArray *phoneticArray = [NSMutableArray array];
        EZEcWord *word = model.ec.word.firstObject;
        
        // https://dict.youdao.com/dictvoice?audio=good&type=2
        NSString *aduioURL = @"https://dict.youdao.com/dictvoice?audio=";
        if (word.usphone) {
            EZTranslatePhonetic *phonetic = [[EZTranslatePhonetic alloc] init];
            phonetic.name = NSLocalizedString(@"us_phonetic", nil);
            phonetic.value = word.usphone; // ɡʊd
            // usspeech: "good&type=2"
            phonetic.speakURL = [NSString stringWithFormat:@"%@%@", aduioURL, word.usspeech];
            [phoneticArray addObject:phonetic];
        }
        if (word.ukphone) {
            EZTranslatePhonetic *phonetic = [[EZTranslatePhonetic alloc] init];
            phonetic.name = NSLocalizedString(@"uk_phonetic", nil);
            phonetic.value = word.ukphone;
            phonetic.speakURL = [NSString stringWithFormat:@"%@%@", aduioURL, word.ukspeech];
            [phoneticArray addObject:phonetic];
        }
        if (phoneticArray.count) {
            wordResult.phonetics = [phoneticArray copy];
        }
        
        NSMutableArray *partArray = [NSMutableArray array];
        [word.trs enumerateObjectsUsingBlock:^(EZWordTr * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *explanation = obj.tr.firstObject.l.i.firstObject;
            EZTranslatePart *part = [EZTranslatePart new];
            part.means = @[ explanation ];
            [partArray addObject:part];
        }];
        if (partArray.count) {
            wordResult.parts = partArray.copy;
        }
        
        // 至少要有词义或单词组才认为有单词翻译结果
        if (wordResult.parts || wordResult.simpleWords) {
            self.wordResult = wordResult;
        }
    }
    
    if (model.ce) {
        // 解析音频
        NSMutableArray *phoneticArray = [NSMutableArray array];
        EZCeWord *word = model.ce.word.firstObject;
        if (word.phone) {
            EZTranslatePhonetic *phonetic = [[EZTranslatePhonetic alloc] init];
            phonetic.name = NSLocalizedString(@"chinese_phonetic", nil);
            phonetic.value = word.phone; // ɡʊd
            [phoneticArray addObject:phonetic];
        }
        if (phoneticArray.count) {
            wordResult.phonetics = [phoneticArray copy];
        }
        
        NSMutableArray *partArray = [NSMutableArray array];
        [word.trs enumerateObjectsUsingBlock:^(EZWordTr * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            EZTrL *l = obj.tr.firstObject.l;
            NSMutableArray *words = [NSMutableArray array];
            for (NSDictionary *wordDict in l.i) {
                if ([wordDict isKindOfClass:[NSDictionary class]]) {
                    EZTextWord *textWord = [EZTextWord mj_objectWithKeyValues:wordDict];
                    [words addObject:textWord];
                }
            }
            
            NSMutableArray *texts = [NSMutableArray array];
            for (EZTextWord *word in words) {
                [texts addObject:word.text];
            }
            NSString *text = [texts componentsJoinedByString:@" "];
            
            EZTranslatePart *partObject = [EZTranslatePart new];
            partObject.part = text;
            partObject.means = @[l.tran];
            
            [partArray addObject:partObject];
        }];
        if (partArray.count) {
            wordResult.parts = partArray.copy;
        }
        
        // 至少要有词义或单词组才认为有单词翻译结果
        if (wordResult.parts || wordResult.simpleWords) {
            self.wordResult = wordResult;
        }
        
    }
    
    if (model.newhh) {
        
    }
    
    return self;
}

+ (instancetype)resultWithYoudaoDictModel:(EZYoudaoDictModel *)model {
    EZQueryResult *result = [[EZQueryResult alloc] init];
    result.text = model.input;
    result.raw = model;
    
    @try {
        EZTranslateWordResult *wordResult = [[EZTranslateWordResult alloc] init];

        if (model.ec) {
            // 解析音频
            NSMutableArray *phoneticArray = [NSMutableArray array];
            EZEcWord *word = model.ec.word.firstObject;
            
           // https://dict.youdao.com/dictvoice?audio=good&type=2
            NSString *aduioURL = @"https://dict.youdao.com/dictvoice?audio=";
            if (word.usphone) {
                EZTranslatePhonetic *phonetic = [[EZTranslatePhonetic alloc] init];
                phonetic.name = NSLocalizedString(@"us_phonetic", nil);
                phonetic.value = word.usphone; // ɡʊd
                // usspeech: "good&type=2"
                phonetic.speakURL = [NSString stringWithFormat:@"%@%@", aduioURL, word.usspeech];
                [phoneticArray addObject:phonetic];
            }
            if (word.ukphone) {
                EZTranslatePhonetic *phonetic = [[EZTranslatePhonetic alloc] init];
                phonetic.name = NSLocalizedString(@"uk_phonetic", nil);
                phonetic.value = word.ukphone;
                phonetic.speakURL = [NSString stringWithFormat:@"%@%@", aduioURL, word.ukspeech];
                [phoneticArray addObject:phonetic];
            }
            if (phoneticArray.count) {
                wordResult.phonetics = [phoneticArray copy];
            }
            
            NSMutableArray *partArray = [NSMutableArray array];
            [word.trs enumerateObjectsUsingBlock:^(EZWordTr * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *explanation = obj.tr.firstObject.l.i.firstObject;
                EZTranslatePart *part = [EZTranslatePart new];
                part.means = @[ explanation ];
                [partArray addObject:part];
            }];
            if (partArray.count) {
                wordResult.parts = partArray.copy;
            }
            
            // 至少要有词义或单词组才认为有单词翻译结果
            if (wordResult.parts || wordResult.simpleWords) {
                result.wordResult = wordResult;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"parse Youdao dict error");
    }
    
    return result;
}

@end
