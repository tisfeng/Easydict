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
#import "NSString+EZUtils.h"
#import "EZEventMonitor.h"

#define MethodNotImplemented()                                                                                                           \
@throw [NSException exceptionWithName:NSInternalInconsistencyException                                                               \
reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
userInfo:nil]

@interface EZQueryService ()

@property (nonatomic, strong) MMOrderedDictionary *langDict;
@property (nonatomic, strong) NSArray<EZLanguage> *languages;
@property (nonatomic, strong) NSDictionary<NSString *, EZLanguage> *langEnumFromStringDict;
@property (nonatomic, strong) NSDictionary<EZLanguage, NSNumber *> *langIndexDict;

@property (nonatomic, strong) EZDetectManager *detectManager;

@end

@implementation EZQueryService

- (instancetype)init {
    if (self = [super init]) {
        // TODO: result should be created when init, but currently it will cause dead cycle.
        //  self.result = [[EZQueryResult alloc] init];
    }
    return self;
}

- (void)dealloc {
    MMLogInfo(@"dealloc service: %@", self);
}

- (EZAudioPlayer *)audioPlayer {
    if (!_audioPlayer) {
        _audioPlayer = [[EZAudioPlayer alloc] init];
        _audioPlayer.service = self;
    }
    return _audioPlayer;
}

- (EZDetectManager *)detectManager {
    if (!_detectManager) {
        _detectManager = [[EZDetectManager alloc] init];

        if (self.queryModel) {
            _detectManager.queryModel = self.queryModel;
        }
    }
    return _detectManager;
}

- (void)setEnabledQuery:(BOOL)enabledQuery {
    _enabledQuery = enabledQuery;

    [[EZLocalStorage shared] setEnabledQuery:enabledQuery serviceType:self.serviceType windowType:self.windowType];
}

- (BOOL)enabledAutoQuery {
    if (self.serviceUsageStatus == EZServiceUsageStatusAlwaysOff) {
        return NO;
    }

    if ([Configuration.shared intelligentQueryModeForWindowType:self.windowType]) {
        // We usually don't want to lookup dictionary if text word > 1.
        EZQueryTextType queryType = [self.queryModel.queryText queryTypeWithLanguage:self.queryModel.queryFromLanguage maxWordCount:1];
        if ((queryType & self.intelligentQueryTextType) != queryType) {
            return NO;
        }
    }

    return YES;
}

// TODO: need to optimize, each service should have its own model, can stop requests individually.
- (void)setResult:(EZQueryResult *)translateResult {
    _result = translateResult;

    _result.service = self;
    _result.serviceType = self.serviceType;
    _result.queryModel = self.queryModel;
}

- (EZQueryResult *)resetServiceResult {
    EZQueryResult *result = self.result;
    [result reset];
    if (!result) {
        result = [[EZQueryResult alloc] init];
    }

    NSArray *enabledReplaceTypes = @[
        EZActionTypeAutoSelectQuery,
        EZActionTypeShortcutQuery,
        EZActionTypeInvokeQuery,
    ];
    if ([enabledReplaceTypes containsObject:self.queryModel.actionType]) {
        result.showReplaceButton = EZEventMonitor.shared.isSelectedTextEditable;
    } else {
        result.showReplaceButton = NO;
    }

    self.result = result;
    return result;
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


- (BOOL)prehandleQueryText:(NSString *)text
                      from:(EZLanguage)from
                        to:(EZLanguage)to
                completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion
{
    if (!self.queryModel) {
        self.queryModel = [[EZQueryModel alloc] init];
        self.queryModel.userSourceLanguage = from;
        self.queryModel.userTargetLanguage = to;
    }
    self.queryModel.inputText = text;

    if (!self.result) {
        self.result = [[EZQueryResult alloc] init];
    }

    self.result.queryText = text;
    self.result.from = from;
    self.result.to = to;

    // If translated language is Chinese, use Chinese text convert directly.
    NSArray *languages = @[ from, to ];
    if ([self autoConvertTraditionalChinese] &&
        [EZLanguageManager.shared onlyContainsChineseLanguages:languages]) {
        NSString *translatedText;
        if ([to isEqualToString:EZLanguageSimplifiedChinese]) {
            translatedText = [text toSimplifiedChineseText];
        }
        if ([to isEqualToString:EZLanguageTraditionalChinese]) {
            translatedText = [text toTraditionalChineseText];
        }
        if (translatedText) {
            self.result.translatedResults = @[ translatedText ];
            completion(self.result, nil);
            return YES;
        }
    }

    NSString *fromLanguage = [self languageCodeForLanguage:from];
    NSString *toLanguage = [self languageCodeForLanguage:to];

    BOOL unsupportedLanguage = NO;

    if (!fromLanguage || !toLanguage) {
        unsupportedLanguage = YES;
    }

    if (unsupportedLanguage) {
        completion(self.result, EZQueryUnsupportedLanguageError(self));
        return YES;
    }

    // Some services need API Key, the built-in API key free quota may not be enough for all users to use, so it is provided to new users first.
    if (self.needPrivateAPIKey && !self.hasPrivateAPIKey && ![EZLocalStorage.shared hasFreeQuotaLeft:self]) {
        EZError *error = [EZError errorWithType:EZErrorTypeInsufficientQuota
                                    description:nil
                               errorDataMessage:NSLocalizedString(@"insufficient_quota_prompt", nil)];

        self.result.promptURL = self.link;
        completion(self.result, error);
        return YES;
    }

    return NO;
}

- (void)startQuery:(EZQueryModel *)queryModel
        completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion {
    NSString *queryText = queryModel.queryText;
    EZLanguage from = queryModel.queryFromLanguage;
    EZLanguage to = queryModel.queryTargetLanguage;

    if ([self prehandleQueryText:queryText
                            from:from
                              to:to
                      completion:completion]) {
        return;
    }

    [self translate:queryText from:from to:to completion:completion];
}

- (nullable id)configurationListItems {
    return nil;
}

#pragma mark - 必须重写的子类方法

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
    return self.link;
}

- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MethodNotImplemented();
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *result, NSError *_Nullable error))completion {
    MethodNotImplemented();
}

#pragma mark - 可选重写的子类方法

- (BOOL)autoConvertTraditionalChinese {
    return NO;
}

- (EZServiceUsageStatus)serviceUsageStatus {
    return EZServiceUsageStatusDefault;
}

- (EZQueryTextType)queryTextType {
    return EZQueryTextTypeTranslation | EZQueryTextTypeSentence;
}

- (EZQueryTextType)intelligentQueryTextType {
    return EZQueryTextTypeTranslation | EZQueryTextTypeSentence;
}

- (BOOL)hasPrivateAPIKey {
    return NO;
}

- (BOOL)needPrivateAPIKey {
    return NO;
}

- (NSInteger)totalFreeQueryCharacterCount {
    return 100 * 10000;
}

- (BOOL)isStream {
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

#pragma mark - MJExtension

// Avoid MJExtension retain cycle.
+ (NSArray *)mj_ignoredPropertyNames {
    return @[ @"result" ];
}

@end
