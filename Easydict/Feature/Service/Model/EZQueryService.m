//
//  EZQueryService.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryService.h"
#import "EZLocalStorage.h"
#import "EZAudioPlayer.h"
#import "NSString+EZChineseText.h"
#import "EZTextWordUtils.h"
#import "EZConfiguration.h"

#define MethodNotImplemented()                                                                                                           \
@throw [NSException exceptionWithName:NSInternalInconsistencyException                                                               \
reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
userInfo:nil]

@interface EZQueryService ()

@property (nonatomic, strong) MMOrderedDictionary *langDict;
@property (nonatomic, strong) NSArray<EZLanguage> *languages;
@property (nonatomic, strong) NSDictionary<NSString *, EZLanguage> *langEnumFromStringDict;
@property (nonatomic, strong) NSDictionary<EZLanguage, NSNumber *> *langIndexDict;

@end


@implementation EZQueryService

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (EZAudioPlayer *)audioPlayer {
    if (!_audioPlayer) {
        _audioPlayer = [[EZAudioPlayer alloc] init];
        _audioPlayer.service = self;
    }
    return _audioPlayer;
}

- (void)setEnabledQuery:(BOOL)enabledQuery {
    _enabledQuery = enabledQuery;
    
    [[EZLocalStorage shared] setEnabledQuery:enabledQuery serviceType:self.serviceType windowType:self.windowType];
}

- (BOOL)enabledAutoQuery {
    if (self.serviceUsageStatus == EZServiceUsageStatusAlwaysOff) {
        return NO;
    }
    
    if ([EZConfiguration.shared intelligentQueryModeForWindowType:self.windowType]) {
        EZQueryTextType queryType = [EZTextWordUtils queryTypeOfText:self.queryModel.queryText language:self.queryModel.queryFromLanguage];
        if ((queryType & self.intelligentQueryTextType) != queryType) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)enabled {
    if (self.queryTextType == EZQueryTextTypeNone) {
        return NO;
    }
    
    return _enabled;
}

// TODO: need to optimize, each service should have its own model, can stop requests individually.
- (void)setResult:(EZQueryResult *)translateResult {
    _result = translateResult;
    
    _result.service = self;
    _result.serviceType = self.serviceType;
    _result.queryModel = self.queryModel;
    _result.queryText = self.queryModel.queryText;
}

- (MMOrderedDictionary *)langDict {
    if (!_langDict) {
        _langDict = [self supportLanguagesDictionary];
    }
    return _langDict;
}

- (NSArray<EZLanguage> *)languages {
    if (!_languages) {
        _languages = [self.langDict sortedKeys];
    }
    return _languages;
}

- (NSDictionary<NSString *, EZLanguage> *)langEnumFromStringDict {
    if (!_langEnumFromStringDict) {
        _langEnumFromStringDict = [[self.langDict keysAndObjects] mm_reverseKeysAndObjectsDictionary];
    }
    return _langEnumFromStringDict;
}

- (NSDictionary<EZLanguage, NSNumber *> *)langIndexDict {
    if (!_langIndexDict) {
        _langIndexDict = [self.languages mm_objectToIndexDictionary];
    }
    return _langIndexDict;
}

- (NSString *_Nullable)languageCodeForLanguage:(EZLanguage)lang {
    return [self.langDict objectForKey:lang];
}

- (EZLanguage)languageEnumFromCode:(NSString *)langString {
    EZLanguage language = [self.langEnumFromStringDict objectForKey:langString];
    if (!language) {
        language = EZLanguageAuto;
    }
    return language;
}

- (NSInteger)indexForLanguage:(EZLanguage)lang {
    return [[self.langIndexDict objectForKey:lang] integerValue];
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    [self ocr:queryModel.OCRImage from:queryModel.queryFromLanguage to:queryModel.queryTargetLanguage completion:completion];
}


#pragma mark - 子类重写

- (EZServiceType)serviceType {
    MethodNotImplemented();
    return nil;
}

- (EZQueryTextType)queryTextType {
    return EZQueryTextTypeTranslation | EZQueryTextTypeSentence;
}

- (EZQueryTextType)intelligentQueryTextType {
    return EZQueryTextTypeTranslation | EZQueryTextTypeSentence;
}

- (EZServiceUsageStatus)serviceUsageStatus {
    return EZServiceUsageStatusDefault;
}

- (NSString *)name {
    MethodNotImplemented();
    return nil;
}

- (nullable NSString *)link {
    return nil;
}

/// 单词直达链接
- (nullable NSString *)wordLink:(EZQueryModel *)queryModel {
    return nil;
}


- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MethodNotImplemented();
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:YES from:from to:to completion:completion]) {
        return;
    }
    
    MethodNotImplemented();
}

- (BOOL)prehandleQueryTextLanguage:(NSString *)text autoConvertChineseText:(BOOL)isConvert from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    // If translated language is Chinese, use Chinese text convert directly.
    NSArray *languages = @[ from, to ];
    if (isConvert && [EZLanguageManager.shared onlyContainsChineseLanguages:languages]) {
        NSString *result;
        if ([to isEqualToString:EZLanguageSimplifiedChinese]) {
            result = [text toSimplifiedChineseText];
        }
        if ([to isEqualToString:EZLanguageTraditionalChinese]) {
            result = [text toTraditionalChineseText];
        }
        if (result) {
            self.result.translatedResults = @[ result ];
            completion(self.result, nil);
            return YES;
        }
    }
    
    NSString *fromLanguage = [self languageCodeForLanguage:self.queryModel.queryFromLanguage];
    NSString *toLanguage = [self languageCodeForLanguage:self.queryModel.queryTargetLanguage];
    
    BOOL unsupportedLanguage = NO;
    
    if (!fromLanguage || !toLanguage) {
        unsupportedLanguage = YES;
    }
    
    if (unsupportedLanguage) {
        self.result.errorType = EZErrorTypeUnsupportedLanguage;
        completion(self.result, EZQueryUnsupportedLanguageError(self));
        return YES;
    }
    
    return NO;
}

- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage language, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)textToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable audioURL, NSError *_Nullable error))completion {
    [self.audioPlayer.defaultTTSService textToAudio:text fromLanguage:from completion:completion];
}

- (NSString *)getTTSLanguageCode:(EZLanguage)language {
    if ([language isEqualToString:EZLanguageClassicalChinese]) {
        language = EZLanguageSimplifiedChinese;
    }
    
    NSString *languageCode = [self languageCodeForLanguage:language];
    
    // Youdao web TTS,
    if (self.serviceType == EZServiceTypeYoudao) {
        if ([EZLanguageManager.shared isChineseLanguage:language]) {
            languageCode = @"zh"; // Not zh-CHS
        }
    }
    return languageCode;
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull ocrResult, BOOL success))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable ocrResult, EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

@end
