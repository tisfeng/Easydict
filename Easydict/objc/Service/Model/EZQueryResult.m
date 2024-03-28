//
//  EZQueryResult.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryResult.h"
#import "EZLocalStorage.h"
#import "NSArray+EZChineseText.h"
#import "NSString+EZUtils.h"

/**
 Get the abbreviation of the part of speech.
 
 noun -> n.
 pronoun -> pron.
 adjective -> adj.
 verb -> v.
 adverb -> adv.
 preposition -> prep.
 conjunction -> conj.
 interjection -> interj.
 */
NSString *getPartAbbreviation(NSString *part) {
    if (part.length == 0) {
        return @"";
    }
    
    static NSDictionary *partOfSpeechMap = @{
        /**
         传统上，英语中有八个词类：名词、代词、形容词、动词、副词、介词、连词、感叹词。
         而在更前沿的语法研究中，语法学家们分出了更多、更细的词类，如限定词、句首助动词等。
         https://zh.wikipedia.org/wiki/%E8%A9%9E%E9%A1%9E
         */
        
        @"adj." : @[ @"adjective", @"形容词" ], // good, nice, fast
        @"adv." : @[ @"adverb", @"副词" ],      // quickly, well, often
        @"v." : @[ @"verb", @"动词" ],          // run, eat, sleep
        
        /**
         系动词，也称连系动词（Linking verb），是用来辅助主语的动词。 它本身有词义，但不能单独用作谓语，其后必须跟表语，构成系表结构说明主语的状况、性质、特征等情况。
         
         主系表结构
         https://baike.baidu.com/item/%E7%B3%BB%E5%8A%A8%E8%AF%8D/3638954
         */
        @"linkv." : @[ @"linkv", @"linking verb", @"系动词" ], // be (is, am, are, was, were), seem, appear
        
        /**
         助动词的主要语法特征是不能独立充当谓语动词，它在句中的作用是协助主动词构成复杂动词词组，表示各种意义。
         
         新语法把助动词分为三大类：基本助动词（Primary Auxiliary）、情态助动词（Modal Auxiliary）和半助动词（Semi-auxiliary）。 基本助动词（be, do, have）是没有词义的，而情态助动词（如 can，may，must, will, etc） 和半助动词（如 have to, be to, be likely to, etc）则是有词义的。
         
         其所以叫做“情态助动词”是由于它本身能表示情态意义，以示区别于那些没有词义的基本助动词。如果说它们是“情态动词”，又说这种动词之后要跟动词原形，似难以自圆其说。
         https://www.zhihu.com/question/31379646/answer/1726732719
         */
        @"auxv." : @[ @"auxv", @"auxiliary verb", @"助动词" ], // be, do, have
        @"modalv." : @[ @"modalv", @"modal verb", @"情态动词" ], // can, must, should
        
        @"n." : @[ @"noun", @"名词" ],                // book, cat, house
        @"pron." : @[ @"pronoun", @"代词" ],          // I, you, he/she
        @"prep." : @[ @"preposition", @"介词" ],      // in, on, at
        @"conj." : @[ @"conjunction", @"连词" ],      // and, but, or
        @"int." : @[ @"int", @"感叹词" ],             // wow, oh, hey（Bing，有道，百度）
        @"interj." : @[ @"interjection", @"感叹词" ], // wow, oh, hey（谷歌）
        
        /**
         限定词是在名词词组中对名词中心词起特指、类指以及表示确定数量和非确定数量等限定作用的词类。名词词组除有词汇意义外，还有其所指意义，是特指还是类指（即泛指一类人或物），是有确定的数量还是没有确定的数量。能在名词词组中表示这种所指意义的词类就是限定词。
         https://baike.baidu.com/item/%E9%99%90%E5%AE%9A%E8%AF%8D/9227027
         
         - 冠词：the, a/an
         - 指示性限定词：this, that, these, those
         - 形容词性的物主代词限定词：my, your, his, her, its, our, their
         - 疑问限定词：which, whose, what
         - 分配式限定词：each, every, either
         https://zhuanlan.zhihu.com/p/347655024
         */
        @"det." : @[ @"determinative", @"限定词" ], // the, a/an, this
        /**
         冠词是一种特殊的限定词，用来具体化或泛化名词。英语中的冠词分为定冠词和不定冠词两种：
         
         定冠词包括 "the"，用于特指某个特定的事物或人，例如："the book"（那本书）。
         不定冠词包括 "a" 和 "an"，用于泛指一个事物或人，例如："a book"（一本书）。
         */
        @"art." : @[ @"article", @"冠词" ], // the, a/an
        
        @"abbr." : @[ @"abbreviation", @"缩写" ], // etc., Mr., Jan.
        @"inf." : @[ @"infinitive", @"不定词" ],  // to + verb (to go, to eat)
        @"part." : @[ @"participle", @"分词" ],   // eating, played, seen
        @"num." : @[ @"numeral", @"数词" ],       // one, two, hundred
        @"Web" : @[ @"Web", @"网络" ]             // HTML, JavaScript, CSS
    };
    
    NSString *partName = nil;
    
    for (NSString *key in partOfSpeechMap) {
        NSArray *values = partOfSpeechMap[key];
        if ([values containsObject:part]) {
            partName = key;
            break;
        } else {
            BOOL stop = NO;
            for (NSString *value in values) {
                if ([value hasPrefix:part]) {
                    partName = key;
                    stop = YES;
                    break;
                }
            }
            if (stop) {
                break;
            }
        }
    }
    
    if (!partName) {
        if ([part isEnglishWord]) {
            /**
             Some special part in Bing:
             
             infinmarker(infinitive marker): to
             defa(definite article): the
             na(indefinite article): a
             */
            partName = [NSString stringWithFormat:@"%@.", part];
        } else {
            partName = part;
        }
    }
    
    return partName;
}


