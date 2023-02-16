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

#define MethodNotImplemented()                                                                                                           \
@throw [NSException exceptionWithName:NSInternalInconsistencyException                                                               \
reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
userInfo:nil]


@interface EZQueryService ()

@property (nonatomic, strong) MMOrderedDictionary *langDict;
@property (nonatomic, strong) NSArray<EZLanguage> *languages;
@property (nonatomic, strong) NSDictionary<NSString *, EZLanguage> *langEnumFromStringDict;
@property (nonatomic, strong) NSDictionary<EZLanguage, NSNumber *> *langIndexDict;

@property (nonatomic, strong) EZAudioPlayer *aduioPlayer;

@end


@implementation EZQueryService

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (EZAudioPlayer *)aduioPlayer {
    if (!_aduioPlayer) {
        _aduioPlayer = [[EZAudioPlayer alloc] init];
    }
    return _aduioPlayer;
}

- (void)setEnabledQuery:(BOOL)enabledQuery {
    _enabledQuery = enabledQuery;
    
    [[EZLocalStorage shared] setEnabledQuery:enabledQuery serviceType:self.serviceType windowType:self.windowType];
}

- (void)setResult:(EZQueryResult *)translateResult {
    _result = translateResult;
    
    _result.service = self;
    _result.serviceType = self.serviceType;
    _result.queryModel = self.queryModel;
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
    MethodNotImplemented();
}


#pragma mark - 子类重写

- (EZServiceType)serviceType {
    MethodNotImplemented();
    return nil;
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
    // If translated language is Chinese, use Chinese text convert directly.
    NSArray *languages = @[ from, to ];
    if ([EZLanguageManager onlyContainsChineseLanguages:languages]) {
        NSString *result;
        if ([to isEqualToString:EZLanguageSimplifiedChinese]) {
            result = [text toSimplifiedChineseText];
        }
        if ([to isEqualToString:EZLanguageTraditionalChinese]) {
            result = [text toTraditionalChineseText];
        }
        if (result) {
            self.result.normalResults = @[ result ];
            completion(self.result, nil);
            return;
        }
    }
    MethodNotImplemented();
}

- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage language, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)textToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable audioUrl, NSError *_Nullable error))completion {
    [self.aduioPlayer playSystemTextAudio:text fromLanguage:from];
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull ocrResult, BOOL success))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable ocrResult, EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

@end
