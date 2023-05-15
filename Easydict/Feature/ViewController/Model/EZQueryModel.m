//
//  EZQueryModel.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryModel.h"
#import "EZConfiguration.h"

@interface EZQueryModel ()

@property (nonatomic, strong) NSMutableDictionary *stopBlockDictionary; // <serviceType: block>

@end

@implementation EZQueryModel

@synthesize needDetectLanguage = _needDetectLanguage;
@synthesize detectedLanguage = _detectedLanguage;

- (instancetype)init {
    if (self = [super init]) {
        self.userSourceLanguage = EZConfiguration.shared.from;
        self.userTargetLanguage = EZConfiguration.shared.to;
        self.detectedLanguage = EZLanguageAuto;
        self.actionType = EZActionTypeInputQuery;
        self.stopBlockDictionary = [NSMutableDictionary dictionary];
        self.needDetectLanguage = YES;
        self.showAutoLanguage = NO;
        self.specifiedTextLanguageDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    EZQueryModel *model = [[EZQueryModel allocWithZone:zone] init];
    model.actionType = self.actionType;
    model.queryText = self.queryText;
    model.userSourceLanguage = self.userSourceLanguage;
    model.userTargetLanguage = self.userTargetLanguage;
    model.detectedLanguage = self.detectedLanguage;
    model.OCRImage = self.OCRImage;
    model.queryViewHeight = self.queryViewHeight;
    model.audioURL = self.audioURL;
    model.needDetectLanguage = self.needDetectLanguage;
    model.showAutoLanguage = self.showAutoLanguage;
    model.specifiedTextLanguageDict = [self.specifiedTextLanguageDict mutableCopy];
    
    return model;
}

- (void)setQueryText:(NSString *)queryText {
    if (![queryText isEqualToString:_queryText]) {
        // TODO: need to optimize, like needDetectLanguage.
        self.audioURL = nil;
        self.needDetectLanguage = YES;
    }
    
    _queryText = [queryText copy];
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

- (EZLanguage)detectedLanguage {
    if (_queryText.length == 0) {
        _detectedLanguage = EZLanguageAuto;
    }
    
    return _detectedLanguage;
}

- (void)setDetectedLanguage:(EZLanguage)detectedLanguage {
    _detectedLanguage = detectedLanguage;
    
    NSString *text = [self.queryText trim];
    [self.specifiedTextLanguageDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, EZLanguage language, BOOL *stop) {
        if ([key isEqualToString:text]) {
            _detectedLanguage = language;
            _needDetectLanguage = NO;
            *stop = YES;
        }
    }];
}

- (BOOL)needDetectLanguage {
    if (![self.userSourceLanguage isEqualToString:EZLanguageAuto]) {
        return NO;
    }
    return _needDetectLanguage;
}

- (void)setNeedDetectLanguage:(BOOL)needDetectLanguage {
    _needDetectLanguage = needDetectLanguage;
    
    if (needDetectLanguage) {
        _showAutoLanguage = NO;
    }
    
    [self setDetectedLanguage:self.detectedLanguage];
}


- (EZLanguage)queryFromLanguage {
    EZLanguage fromLanguage = self.userSourceLanguage;
    if ([fromLanguage isEqualToString:EZLanguageAuto]) {
        fromLanguage = self.detectedLanguage;
    }
    return fromLanguage;
}

- (EZLanguage)queryTargetLanguage {
    EZLanguage fromLanguage = self.queryFromLanguage;
    EZLanguage targetLanguage = self.userTargetLanguage;
    if ([targetLanguage isEqualToString:EZLanguageAuto]) {
        targetLanguage = [EZLanguageManager targetLanguageWithSourceLanguage:fromLanguage];
    }
    return targetLanguage;
}

- (BOOL)hasQueryFromLanguage {
    return ![self.queryFromLanguage isEqualToString:EZLanguageAuto];
}

- (BOOL)showAutoLanguage {
    if (self.queryText.length == 0) {
        return NO;
    }
    
    return _showAutoLanguage;
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

@end
