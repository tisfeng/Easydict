//
//  EZQueryResult.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryResult.h"
#import "EZLocalStorage.h"

NSString *const EZServiceTypeGoogle = @"Google";
NSString *const EZServiceTypeBaidu = @"Baidu";
NSString *const EZServiceTypeYoudao = @"Youdao";
NSString *const EZServiceTypeApple = @"Apple";
NSString *const EZServiceTypeDeepL = @"DeepL";
NSString *const EZServiceTypeVolcano = @"Volcano";


/// Convert part
/**
 adjective -> adj.
    adverb -> adv.
    verb -> v.
    noun -> n.
    pronoun -> pron.
    preposition -> prep.
    conjunction -> conj.
    interjection -> interj.
 */
NSString *getPartName(NSString *part) {
    NSDictionary *dict = @{
        @"adjective" : @"adj.",
        @"adverb" : @"adv.",
        @"verb" : @"v.",
        @"noun" : @"n.",
        @"pronoun" : @"pron.",
        @"preposition" : @"prep.",
        @"conjunction" : @"conj.",
        @"interjection" : @"interj.",
    };
    
    NSString *partName = dict[part];
    if (!partName) {
        partName = part;
    }
    
    return partName;
}


@implementation EZTranslatePhonetic : NSObject

@end


@implementation EZTranslatePart : NSObject

- (void)setPart:(NSString *)part {
    _part = getPartName(part);
}

@end


@implementation EZTranslateExchange : NSObject

@end


@implementation EZTranslateSimpleWord : NSObject

- (void)setPart:(NSString *)part {
    _part = getPartName(part);
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
    }
    return self;
}

- (NSString *)translatedText {
    NSString *text = [self.normalResults componentsJoinedByString:@"\n"] ?: @"";
    return text;
}

- (BOOL)isEmpty {
    if (!self.wordResult && self.translatedText.length == 0 && !self.error) {
        return YES;
    }
    return NO;
}

- (BOOL)hasResult {
    if (self.isEmpty == NO || self.error != nil) {
        return YES;
    }
    return NO;
}

- (void)reset {
    self.queryModel = [[EZQueryModel alloc] init];
    self.normalResults = nil;
    self.wordResult = nil;
    self.error = nil;
    self.serviceType = EZServiceTypeBaidu;
    self.service = nil;
    self.isShowing = NO;
    self.viewHeight = 0;
    self.text = @"";
    self.from = EZLanguageAuto;
    self.to = EZLanguageAuto;
    self.toSpeakURL = nil;
    self.fromSpeakURL = nil;
    self.raw = nil;
}

@end