@implementation EZWordPhonetic : NSObject

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

@end


@implementation EZTranslatePart : NSObject

- (void)setPart:(NSString *)part {
    _part = getPartAbbreviation(part);
}

@end


@implementation EZTranslateExchange : NSObject

@end


@implementation EZTranslateSimpleWord : NSObject

- (void)setPart:(NSString *)part {
    _part = getPartAbbreviation(part);
}

- (NSString *)meansText {
    if (!_meansText) {
        _meansText = [self.means componentsJoinedByString:@"; "] ?: @"";
    }
    return _meansText;
}

- (void)setShowPartMeans:(BOOL)showPartMeans {
    _showPartMeans = showPartMeans;
    
    if (showPartMeans) {
        NSString *pos = self.part ? [NSString stringWithFormat:@"%@  ", self.part] : @"";
        NSString *partMeansText = [NSString stringWithFormat:@"%@%@", pos, self.meansText];
        self.meansText = partMeansText;
    }
}

@end


@implementation EZTranslateWordResult

@end


@implementation EZQueryResult

- (instancetype)init {
    if (self = [super init]) {
        [self reset];
        self.webViewManager = [[EZWebViewManager alloc] init];
    }
    return self;
}

- (nullable NSString *)translatedText {
    NSString *text = [self.translatedResults componentsJoinedByString:@"\n"];
    return text;
}

- (BOOL)hasShowingResult {
    if (self.hasTranslatedResult || self.error || self.HTMLString.length) {
        return YES;
    }
    return NO;
}

- (BOOL)hasTranslatedResult {
    if (self.wordResult || self.translatedText || self.HTMLString.length) {
        return YES;
    }
    return NO;
}

- (BOOL)isWarningErrorType {
    EZErrorType errorType = self.error.type;
    BOOL warningType = (errorType == EZErrorTypeUnsupportedLanguage)
    || (errorType == EZErrorTypeNoResultsFound)
    || (errorType == EZErrorTypeInsufficientQuota);
    return warningType;
}

- (nullable NSString *)copiedText {
    if (!self.HTMLString.length) {
        return self.translatedText;
    }
    return _copiedText;
}

- (EZLanguage)queryFromLanguage {
    return self.queryModel.queryFromLanguage;
}

- (void)reset {
    self.queryModel = [[EZQueryModel alloc] init];
    self.translatedResults = nil;
    self.wordResult = nil;
    self.error = nil;
    self.serviceType = EZServiceTypeYoudao;
    [self.service.audioPlayer stop];
    self.service = nil;
    self.isShowing = NO;
    self.isLoading = NO;
    self.viewHeight = 0;
    self.queryText = @"";
    self.from = EZLanguageAuto;
    self.to = EZLanguageAuto;
    self.toSpeakURL = nil;
    self.fromSpeakURL = nil;
    self.raw = nil;
    self.promptTitle = nil;
    self.promptURL = nil;
    self.showBigWord = NO;
    self.translateResultsTopInset = 0;
    self.isFinished = YES;
    self.manulShow = NO;
    self.HTMLString = nil;
    self.copiedText = nil;
    self.didFinishLoadingHTMLBlock = nil;
    [self.webViewManager reset];
    self.showReplaceButton = NO;
}

- (void)convertToTraditionalChineseResult {
    self.translatedResults = [self.translatedResults toTraditionalChineseTexts];
}

@end
