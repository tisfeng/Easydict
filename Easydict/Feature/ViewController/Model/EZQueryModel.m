//
//  EZQueryModel.m
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryModel.h"
#import "EZConfiguration.h"

NSString *const EZQueryTypeAutoSelect = @"auto_select_query";
NSString *const EZQueryTypeShortcut = @"shortcut_query";
NSString *const EZQueryTypeInput = @"input_query";
NSString *const EZQueryTypeOCR = @"ocr_query";

@interface EZQueryModel ()

@property (nonatomic, strong) NSMutableDictionary *stopBlockDictionary; // <serviceType: block>

@end

@implementation EZQueryModel

- (instancetype)init {
    if (self = [super init]) {
        self.userSourceLanguage = EZConfiguration.shared.from;
        self.userTargetLanguage = EZConfiguration.shared.to;
        self.detectedLanguage = EZLanguageAuto;
        self.queryType = EZQueryTypeInput;
        self.stopBlockDictionary = [NSMutableDictionary dictionary];
        self.needDetectLanguage = YES;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    EZQueryModel *model = [[EZQueryModel allocWithZone:zone] init];
    model.queryType = self.queryType;
    model.queryText = self.queryText;
    model.userSourceLanguage = self.userSourceLanguage;
    model.userTargetLanguage = self.userTargetLanguage;
    model.detectedLanguage = self.detectedLanguage;
    model.ocrImage = self.ocrImage;
    model.queryViewHeight = self.queryViewHeight;
    model.audioURL = self.audioURL;
    model.needDetectLanguage = self.needDetectLanguage;
    
    return model;
}

- (void)setQueryText:(NSString *)queryText {
    if (![queryText isEqualToString:_queryText]) {
        self.audioURL = nil;
        self.needDetectLanguage = YES;
    }
    
    _queryText = [queryText copy];
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

- (void)stopAllService {
    for (NSString *key in self.stopBlockDictionary.allKeys) {
        [self stopServiceRequest:key];
    }
}

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

- (BOOL)hasQueryFromLanguage {
    return ![self.queryFromLanguage isEqualToString:EZLanguageAuto];
}

- (BOOL)needDetectLanguage {
    if (![self.userSourceLanguage isEqualToString:EZLanguageAuto]) {
        return NO;
    }
    return _needDetectLanguage;
}

@end
