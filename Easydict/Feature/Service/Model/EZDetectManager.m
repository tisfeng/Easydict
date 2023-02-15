//
//  DetectText.m
//  Easydict
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZDetectManager.h"
#import "EZBaiduTranslate.h"
#import "EZGoogleTranslate.h"
#import "EZConfiguration.h"

@interface EZDetectManager ()

@property (nonatomic, strong) EZGoogleTranslate *googleService;
@property (nonatomic, strong) EZBaiduTranslate *baiduService;

@end

@implementation EZDetectManager

+ (instancetype)managerWithModel:(EZQueryModel *)model {
    EZDetectManager *manager = [[EZDetectManager alloc] init];
    manager.queryModel = model;
    
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (EZAppleService *)appleService {
    if (!_appleService) {
        _appleService = [[EZAppleService alloc] init];
    }
    return _appleService;
}

- (EZQueryService *)ocrService {
    if (!_ocrService) {
        _ocrService = self.appleService;
    }
    return _ocrService;
}

- (EZGoogleTranslate *)googleService {
    if (!_googleService) {
        _googleService = [[EZGoogleTranslate alloc] init];
    }
    return _googleService;
}

- (EZBaiduTranslate *)baiduService {
    if (!_baiduService) {
        _baiduService = [[EZBaiduTranslate alloc] init];
    }
    return _baiduService;
}

#pragma mark -

- (void)ocrAndDetectText:(void (^)(EZQueryModel *_Nonnull, NSError *_Nullable))completion {
    [self deepOCR:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        self.queryModel.queryText = ocrResult.mergedText;
        completion(self.queryModel, error);
    }];
}

/// Detect text language. Apple System detect, Google detect, Baidu detect.
- (void)detectText:(NSString *)queryText completion:(void (^)(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error))completion {
    if (queryText.length == 0) {
        NSLog(@"detectText cannot be nil");
        completion(self.queryModel, nil);
        return;
    }
    
    [self.appleService detectText:queryText completion:^(EZLanguage appleDetectdedLanguage, NSError *_Nullable error) {
        NSMutableArray<EZLanguage> *preferredLanguages = [[EZLanguageManager systemPreferredLanguages] mutableCopy];
        if ([self isAlphabet:queryText]) {
            appleDetectdedLanguage = EZLanguageEnglish;
            NSLog(@"%@ isAlphabet, correct to English", queryText);
        }
        
        // Try to detect Chinese language.
        if (![EZLanguageManager isChineseLanguage:appleDetectdedLanguage]) {
            // test: 開門 open, "使用 OCR" --> 英文 --> 中文
            EZLanguage chineseLanguage = [self chineseLanguageTypeOfText:queryText];
            if (![chineseLanguage isEqualToString:EZLanguageAuto]) {
                appleDetectdedLanguage = chineseLanguage;
            }
        }
        
        EZLanguageDetectOptimize languageDetectOptimize = EZConfiguration.shared.languageDetectOptimize;
        
        // Add English and Chinese to the preferred language list, in general, sysytem detect English and Chinese is relatively accurate, so we don't need to use google or baidu to detect again.
        [preferredLanguages addObjectsFromArray:@[
            EZLanguageEnglish,
            EZLanguageSimplifiedChinese,
            EZLanguageTraditionalChinese,
        ]];
        
        BOOL isPreferredLanguage = [preferredLanguages containsObject:appleDetectdedLanguage];
        if (isPreferredLanguage || languageDetectOptimize == EZLanguageDetectOptimizeNone) {
            [self handleDetectedLanguage:appleDetectdedLanguage error:error completion:completion];
            return;
        }
        
        void (^baiduDetectBlock)(NSString *) = ^(NSString *queryText) {
            [self.baiduService detectText:queryText completion:^(EZLanguage _Nonnull language, NSError *_Nullable error) {
                EZLanguage detectedLanguage = appleDetectdedLanguage;
                if (!error) {
                    detectedLanguage = language;
                    NSLog(@"baidu detected: %@", language);
                } else {
                    MMLogInfo(@"baidu detect error: %@", error);
                }
                [self handleDetectedLanguage:detectedLanguage error:error completion:completion];
            }];
        };
        
        if (languageDetectOptimize == EZLanguageDetectOptimizeBaidu) {
            baiduDetectBlock(queryText);
            return;
        }
        
        if (languageDetectOptimize == EZLanguageDetectOptimizeGoogle) {
            [self.googleService detectText:queryText completion:^(EZLanguage _Nonnull language, NSError *_Nullable error) {
                if (!error) {
                    NSLog(@"google detected: %@", language);
                    [self handleDetectedLanguage:language error:error completion:completion];
                    return;
                }
                
                MMLogInfo(@"google detect error: %@", error);
                
                // If google detect failed, use baidu detect.
                baiduDetectBlock(queryText);
            }];
            return;
        }
    }];
}

