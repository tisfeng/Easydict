//
//  EZQueryResult+EZYoudaoDictModel.m
//  Easydict
//
//  Created by tisfeng on 2022/12/31.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryResult+EZYoudaoDictModel.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation EZQueryResult (EZYoudaoDictModel)

- (instancetype)setupWithYoudaoDictModel:(EZYoudaoDictModel *)model {
    self.raw = model;
    self.queryText = model.input;
    
    EZTranslateWordResult *wordResult = [[EZTranslateWordResult alloc] init];
    EZLanguage language = self.queryModel.queryFromLanguage;

    if (model.ec) {
        // 解析音频
        NSMutableArray *phoneticArray = [NSMutableArray array];
        EZEcWord *word = model.ec.word.firstObject;
        
        // https://dict.youdao.com/dictvoice?audio=good&type=2
        NSString *aduioURL = @"https://dict.youdao.com/dictvoice?audio=";
        if (word.usphone) {
            EZWordPhonetic *phonetic = [[EZWordPhonetic alloc] init];
            phonetic.name = NSLocalizedString(@"us_phonetic", nil);
            phonetic.language = language;
            phonetic.accent = @"us";
            phonetic.word = self.queryText;
            phonetic.value = word.usphone; // ɡʊd
            // usspeech: "good&type=2"
            NSString *usspeech = [NSString stringWithFormat:@"%@%@", aduioURL, word.usspeech];
            phonetic.speakURL = usspeech;
            [phoneticArray addObject:phonetic];
            
            self.fromSpeakURL = phonetic.speakURL;
            self.queryModel.audioURL = usspeech;
        }
        if (word.ukphone) {
            EZWordPhonetic *phonetic = [[EZWordPhonetic alloc] init];
            phonetic.name = NSLocalizedString(@"uk_phonetic", nil);
            phonetic.language = language;
            phonetic.accent = @"uk";
            phonetic.word = self.queryText;
            phonetic.value = word.ukphone;
            phonetic.speakURL = [NSString stringWithFormat:@"%@%@", aduioURL, word.ukspeech];
            [phoneticArray addObject:phonetic];
        }
        if (phoneticArray.count) {
            wordResult.phonetics = [phoneticArray copy];
        }
        
        NSMutableArray *partArray = [NSMutableArray array];
        [word.trs enumerateObjectsUsingBlock:^(EZWordTr *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            // adj. 好的，优良的；能干的，擅长的；好的，符合心愿的；
            // 行政助理 [administrative assistants]
            NSString *explanation = obj.tr.firstObject.l.i.firstObject;
            
            EZTranslatePart *partObject = [[EZTranslatePart alloc] init];
            NSString *means = explanation;

            NSString *delimiterSymbol = @".";
            NSArray *array = [explanation componentsSeparatedByString:delimiterSymbol];
            if (array.count > 1) {
                NSString *pos = array.firstObject;
                if (pos.length < 5) {
                    partObject.part = [NSString stringWithFormat:@"%@%@", pos, delimiterSymbol];
                    means = [array[1] trim];
                }
            }
            partObject.means = @[ means ];
            
            [partArray addObject:partObject];
        }];
        if (partArray.count) {
            wordResult.parts = [partArray copy];
        }
        
        NSArray<EZWfElement *> *wfs = word.wfs;
        if (wfs.count) {
            NSMutableArray *exchanges = [NSMutableArray array];
            for (EZWfElement *element in wfs) {
                EZTranslateExchange *exchange = [[EZTranslateExchange alloc] init];
                exchange.name = element.wf.name;
                exchange.words = [element.wf.value componentsSeparatedByString:@"或"]; // input或inputted
                [exchanges addObject:exchange];
            }
            if (exchanges.count) {
                wordResult.exchanges = exchanges;
            }
        }
        
        wordResult.tags = model.ec.examType;
    }
    
    if (model.ce) {
        // 解析音频
        NSMutableArray *phoneticArray = [NSMutableArray array];
        EZCeWord *word = model.ce.word.firstObject;
        if (word.phone) {
            EZWordPhonetic *phonetic = [[EZWordPhonetic alloc] init];
            phonetic.word = self.queryText;
            phonetic.language = language;
            phonetic.name = NSLocalizedString(@"chinese_phonetic", nil);
            phonetic.value = word.phone; // ɡʊd
            [phoneticArray addObject:phonetic];
        }
        if (phoneticArray.count) {
            wordResult.phonetics = [phoneticArray copy];
        }
        
        NSMutableArray *wordArray = [NSMutableArray array];
        [word.trs enumerateObjectsUsingBlock:^(EZWordTr *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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
                simpleWord.means = @[ means ];
            }
            simpleWord.showPartMeans = YES;
            [wordArray addObject:simpleWord];
        }];
        if (wordArray.count) {
            wordResult.simpleWords = [wordArray copy];
        }
    }
    
    EZWebTrans *webTrans = model.webTrans;
    if (webTrans) {
        NSMutableArray *webExplanations = [NSMutableArray array];
        for (EZWebTranslation *webTranslation in webTrans.webTranslation) {
            EZTranslateSimpleWord *simpleWord = [[EZTranslateSimpleWord alloc] init];
            simpleWord.word = webTranslation.key;
            
            NSMutableArray *explanations = [NSMutableArray array];
            for (EZTran *trans in webTranslation.trans) {
                [explanations addObject:trans.value];
            }
            simpleWord.means = explanations;
            [webExplanations addObject:simpleWord];
        }
        
        if (webExplanations.count) {
            NSMutableArray *simpleWords = [NSMutableArray arrayWithArray:wordResult.simpleWords];
            wordResult.simpleWords = [simpleWords arrayByAddingObjectsFromArray:webExplanations];
        }
    }
    
    if (model.newhh) {
    }
    
    // 至少要有词义或单词组才认为有单词翻译结果
    if (wordResult.parts || wordResult.simpleWords) {
        self.wordResult = wordResult;
    }
    
    return self;
}

