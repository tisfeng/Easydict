//
//  Translate.m
//  Bob
//
//  Created by ripper on 2019/12/13.
//  Copyright © 2019 ripperhe. All rights reserved.
//

#import "Translate.h"

#define MethodNotImplemented() \
@throw [NSException exceptionWithName:NSInternalInconsistencyException \
reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
userInfo:nil]

@interface Translate ()

@property (nonatomic, strong) MMOrderedDictionary *langDict;
@property (nonatomic, strong) NSArray *languages;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSString *> *langStringFromEnumDict;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *langEnumFromStringDict;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSNumber *> *langIndexDict;

@end

@implementation Translate

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

- (NSDictionary<NSNumber *,NSString *> *)langStringFromEnumDict {
    if (!_langStringFromEnumDict) {
        _langStringFromEnumDict = [self.langDict keysAndObjects];
    }
    return _langStringFromEnumDict;
}

- (NSDictionary<NSString *,NSNumber *> *)langEnumFromStringDict {
    if (!_langEnumFromStringDict) {
        _langEnumFromStringDict = [[self.langDict keysAndObjects] mm_reverseKeysAndObjectsDictionary];
    }
    return _langEnumFromStringDict;
}

- (NSDictionary<NSNumber *,NSNumber *> *)langIndexDict {
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

#pragma mark - 子类重写

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

- (void)translate:(NSString *)text from:(Language)from to:(Language)to completion:(void (^)(TranslateResult * _Nullable, NSError * _Nullable))completion {
    MethodNotImplemented();
}

- (void)detect:(NSString *)text completion:(void (^)(Language, NSError * _Nullable))completion {
    MethodNotImplemented();
}

- (void)audio:(NSString *)text from:(Language)from completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    MethodNotImplemented();
}

- (void)ocr:(NSImage *)image from:(Language)from to:(Language)to completion:(void (^)(OCRResult * _Nullable, NSError * _Nullable))completion {
    MethodNotImplemented();
}

- (void)ocrAndTranslate:(NSImage *)image from:(Language)from to:(Language)to ocrSuccess:(void (^)(OCRResult * _Nonnull, BOOL))ocrSuccess completion:(void (^)(OCRResult * _Nullable, TranslateResult * _Nullable, NSError * _Nullable))completion {
    MethodNotImplemented();
}

@end