- (void)handleDetectedLanguage:(EZLanguage)language
                         error:(NSError *_Nullable)error
                    completion:(void (^)(EZQueryModel *_Nonnull queryModel, NSError *_Nullable error))completion {
    self.queryModel.detectedLanguage = language;
    completion(self.queryModel, error);
}

- (void)ocr:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSImage *image = self.queryModel.ocrImage;
    if (!image) {
        NSLog(@"image cannot be nil");
        return;
    }
    
    [self.ocrService ocr:self.queryModel completion:completion];
}

/// If not designated ocr language, after ocr, we use detected language to ocr again.
- (void)deepOCR:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSImage *image = self.queryModel.ocrImage;
    if (!image) {
        NSLog(@"image cannot be nil");
        return;
    }
    
    BOOL retryOCR = [self.queryModel.detectedLanguage isEqualToString:EZLanguageAuto] && [self.queryModel.userSourceLanguage isEqualToString:EZLanguageAuto];
    
    [self ocr:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        if (!error && retryOCR) {
            NSString *ocrText = ocrResult.mergedText;
            [self detectText:ocrText completion:^(EZQueryModel *_Nonnull queryModel, NSError *_Nullable ocrError) {
                if (!error) {
                    [self.ocrService ocr:queryModel completion:completion];
                } else {
                    completion(ocrResult, nil);
                }
            }];
        } else {
            completion(ocrResult, error);
        }
    }];
}

/// Check if has proxy.
- (BOOL)checkIfHasProxy {
    CFDictionaryRef proxies = SCDynamicStoreCopyProxies(NULL);
    
    CFTypeRef httpProxy = CFDictionaryGetValue(proxies, kSCPropNetProxiesHTTPProxy);
    NSNumber *httpEnable = (__bridge NSNumber *)(CFDictionaryGetValue(proxies, kSCPropNetProxiesHTTPEnable));
    
    if (httpProxy && httpEnable && [httpEnable integerValue]) {
        return YES;
    }
    
    return NO;
}


#pragma mark - Detect Language Manually

/// Check if it is a single letter of the alphabet.
- (BOOL)isAlphabet:(NSString *)string {
    if (string.length != 1) {
        return NO;
    }
    
    NSString *regex = @"[a-zA-Z]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:string];
}

/// Count English characters length in string.
- (NSInteger)englishCharactersLength:(NSString *)string {
    string = [self removePunctuationAndWhitespaceCharacters:string];
    __block NSInteger length = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *_Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL *_Nonnull stop) {
        if ([self isAlphabet:substring]) {
            length++;
        }
    }];
    return length;
}


/// Get Chinese language type of text, traditional or simplified. If it is not Chinese, return EZLanguageAuto.
- (EZLanguage)chineseLanguageTypeOfText:(NSString *)text {
    text = [self removePunctuationAndWhitespaceCharacters:text];
    if (![self isChineseText:text]) {
        return EZLanguageAuto;
    }
    
    // test: 使用 OCR, 開門 open
    NSInteger traditionalChineseCharactersLength = [self chineseCharactersLength:text type:EZLanguageTraditionalChinese];
    
    EZLanguage lanugae = EZLanguageSimplifiedChinese;
    
    // if traditional Chinese characters length >= 1/3 of text length, then it is traditional Chinese.
    if (traditionalChineseCharactersLength >= text.length / 3.0) {
        lanugae = EZLanguageTraditionalChinese;
    }
    NSLog(@"---> Correct to Chinese langauge: %@", lanugae);
    
    return lanugae;
}

/// Count Chinese characters length in string with specific language.
- (NSInteger)chineseCharactersLength:(NSString *)string type:(EZLanguage)language {
    string = [self removePunctuationAndWhitespaceCharacters:string];
    __block NSInteger length = 0;
    for (NSInteger i = 0; i < string.length; i++) {
        NSString *charString = [string substringWithRange:NSMakeRange(i, 1)];
        if (language == EZLanguageTraditionalChinese) {
            if ([self isTraditionalChineseText:charString]) {
                length++;
            }
        } else if (language == EZLanguageSimplifiedChinese) {
            if ([self isSimplifiedChineseText:charString]) {
                length++;
            }
        }
    }
    return length;
}

