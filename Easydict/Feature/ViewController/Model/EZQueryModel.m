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

- (instancetype)init {
    if (self = [super init]) {
        self.userSourceLanguage = EZConfiguration.shared.from;
        self.userTargetLanguage = EZConfiguration.shared.to;
        self.detectedLanguage = EZLanguageAuto;
        self.actionType = EZActionTypeInputQuery;
        self.stopBlockDictionary = [NSMutableDictionary dictionary];
        self.needDetectLanguage = YES;
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
    model.ocrImage = self.ocrImage;
    model.queryViewHeight = self.queryViewHeight;
    model.audioURL = self.audioURL;
    model.needDetectLanguage = self.needDetectLanguage;
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
        _ocrImage = nil;
    }
}

- (void)setOcrImage:(NSImage *)ocrImage {
    _ocrImage = ocrImage;
    
    if (ocrImage) {
        _actionType = EZActionTypeOCRQuery;
    }
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
