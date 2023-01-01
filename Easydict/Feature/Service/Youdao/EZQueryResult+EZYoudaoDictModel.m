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
            // adj. 好的，优良的；能干的，擅长的；好的，符合心愿的；
            NSString *explanation = obj.tr.firstObject.l.i.firstObject;
                        
            NSArray *array = [explanation componentsSeparatedByString:@"."];
            NSString *pos = array.firstObject;
            NSString *means = explanation;

            EZTranslatePart *partObject = [[EZTranslatePart alloc] init];
            if (pos.length < 5) {
                partObject.part = [NSString stringWithFormat:@"%@.", pos];
                array = [array subarrayWithRange:NSMakeRange(1, array.count - 1)];
                means = [[array componentsJoinedByString:@"."] trim];
            }
            partObject.means = @[ means ];
            
            [partArray addObject:partObject];
        }];
        if (partArray.count) {
            wordResult.parts = [partArray copy];
        }
        
        // 至少要有词义或单词组才认为有单词翻译结果
        if (wordResult.parts || wordResult.simpleWords) {
            self.wordResult = wordResult;
        }
        
        NSArray<EZWfElement *> *wfs = word.wfs;
        if (wfs.count) {
            NSMutableArray *exchanges = [NSMutableArray array];
            for (EZWfElement *element in wfs) {
                EZTranslateExchange *exchange = [[EZTranslateExchange alloc] init];
                exchange.name = element.wf.name;
                exchange.words = @[element.wf.value];
                [exchanges addObject:exchange];
            }
            
            if (exchanges.count) {
                self.wordResult.exchanges = exchanges;
            }
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
        
        NSMutableArray *wordArray = [NSMutableArray array];
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
            
            EZTranslateSimpleWord *simpleWord = [[EZTranslateSimpleWord alloc] init];
            simpleWord.word = text;
            simpleWord.part = l.pos;
            NSString *means = l.tran;
            if (means) {
                simpleWord.means = @[means];
            }
            simpleWord.showPartMeans = YES;
            [wordArray addObject:simpleWord];
        }];
        if (wordArray.count) {
            wordResult.simpleWords = [wordArray copy];
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


@end
