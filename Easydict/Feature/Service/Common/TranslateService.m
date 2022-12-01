//
//  Translate.m
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "TranslateService.h"
#import "EZLocalStorage.h"

#define MethodNotImplemented()    \
    @throw [NSException exceptionWithName:NSInternalInconsistencyException    \
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
                                 userInfo:nil]


@interface TranslateService ()

@property (nonatomic, strong) MMOrderedDictionary *langDict;
@property (nonatomic, strong) NSArray *languages;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSString *> *langStringFromEnumDict;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *langEnumFromStringDict;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSNumber *> *langIndexDict;

@end


@implementation TranslateService

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

- (void)setResult:(TranslateResult *)translateResult {
    _result = translateResult;
       
    _result.serviceType = self.serviceType;
    _result.isShowing = self.enabled;
}

- (MMOrderedDictionary *)langDict {
    if (!_langDict) {
        _langDict = [self supportLanguagesDictionary];
    }
    return _langDict;
}

- (NSArray<NSNumber *> *)languages {
    if (!_languages) {
        _languages = [self.langDict sortedKeys];
    }
    return _languages;
}

- (NSDictionary<NSNumber *, NSString *> *)langStringFromEnumDict {
    if (!_langStringFromEnumDict) {
        _langStringFromEnumDict = [self.langDict keysAndObjects];
    }
    return _langStringFromEnumDict;
}

- (NSDictionary<NSString *, NSNumber *> *)langEnumFromStringDict {
    if (!_langEnumFromStringDict) {
        _langEnumFromStringDict = [[self.langDict keysAndObjects] mm_reverseKeysAndObjectsDictionary];
    }
    return _langEnumFromStringDict;
}

- (NSDictionary<NSNumber *, NSNumber *> *)langIndexDict {
    if (!_langIndexDict) {
        _langIndexDict = [self.languages mm_objectToIndexDictionary];
    }
    return _langIndexDict;
}

- (NSString *)languageStringFromEnum:(Language)lang {
    return [self.langStringFromEnumDict objectForKey:@(lang)];
}

- (Language)languageEnumFromString:(NSString *)langString {
    return [[self.langEnumFromStringDict objectForKey:langString] integerValue];
}

- (NSInteger)indexForLanguage:(Language)lang {
    return [[self.langIndexDict objectForKey:@(lang)] integerValue];
}


- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(OCRResult * _Nullable, NSError * _Nullable))completion {
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

- (MMOrderedDictionary *)supportLanguagesDictionary {
    MethodNotImplemented();
}

- (void)translate:(NSString *)text from:(Language)from to:(Language)to completion:(void (^)(TranslateResult *_Nullable result, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)detect:(NSString *)text completion:(void (^)(Language lang, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)audio:(NSString *)text from:(Language)from completion:(void (^)(NSString *_Nullable text, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)ocr:(NSImage *)image from:(Language)from to:(Language)to completion:(void (^)(OCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

- (void)ocrAndTranslate:(NSImage *)image from:(Language)from to:(Language)to ocrSuccess:(void (^)(OCRResult *_Nonnull ocrResult, BOOL success))ocrSuccess completion:(void (^)(OCRResult *_Nullable ocrResult, TranslateResult *_Nullable result, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

@end
