//
//  EZQueryResult.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryResult.h"
#import "EZLocalStorage.h"



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

- (BOOL)hasShowingResult {
    if (self.hasTranslatedResult || self.error || self.errorMessage.length) {
        return YES;
    }
    return NO;
}

- (BOOL)hasTranslatedResult {
    if (self.wordResult || self.translatedText.length) {
        return YES;
    }
    return NO;
}

- (void)reset {
    self.queryModel = [[EZQueryModel alloc] init];
    self.normalResults = nil;
    self.wordResult = nil;
    self.error = nil;
    self.serviceType = EZServiceTypeYoudao;
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
    self.errorMessage = nil;
    self.isFinished = NO;
}

@end