/// Check if text is Chinese.  アイス・スノーセーリング世界選手権大会 --> ja
/// If Chinese characters length >= 1/5 and Chinese characters length + English characters length == text length, then it is Chinese.
- (BOOL)isChineseText:(NSString *)text {
    text = [self removePunctuationAndWhitespaceCharacters:text];
    NSInteger chineseCharactersLength = [self chineseCharactersLength:text];
    CGFloat textLength = text.length;
    CGFloat chineseCharactersRatio = chineseCharactersLength / textLength;
    
    NSInteger englishCharactersLength = [self englishCharactersLength:text];
    if (chineseCharactersRatio >= 0.2 && chineseCharactersLength + englishCharactersLength == textLength) {
        return YES;
    }
    
    return NO;
}

/// Count Chinese characters length in string. Do not distinguish between traditional and simplified Chinese.
- (NSInteger)chineseCharactersLength:(NSString *)string {
    NSInteger length = 0;
    for (NSInteger i = 0; i < string.length; i++) {
        NSString *subString = [string substringWithRange:NSMakeRange(i, 1)];
        if ([self isChineseCharacter:subString]) {
            length++;
        }
    }
    return length;
}

/// Check if it is a Chinese character. 権 --> ja
- (BOOL)isChineseCharacter:(NSString *)string {
    EZLanguage language = [self.appleService detectTextLanguage:string];
    if ([EZLanguageManager isChineseLanguage:language]) {
        return YES;
    }
    return NO;
}

/// This method is not accurate. 権 --> zh
- (BOOL)isChineseCharacter2:(NSString *)string {
    if (string.length != 1) {
        return NO;
    }
    
    // 権 should be Japanese, but this method will detect it as Chinese.
    NSString *regex = @"[\u4e00-\u9fa5]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:string];
}

/// Check if char is Simplified Chinese. test: 使用 OCR
- (BOOL)isSimplifiedChineseChar:(NSString *)charString {
    if (![self isChineseCharacter:charString]) {
        return NO;
    }
    
    NSString *traditionalText = [self toTraditionalChineseText:charString];
    if ([traditionalText isEqualToString:charString]) {
        return YES;
    }
    return NO;
}

/// Check if char is Traditional Chinese. test: 開門 open
- (BOOL)isTraditionalChineseChar:(NSString *)charString {
    if (![self isChineseCharacter:charString]) {
        return NO;
    }
    
    NSString *simplifiedText = [self toSimplifiedChineseText:charString];
    if (![simplifiedText isEqualToString:charString]) {
        return YES;
    }
    return NO;
}

// Check if text is Chinese, then iterate each char to check if it is Simplified Chinese.
- (BOOL)isSimplifiedChineseText:(NSString *)string {
    if (![self isChineseText:string]) {
        return NO;
    }
    
    for (NSInteger i = 0; i < string.length; i++) {
        NSString *charString = [string substringWithRange:NSMakeRange(i, 1)];
        if (![self isSimplifiedChineseChar:charString]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isTraditionalChineseText:(NSString *)string {
    if (![self isChineseText:string]) {
        return NO;
    }
    
    for (NSInteger i = 0; i < string.length; i++) {
        NSString *charString = [string substringWithRange:NSMakeRange(i, 1)];
        if (![self isTraditionalChineseChar:charString]) {
            return NO;
        }
    }
    return YES;
}

/// Convert Simplified Chinese to Traditional Chinese.
- (NSString *)toTraditionalChineseText:(NSString *)string {
    NSString *traditionalChinese = [string stringByApplyingTransform:@"Hans-Hant" reverse:NO];
    return traditionalChinese;
}

/// Convert Traditional Chinese to Simplified Chinese.
- (NSString *)toSimplifiedChineseText:(NSString *)string {
    NSString *simplifiedChinese = [string stringByApplyingTransform:@"Hant-Hans" reverse:NO];
    return simplifiedChinese;
}


/// Remove all whitespace and newline characters, including whitespace in the middle of the string.
- (NSString *)removeWhitespaceAndNewlineCharacters:(NSString *)string {
    NSString *text = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    text = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return text;
}

/// Remove all punctuation characters, including English and Chinese.
- (NSString *)removePunctuationCharacters:(NSString *)string {
    NSString *text = [string stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    return text;
}

/// Remove all punctuation and whitespace characters.
- (NSString *)removePunctuationAndWhitespaceCharacters:(NSString *)string {
    NSString *text = [self removePunctuationCharacters:string];
    text = [self removeWhitespaceAndNewlineCharacters:text];
    return text;
}

@end
