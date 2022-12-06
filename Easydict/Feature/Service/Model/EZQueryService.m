//
//  EZQueryService.m
//  Easydict
//
//  Created by tisfeng on 2022/11/30.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZQueryService.h"
#import "EZLocalStorage.h"

#define MethodNotImplemented()    \
@throw [NSException exceptionWithName:NSInternalInconsistencyException    \
reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
userInfo:nil]


@interface EZQueryService ()

@property (nonatomic, strong) MMOrderedDictionary *langDict;
@property (nonatomic, strong) NSArray<EZLanguage> *languages;
//@property (nonatomic, strong) NSDictionary<NSNumber *, NSString *> *langStringFromEnumDict;
@property (nonatomic, strong) NSDictionary<NSString *, EZLanguage> *langEnumFromStringDict;
@property (nonatomic, strong) NSDictionary< EZLanguage, NSNumber *> *langIndexDict;

@end


@implementation EZQueryService

- (instancetype)init {
    if (self = [super init]) {
        self.enabled = [[EZLocalStorage shared] getServiceInfo:self.serviceType].enabled;
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    
    [[EZLocalStorage shared] setServiceType:self.serviceType enabled:enabled];
}

- (void)setResult:(EZQueryResult *)translateResult {
    _result = translateResult;
    
    _result.serviceType = self.serviceType;
    _result.isShowing = self.enabled;
    _result.link = self.wordLink;
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


- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult * _Nullable, NSError * _Nullable))completion {
    MethodNotImplemented();
}


#pragma mark - 子类重写

- (EZServiceType)serviceType {
    MethodNotImplemented();
    return nil;
}

- (NSString *)identifier {
    MethodNotImplemented();
    return nil;
}

- (NSString *)name {
    MethodNotImplemented();
    return nil;
}

- (NSString *)link {
    MethodNotImplemented();
    return nil;
}

/// 单词直达链接 
- (nullable NSString *)wordLink {
    MethodNotImplemented();
    return nil;
}


- (MMOrderedDictionary *)supportLanguagesDictionary {
    MethodNotImplemented();
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)detect:(NSString *)text completion:(void (^)(EZLanguage lang, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)audio:(NSString *)text from:(EZLanguage)from completion:(void (^)(NSString *_Nullable text, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)ocr:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull ocrResult, BOOL success))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable ocrResult, EZQueryResult *_Nullable result, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

@end