/*
function A (t, o, n) {
    o = "ydsecret://query/key/B*RGygVywfNBwpmBaZg*WT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl"
    n = "ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4"
    if (!t)
        return null;
    const a = CryptoJS.enc.Hex.parse(m(o))
      , r = CryptoJS.enc.Hex.parse(m(n))
      , i = CryptoJS.AES.decrypt(CryptoJS.enc.Base64.parse(t), a, {
        iv: r,
        mode: CryptoJS.mode.CBC,
        padding: CryptoJS.pad.Pkcs7
      });
    let s = i.toString(CryptoJS.enc.Utf8);
    return s
}
*/
// Convert JS function A to objc
- (NSString *)decrypt:(NSString *)text {
    NSString *key = @"B*RGygVywfNBwpmBaZg*WT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl";
    NSString *iv = @"C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4";
    if (!text) {
        return nil;
    }
    NSData *keyData = [self dataFromHexString:key];
    NSData *ivData = [self dataFromHexString:iv];
    NSData *textData = [[NSData alloc] initWithBase64EncodedString:text options:0];
    NSData *decryptedData = [self aesDecrypt:textData key:keyData iv:ivData];
    NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    return decryptedString;
}

- (NSData *)dataFromHexString:(NSString *)string {
    NSMutableData *data = [NSMutableData dataWithCapacity:string.length / 2];
    for (NSInteger i = 0; i < string.length; i += 2) {
        NSString *hex = [string substringWithRange:NSMakeRange(i, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:hex];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

- (NSData *)aesDecrypt:(NSData *)data key:(NSData *)key iv:(NSData *)iv {
    NSMutableData *decryptedData = [NSMutableData dataWithLength:data.length];
    size_t decryptedLength = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          key.bytes,
                                          key.length,
                                          iv.bytes,
                                          data.bytes,
                                          data.length,
                                          decryptedData.mutableBytes,
                                          decryptedData.length,
                                          &decryptedLength);
    if (cryptStatus == kCCSuccess) {
        decryptedData.length = decryptedLength;
    } else {
        decryptedData = nil;
    }
    return decryptedData;
}



@end
