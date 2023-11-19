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
    static NSDictionary *dict = @{
        @"adjective" : @"adj.",
        @"adj" : @"adj.",
        @"adverb" : @"adv.",
        @"adv": @"adv.",
        @"verb" : @"v.",
        @"noun" : @"n.",
        @"pronoun" : @"pron.",
        @"preposition" : @"prep.",
        @"conjunction" : @"conj.",
        @"interjection" : @"interj.",
        @"det": @"det.", // determinative 限定词
    };
    
    NSString *partName = dict[part];
    if (!partName) {
        partName = part;
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
    if (self.hasTranslatedResult || self.error || self.errorMessage.length || self.HTMLString.length || self.noResultsFound) {
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
    BOOL warningType = (self.errorType == EZErrorTypeUnsupportedLanguage) || (self.errorType == EZErrorTypeNoResultsFound);
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
    self.errorMessage = nil;
    self.errorType = EZErrorTypeAPI;
    self.isFinished = YES;
    self.errorType = EZErrorTypeNone;
    self.manulShow = NO;
    self.HTMLString = nil;
    self.noResultsFound = NO;
    self.copiedText = nil;
    self.didFinishLoadingHTMLBlock = nil;
    [self.webViewManager reset];
    self.showReplaceButton = NO;
}

@end
