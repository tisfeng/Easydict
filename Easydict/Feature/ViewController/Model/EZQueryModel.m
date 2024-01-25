//
//  EZQueryModel.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryModel.h"
#import "EZConfiguration.h"
#import <KVOController/NSObject+FBKVOController.h>
#import "NSString+EZUtils.h"
#import "NSString+EZSplit.h"
#import "EZAppleDictionary.h"
#import "NSString+EZHandleInputText.h"
#import "Easydict-Swift.h"

@interface EZQueryModel ()

@property (nonatomic, copy) NSString *queryText;

@property (nonatomic, strong) NSMutableDictionary *stopBlockDictionary; // <serviceType : block>

@end

@implementation EZQueryModel

@synthesize needDetectLanguage = _needDetectLanguage;
@synthesize detectedLanguage = _detectedLanguage;

- (instancetype)init {
    if (self = [super init]) {
        [self.KVOController observe:Configuration.shared keyPath:@"fromLanguage" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(EZQueryModel *queryModel, Configuration *config, NSDictionary<NSString *, id> *_Nonnull change) {
            queryModel.userSourceLanguage = change[NSKeyValueChangeNewKey];
        }];
        [self.KVOController observe:Configuration.shared keyPath:@"toLanguage" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(EZQueryModel *queryModel, Configuration *config, NSDictionary<NSString *, id> *_Nonnull change) {
            queryModel.userTargetLanguage = change[NSKeyValueChangeNewKey];
        }];
        
        self.detectedLanguage = EZLanguageAuto;
        self.actionType = EZActionTypeInputQuery;
        self.stopBlockDictionary = [NSMutableDictionary dictionary];
        self.needDetectLanguage = YES;
        self.showAutoLanguage = NO;
        self.specifiedTextLanguageDict = [NSMutableDictionary dictionary];
        self.autoQuery = YES;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    EZQueryModel *model = [[EZQueryModel allocWithZone:zone] init];
    model.actionType = _actionType;
    model.inputText = _inputText;
    model.userSourceLanguage = _userSourceLanguage;
    model.userTargetLanguage = _userTargetLanguage;
    model.detectedLanguage = _detectedLanguage;
    model.OCRImage = _OCRImage;
    model.queryViewHeight = _queryViewHeight;
    model.audioURL = _audioURL;
    model.needDetectLanguage = _needDetectLanguage;
    model.showAutoLanguage = _showAutoLanguage;
    model.specifiedTextLanguageDict = [_specifiedTextLanguageDict mutableCopy];
    model.autoQuery = _autoQuery;
    
    return model;
}

- (void)setInputText:(NSString *)inputText {
    if (![inputText isEqualToString:_inputText]) {
        // TODO: need to optimize, like needDetectLanguage.
        self.audioURL = nil;
        self.needDetectLanguage = YES;
        self.queryText = [self handleInputText:inputText];
    }
    
    _inputText = [inputText copy];

    if (_inputText.trim.length == 0) {
        _detectedLanguage = EZLanguageAuto;
        _showAutoLanguage = NO;
    }
}

- (void)setActionType:(EZActionType)actionType {
    _actionType = actionType;
    
    if (actionType != EZActionTypeOCRQuery && actionType != EZActionTypeScreenshotOCR) {
        _OCRImage = nil;
    }
}

- (void)setOCRImage:(NSImage *)ocrImage {
    _OCRImage = ocrImage;
    
    if (ocrImage) {
        _actionType = EZActionTypeOCRQuery;
    }
}

- (void)setDetectedLanguage:(EZLanguage)detectedLanguage {
    _detectedLanguage = detectedLanguage;
    
    [self.specifiedTextLanguageDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, EZLanguage language, BOOL *stop) {
        if ([key isEqualToString:self.queryText]) {
            _detectedLanguage = language;
            _needDetectLanguage = NO;
            *stop = YES;
        }
    }];
}

- (void)setNeedDetectLanguage:(BOOL)needDetectLanguage {
    _needDetectLanguage = needDetectLanguage;
    
    if (needDetectLanguage) {
        _showAutoLanguage = NO;
    }
    
    [self setDetectedLanguage:self.detectedLanguage];
}


- (EZLanguage)queryFromLanguage {
    EZLanguage fromLanguage = self.hasUserSourceLanguage ? self.userSourceLanguage : self.detectedLanguage;
    return fromLanguage;
}

- (EZLanguage)queryTargetLanguage {
    EZLanguage fromLanguage = self.queryFromLanguage;
    EZLanguage targetLanguage = self.userTargetLanguage;
    if (!self.hasUserTargetLanguage) {
        targetLanguage = [EZLanguageManager.shared userTargetLanguageWithSourceLanguage:fromLanguage];
    }
    return targetLanguage;
}

- (BOOL)hasQueryFromLanguage {
    return ![self.queryFromLanguage isEqualToString:EZLanguageAuto];
}

- (BOOL)hasUserSourceLanguage {
    BOOL hasUserSourceLanguage = ![self.userSourceLanguage isEqualToString:EZLanguageAuto];
    return hasUserSourceLanguage;
}

- (BOOL)hasUserTargetLanguage {
    BOOL hasUserTargetLanguage = ![self.userTargetLanguage isEqualToString:EZLanguageAuto];
    return hasUserTargetLanguage;
}


#pragma mark - Stop Block

- (void)setStopBlock:(void (^)(void))stopBlock serviceType:(NSString *)type {
    self.stopBlockDictionary[type] = stopBlock;
}

- (void)stopServiceRequest:(NSString *)serviceType {
    void (^stopBlock)(void) = self.stopBlockDictionary[serviceType];
    if (stopBlock) {
        stopBlock();
        [self.stopBlockDictionary removeObjectForKey:serviceType];
    }
}

- (BOOL)isServiceStopped:(NSString *)serviceType {
    return self.stopBlockDictionary[serviceType] == nil;
}

- (void)stopAllService {
    for (NSString *key in self.stopBlockDictionary.allKeys) {
        [self stopServiceRequest:key];
    }
}


#pragma mark - Handle Input text

- (NSString *)handleInputText:(NSString *)inputText {
    NSString *queryText = [inputText trim];
    
    /**
     Split camel and snake case text
     https://github.com/tisfeng/Easydict/issues/135#issuecomment-1750498120
     
     _anchoredDraggable_State --> anchored Draggable State
     */
    if ([queryText isSingleWord]) {
        // If text is an English word, like LaTeX, we don't split it.
        BOOL isEnglishWord = [EZAppleDictionary.shared queryDictionaryForText:queryText language:EZLanguageEnglish];
        if (!isEnglishWord) {
            // If text has quotes, like 'UIKit', we don't split it.
            if ([queryText hasQuotesPair]) {
                queryText = [queryText tryToRemoveQuotes];
            } else {
                queryText = [queryText splitCodeText];
            }
        }
    }
    
    if (Configuration.shared.beta) {
        // Remove prefix [//,#,*,] and join texts.
        queryText = [queryText removeCommentBlockSymbols];
    }

    return [queryText trim];
}

@end
