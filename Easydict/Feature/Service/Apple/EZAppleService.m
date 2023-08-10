//
//  EZAppleService.m
//  Easydict
//
//  Created by tisfeng on 2022/11/29.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAppleService.h"
#import <Vision/Vision.h>
#import <AVFoundation/AVFoundation.h>
#import "EZExeCommand.h"
#import "EZConfiguration.h"
#import "EZTextWordUtils.h"
#import "NSString+EZChineseText.h"
#import <CoreImage/CoreImage.h>
#import "NSString+EZCharacterSet.h"

static NSString *const kLineBreakText = @"\n";
static NSString *const kParagraphBreakText = @"\n\n";
static NSString *const kIndentationText = @"";

static NSArray *const kAllowedCharactersInPoetryList = @[ @"《", @"》" ];

static CGFloat const kParagraphLineHeightRatio = 1.2;

@interface VNRecognizedTextObservation (EZText)
@property (nonatomic, copy, readonly) NSString *firstText;
@end

@implementation VNRecognizedTextObservation (EZText)
- (NSString *)firstText {
    NSString *text = [[self topCandidates:1] firstObject].string;
    return text;
}
@end

@interface NSArray (VNRecognizedTextObservation)
@property (nonatomic, copy, readonly) NSArray<NSString *> *recognizedTexts;
@end

@implementation NSArray (VNRecognizedTextObservation)

- (NSArray<NSString *> *)recognizedTexts {
    NSMutableArray *texts = [NSMutableArray array];
    for (VNRecognizedTextObservation *observation in self) {
        NSString *text = observation.firstText;
        if (text) {
            [texts addObject:text];
        }
    }
    return texts;
}

@end


@interface EZAppleService ()

@property (nonatomic, strong) EZExeCommand *exeCommand;

@property (nonatomic, strong) NSDictionary *appleLangEnumFromStringDict;

/**
 CGFloat minLineHeight = MAXFLOAT;
 CGFloat totalLineHeight = 0;
 CGFloat averageLineHeight = 0;
 
 // OCR line spacing may be less than 0
 CGFloat minLineSpacing = MAXFLOAT;
 CGFloat minPositiveLineSpacing = MAXFLOAT;
 CGFloat totalLineSpacing = 0;
 CGFloat averageLineSpacing = 0;
 
 CGFloat minX = MAXFLOAT;
 CGFloat maxLengthOfLine = 0;
 CGFloat minLengthOfLine = MAXFLOAT;
 NSInteger punctuationMarkCount = 0;
 NSInteger totalCharCount = 0;
 CGFloat charCountPerLine = 0;
 */

@property (nonatomic, copy) EZLanguage language;

@property (nonatomic, assign) CGFloat minX;
@property (nonatomic, assign) CGFloat maxLineLength;

@property (nonatomic, strong) VNRecognizedTextObservation *maxLongLineTextObservation;
@property (nonatomic, strong) VNRecognizedTextObservation *minXLineTextObservation;

@property (nonatomic, strong) NSImage *ocrImage;
@property (nonatomic, assign) BOOL isPoetry;

@property (nonatomic, assign) CGFloat minLineLength;
@property (nonatomic, assign) CGFloat minLineHeight;
@property (nonatomic, assign) CGFloat totalLineHeight;
@property (nonatomic, assign) CGFloat averageLineHeight;

@property (nonatomic, assign) CGFloat minLineSpacing;
@property (nonatomic, assign) CGFloat minPositiveLineSpacing;
@property (nonatomic, assign) CGFloat totalLineSpacing;
@property (nonatomic, assign) CGFloat averageLineSpacing;

@property (nonatomic, assign) NSInteger punctuationMarkCount;
@property (nonatomic, assign) NSInteger totalCharCount;
@property (nonatomic, assign) CGFloat charCountPerLine;

@end

@implementation EZAppleService

- (instancetype)init {
    self = [super init];
    if (self) {
        self.minLineHeight = MAXFLOAT;
        self.minLineSpacing = MAXFLOAT;
        self.minPositiveLineSpacing = MAXFLOAT;
        self.minX = MAXFLOAT;
        self.maxLineLength = 0;
        self.minLineLength = MAXFLOAT;
    }
    return self;
}

- (EZExeCommand *)exeCommand {
    if (!_exeCommand) {
        _exeCommand = [[EZExeCommand alloc] init];
    }
    return _exeCommand;
}

- (NSDictionary<NLLanguage, EZLanguage> *)appleLangEnumFromStringDict {
    if (!_appleLangEnumFromStringDict) {
        _appleLangEnumFromStringDict = [[[self appleLanguagesDictionary] keysAndObjects] mm_reverseKeysAndObjectsDictionary];
    }
    return _appleLangEnumFromStringDict;
}


#pragma mark - 子类重写

- (EZServiceType)serviceType {
    return EZServiceTypeApple;
}

- (NSString *)name {
    return NSLocalizedString(@"apple_translate", nil);
}

- (MMOrderedDictionary *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        //                                        EZLanguageAuto, @"auto",
                                        EZLanguageSimplifiedChinese, @"zh_CN",
                                        EZLanguageTraditionalChinese, @"zh_TW",
                                        EZLanguageEnglish, @"en_US",
                                        EZLanguageJapanese, @"ja_JP",
                                        EZLanguageKorean, @"ko_KR",
                                        EZLanguageFrench, @"fr_FR",
                                        EZLanguageSpanish, @"es_ES",
                                        EZLanguagePortuguese, @"pt_BR",
                                        EZLanguageItalian, @"it_IT",
                                        EZLanguageGerman, @"de_DE",
                                        EZLanguageRussian, @"ru_RU",
                                        EZLanguageArabic, @"ar_AE",
                                        EZLanguageThai, @"th_TH",
                                        EZLanguagePolish, @"pl_PL",
                                        EZLanguageTurkish, @"tr_TR",
                                        EZLanguageIndonesian, @"id_ID",
                                        EZLanguageVietnamese, @"vi_VN",
                                        nil];
    
    return orderedDict;
}

- (MMOrderedDictionary<EZLanguage, NLLanguage> *)appleLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, NLLanguageUndetermined,                     // uud
                                        EZLanguageSimplifiedChinese, NLLanguageSimplifiedChinese,   // zh-Hans
                                        EZLanguageTraditionalChinese, NLLanguageTraditionalChinese, // zh-Hant
                                        EZLanguageEnglish, NLLanguageEnglish,                       // en
                                        EZLanguageJapanese, NLLanguageJapanese,                     // ja
                                        EZLanguageKorean, NLLanguageKorean,
                                        EZLanguageFrench, NLLanguageFrench,
                                        EZLanguageSpanish, NLLanguageSpanish,
                                        EZLanguagePortuguese, NLLanguagePortuguese,
                                        EZLanguageItalian, NLLanguageItalian,
                                        EZLanguageGerman, NLLanguageGerman,
                                        EZLanguageRussian, NLLanguageRussian,
                                        EZLanguageArabic, NLLanguageArabic,
                                        EZLanguageSwedish, NLLanguageSwedish,
                                        EZLanguageRomanian, NLLanguageRomanian,
                                        EZLanguageThai, NLLanguageThai,
                                        EZLanguageSlovak, NLLanguageSlovak,
                                        EZLanguageDutch, NLLanguageDutch,
                                        EZLanguageHungarian, NLLanguageHungarian,
                                        EZLanguageGreek, NLLanguageGreek,
                                        EZLanguageDanish, NLLanguageDanish,
                                        EZLanguageFinnish, NLLanguageFinnish,
                                        EZLanguagePolish, NLLanguagePolish,
                                        EZLanguageCzech, NLLanguageCzech,
                                        EZLanguageTurkish, NLLanguageTurkish,
                                        EZLanguageUkrainian, NLLanguageUkrainian,
                                        EZLanguageBulgarian, NLLanguageBulgarian,
                                        EZLanguageIndonesian, NLLanguageIndonesian,
                                        EZLanguageMalay, NLLanguageMalay,
                                        EZLanguageVietnamese, NLLanguageVietnamese,
                                        EZLanguagePersian, NLLanguagePersian,
                                        EZLanguageHindi, NLLanguageHindi,
                                        EZLanguageTelugu, NLLanguageTelugu,
                                        EZLanguageTamil, NLLanguageTamil,
                                        EZLanguageUrdu, NLLanguageUrdu,
                                        EZLanguageKhmer, NLLanguageKhmer,
                                        EZLanguageLao, NLLanguageLao,
                                        EZLanguageBengali, NLLanguageBengali,
                                        EZLanguageBurmese, NLLanguageBurmese,
                                        EZLanguageNorwegian, NLLanguageNorwegian,
                                        EZLanguageCroatian, NLLanguageCroatian,
                                        EZLanguageMongolian, NLLanguageMongolian,
                                        EZLanguageHebrew, NLLanguageHebrew,
                                        nil];
    
    return orderedDict;
}

/// Apple ocr language: "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ko-KR", "ja-JP", "ru-RU", "uk-UA"
- (MMOrderedDictionary *)ocrLanguageDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageSimplifiedChinese, @"zh-Hans",
                                        EZLanguageTraditionalChinese, @"zh-Hant",
                                        EZLanguageEnglish, @"en-US",
                                        EZLanguageJapanese, @"ja-JP",
                                        EZLanguageKorean, @"ko-KR",
                                        EZLanguageFrench, @"fr-FR",
                                        EZLanguageSpanish, @"es-ES",
                                        EZLanguagePortuguese, @"pt-BR",
                                        EZLanguageItalian, @"it-IT",
                                        EZLanguageGerman, @"de-DE",
                                        EZLanguageRussian, @"ru-RU",
                                        EZLanguageUkrainian, @"uk-UA",
                                        nil];
    return orderedDict;
}

- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    if (text.length == 0) {
        NSLog(@"text is empty");
        return;
    }
    
    // Since Apple system translation not support zh-hans --> zh-hant and zh-hant --> zh-hans, so we need to convert it manually.
    if ([self prehandleQueryTextLanguage:text autoConvertChineseText:YES from:from to:to completion:completion]) {
        return;
    }
    
    NSString *appleFromLangCode = [self languageCodeForLanguage:from];
    NSString *appleToLangCode = [self languageCodeForLanguage:to];
    
    NSDictionary *paramters = @{
        @"text" : text,
        @"from" : appleFromLangCode,
        @"to" : appleToLangCode,
    };
    //    NSLog(@"Apple translate paramters: %@", paramters);
    
    NSTask *task = [self.exeCommand runTranslateShortcut:paramters completionHandler:^(NSString *_Nonnull result, NSError *error) {
        if ([self.queryModel isServiceStopped:self.serviceType]) {
            return;
        }
        
        if (!error) {
            // Apple Translation does not distinguish between newlines and paragraphs, and the results are all merged with \n\n
            self.result.translatedResults = @[ result.trim ];
        } else {
            self.result.promptTitle = @"如何在 Easydict 中使用 🍎 macOS 系统翻译？";
            // https://github.com/tisfeng/Easydict/blob/main/docs/How-to-use-macOS-system-translation-in-Easydict-zh.md
            NSString *docsURL = @"https://github.com/tisfeng/Easydict/blob/main/docs/How-to-use-macOS-system-translation-in-Easydict-%@.md";
            NSString *language = @"zh";
            if ([to isEqualToString:EZLanguageEnglish]) {
                language = @"en";
            }
            self.result.promptURL = [NSString stringWithFormat:docsURL, language];
        }
        completion(self.result, error);
    }];
    
    [self.queryModel setStopBlock:^{
        [task interrupt];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task terminate];
        });
    } serviceType:self.serviceType];
}

/// Apple System ocr. Use Vision to recognize text in the image. Cost ~0.4s
- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    self.queryModel = queryModel;
    queryModel.autoQuery = YES;
    
    NSImage *image = queryModel.OCRImage;
    
    BOOL automaticallyDetectsLanguage = YES;
    BOOL hasSpecifiedLanguage = ![queryModel.queryFromLanguage isEqualToString:EZLanguageAuto];
    if (hasSpecifiedLanguage) {
        automaticallyDetectsLanguage = NO;
    }
    
    [self ocrImage:image
          language:queryModel.queryFromLanguage
        autoDetect:automaticallyDetectsLanguage
        completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        if (hasSpecifiedLanguage || ocrResult.confidence == 1.0 || error) {
            /**
             If there is only a QR code in the image, OCR will return error, then try to detect QRCode image.
             If there is both text and a QR code in the image, the text is recognized first.
             */
            if (error) {
                EZOCRResult *ocrResult = [self getOCRResultFromQRCodeImage:image];
                if (ocrResult) {
                    completion(ocrResult, nil);
                    return;
                }
            }
            
            queryModel.ocrConfidence = ocrResult.confidence;
            completion(ocrResult, error);
            return;
        }
        
        NSDictionary *languageDict = [self appleDetectTextLanguageDict:ocrResult.mergedText printLog:YES];
        [self getMostConfidentLangaugeOCRResult:languageDict completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
            queryModel.ocrConfidence = ocrResult.confidence;
            completion(ocrResult, error);
        }];
    }];
}

- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"Apple not support ocrAndTranslate");
}

- (void)textToAudio:(NSString *)text fromLanguage:(EZLanguage)from completion:(void (^)(NSString *_Nullable audioURL, NSError *_Nullable error))completion {
    completion(nil, nil);
}


#pragma mark - Public Methods

/// Convert NLLanguage to EZLanguage, e.g. zh-Hans --> Chinese-Simplified
- (EZLanguage)languageEnumFromAppleLanguage:(NLLanguage)appleLanguage {
    EZLanguage ezLanguage = [self.appleLangEnumFromStringDict objectForKey:appleLanguage];
    if (!ezLanguage) {
        ezLanguage = EZLanguageAuto;
    }
    return ezLanguage;
}

/// Convert EZLanguage to NLLanguage, e.g. Chinese-Simplified --> zh-Hans
- (NLLanguage)appleLanguageFromLanguageEnum:(EZLanguage)ezLanguage {
    return [self.appleLanguagesDictionary objectForKey:ezLanguage];
}

- (NSSpeechSynthesizer *)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)fromLanguage {
    NSLog(@"system speak: %@ (%@)", text, fromLanguage);
    
    // voiceIdentifier: com.apple.voice.compact.en-US.Samantha
    NSString *voiceIdentifier = [self voiceIdentifierFromLanguage:fromLanguage];
    NSSpeechSynthesizer *synthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:voiceIdentifier];
    
    void (^playBlock)(NSString *, EZLanguage) = ^(NSString *text, EZLanguage fromLanguage) {
        [synthesizer startSpeakingString:text];
    };
    
    if ([fromLanguage isEqualToString:EZLanguageAuto]) {
        [self detectText:text completion:^(EZLanguage _Nonnull fromLanguage, NSError *_Nullable error) {
            playBlock(text, fromLanguage);
        }];
    } else {
        playBlock(text, fromLanguage);
    }
    
    return synthesizer;
}


#pragma mark - Apple language detect

/// System detect text language,
- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    EZLanguage mostConfidentLanguage = [self detectTextLanguage:text printLog:YES];
    completion(mostConfidentLanguage, nil);
}

- (EZLanguage)detectText:(NSString *)text {
    EZLanguage mostConfidentLanguage = [self detectTextLanguage:text printLog:NO];
    return mostConfidentLanguage;
}

/// Apple System language recognize, and try to correct language.
- (EZLanguage)detectTextLanguage:(NSString *)text printLog:(BOOL)logFlag {
    EZLanguage mostConfidentLanguage = [self appleDetectTextLanguage:text printLog:logFlag];
    
    if ([text isAlphabet] && ![mostConfidentLanguage isEqualToString:EZLanguageEnglish]) {
        mostConfidentLanguage = EZLanguageEnglish;
    }
    
    if ([EZLanguageManager.shared isChineseLanguage:mostConfidentLanguage]) {
        // Correct 勿 --> zh-Hant --> zh-Hans
        EZLanguage chineseLanguage = [self chineseLanguageTypeOfText:text];
        return chineseLanguage;
    } else {
        // Try to detect Chinese language.
        if ([EZLanguageManager.shared isUserChineseFirstLanguage]) {
            // test: 開門 open, 使用1 OCR --> 英文, --> 中文
            EZLanguage chineseLanguage = [self chineseLanguageTypeOfText:text fromLanguage:mostConfidentLanguage];
            if (![chineseLanguage isEqualToString:EZLanguageAuto]) {
                mostConfidentLanguage = chineseLanguage;
            }
        }
    }
    
    return mostConfidentLanguage;
}

/// Apple original detect language.
- (EZLanguage)appleDetectTextLanguage:(NSString *)text {
    EZLanguage mostConfidentLanguage = [self appleDetectTextLanguage:text printLog:NO];
    return mostConfidentLanguage;
}

- (EZLanguage)appleDetectTextLanguage:(NSString *)text printLog:(BOOL)logFlag {
    NSDictionary<NLLanguage, NSNumber *> *languageProbabilityDict = [self appleDetectTextLanguageDict:text printLog:logFlag];
    EZLanguage mostConfidentLanguage = [self getMostConfidentLanguage:languageProbabilityDict printLog:logFlag];
    
    return mostConfidentLanguage;
}

/// Apple original detect language dict.
- (NSDictionary<NLLanguage, NSNumber *> *)appleDetectTextLanguageDict:(NSString *)text printLog:(BOOL)logFlag {
    text = [text trimToMaxLength:100];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // 10.14+  Ref: https://developer.apple.com/documentation/naturallanguage/identifying_the_language_in_text?language=objc
    NLLanguageRecognizer *recognizer = [[NLLanguageRecognizer alloc] init];
    
    // Because Apple text recognition is often inaccurate, we need to limit the recognition language type.
    recognizer.languageConstraints = [self designatedLanguages];
    recognizer.languageHints = [self customLanguageHints];
    [recognizer processString:text];
    
    NSDictionary<NLLanguage, NSNumber *> *languageProbabilityDict = [recognizer languageHypothesesWithMaximum:5];
    NLLanguage dominantLanguage = recognizer.dominantLanguage;
    
    // !!!: All numbers will be return empty dict @{}: 729
    if (languageProbabilityDict.count == 0) {
        EZLanguage firstLanguage = [EZLanguageManager.shared userFirstLanguage];
        dominantLanguage = [self appleLanguageFromLanguageEnum:firstLanguage];
        languageProbabilityDict = @{dominantLanguage : @(0)};
    }
    
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    
    if (logFlag) {
        NSLog(@"system probabilities: %@", languageProbabilityDict);
        NSLog(@"dominant Language: %@", dominantLanguage);
        NSLog(@"detect cost: %.1f ms", (endTime - startTime) * 1000); // ~4ms
    }
    
    return languageProbabilityDict;
}

// designatedLanguages is supportLanguagesDictionary remove some languages
- (NSArray<NLLanguage> *)designatedLanguages {
    NSArray<NLLanguage> *supportLanguages = [[self appleLanguagesDictionary] allValues];
    NSArray<NLLanguage> *removeLanguages = @[
        //        NLLanguageDutch, // heel
    ];
    NSMutableArray<NLLanguage> *uniqueLanguages = [NSMutableArray arrayWithArray:supportLanguages];
    [uniqueLanguages removeObjectsInArray:removeLanguages];
    return uniqueLanguages;
}

/// Custom language hints
- (NSDictionary<NLLanguage, NSNumber *> *)customLanguageHints {
    // TODO: need to refer to the user's preferred language.
    NSDictionary *customHints = @{
        NLLanguageEnglish : @(4.5),
        NLLanguageSimplifiedChinese : @(2.0),
        NLLanguageTraditionalChinese : @(0.6), // 電池
        NLLanguageJapanese : @(0.25),
        NLLanguageFrench : @(0.2), // const, ex, delimiter, proposition
        NLLanguageKorean : @(0.2),
        NLLanguageItalian : @(0.1),     // via
        NLLanguageSpanish : @(0.1),     // favor
        NLLanguageGerman : @(0.05),     // usa, sender
        NLLanguagePortuguese : @(0.05), // favor, e
        NLLanguageDutch : @(0.01),      // heel, via
        NLLanguageCzech : @(0.01),      // pro
    };
    
    NSArray<NLLanguage> *allSupportedLanguages = [[self appleLanguagesDictionary] allValues];
    NSMutableDictionary<NLLanguage, NSNumber *> *languageHints = [NSMutableDictionary dictionary];
    for (NLLanguage language in allSupportedLanguages) {
        languageHints[language] = @(0.01);
    }
    
    [languageHints addEntriesFromDictionary:customHints];
    
    return languageHints;
}

- (NSDictionary<EZLanguage, NSNumber *> *)userPreferredLanguageProbabilities {
    NSArray *preferredLanguages = [EZLanguageManager.shared preferredLanguages];
    
    // TODO: need to test more data. Maybe need to write a unit test.
    
    /**
     Increase the proportional weighting of the user's preferred language.
     
     1. Chinese, + 0.4
     2. English, + 0.3
     3. Japanese, + 0.2
     4. ........, + 0.1
     
     */
    NSMutableDictionary<EZLanguage, NSNumber *> *languageProbabilities = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < preferredLanguages.count; i++) {
        EZLanguage language = preferredLanguages[i];
        CGFloat maxWeight = 0.4;
        CGFloat step = 0.1;
        CGFloat weight = maxWeight - step * i;
        if (weight < 0.1) {
            weight = 0.1;
        }
        if ([language isEqualToString:EZLanguageEnglish]) {
            if (![EZLanguageManager.shared isUserChineseFirstLanguage]) {
                weight += 0.2;
            } else {
                weight += 0.1;
            }
        }
        languageProbabilities[language] = @(weight);
    }
    
    // Since English is so widely used, we need to add additional weighting 0.2, even it's not preferred language.
    if (![preferredLanguages containsObject:EZLanguageEnglish]) {
        languageProbabilities[EZLanguageEnglish] = @(0.2);
    }
    
    return languageProbabilities;
}


/// Get most confident language.
/// languageDict value add userPreferredLanguageProbabilities, then sorted by value, return max dict value.
- (EZLanguage)getMostConfidentLanguage:(NSDictionary<NLLanguage, NSNumber *> *)defaultLanguageProbabilities printLog:(BOOL)logFlag {
    NSMutableDictionary<NLLanguage, NSNumber *> *languageProbabilities = [NSMutableDictionary dictionaryWithDictionary:defaultLanguageProbabilities];
    NSDictionary<EZLanguage, NSNumber *> *userPreferredLanguageProbabilities = [self userPreferredLanguageProbabilities];
    
    for (EZLanguage language in userPreferredLanguageProbabilities.allKeys) {
        NLLanguage appleLanguage = [self appleLanguageFromLanguageEnum:language];
        CGFloat defaultProbability = [defaultLanguageProbabilities[appleLanguage] doubleValue];
        if (defaultProbability) {
            NSNumber *userPreferredLanguageProbability = userPreferredLanguageProbabilities[language];
            languageProbabilities[appleLanguage] = @(defaultProbability + userPreferredLanguageProbability.doubleValue);
        }
    }
    
    NSArray<NLLanguage> *sortedLanguages = [languageProbabilities keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    
    NLLanguage mostConfidentLanguage = sortedLanguages.firstObject;
    EZLanguage ezLanguage = [self languageEnumFromAppleLanguage:mostConfidentLanguage];
    
    if (logFlag) {
        NSLog(@"user probabilities: %@", userPreferredLanguageProbabilities);
        NSLog(@"final language probabilities: %@", languageProbabilities);
        NSLog(@"---> Apple detect: %@", ezLanguage);
    }
    
    return ezLanguage;
}


#pragma mark - Apple OCR

- (void)ocrImage:(NSImage *)image
        language:(EZLanguage)preferredLanguage
      autoDetect:(BOOL)automaticallyDetectsLanguage
      completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    NSLog(@"ocr language: %@", preferredLanguage);
    
    self.ocrImage = image;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Convert NSImage to CGImage
        CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
        
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        
        // Ref: https://developer.apple.com/documentation/vision/recognizing_text_in_images?language=objc
        
        MMOrderedDictionary *appleOCRLanguageDict = [self ocrLanguageDictionary];
        NSArray<EZLanguage> *defaultRecognitionLanguages = [appleOCRLanguageDict sortedKeys];
        NSArray<EZLanguage> *recognitionLanguages = [self updateOCRRecognitionLanguages:defaultRecognitionLanguages
                                                                     preferredLanguages:[EZLanguageManager.shared preferredLanguages]];
        
        VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *_Nonnull request, NSError *_Nullable error) {
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            NSLog(@"ocr cost: %.1f ms", (endTime - startTime) * 1000);
            
            EZOCRResult *ocrResult = [[EZOCRResult alloc] init];
            ocrResult.from = preferredLanguage;
            
            if (error) {
                completion(ocrResult, error);
                return;
            }
            
            BOOL joined = ![ocrResult.from isEqualToString:EZLanguageAuto] || ocrResult.confidence == 1.0;
            [self setupOCRResult:ocrResult request:request intelligentJoined:joined];
            if (!error && ocrResult.mergedText.length == 0) {
                /**
                 !!!: There are some problems with the system OCR.
                 For example, it may return nil when ocr Japanese text:
                 
                 アイス・スノーセーリング世界選手権大会
                 
                 But if specify Japanese as preferredLanguage, we can get right OCR text, So we need to OCR again.
                 */
                
                if ([preferredLanguage isEqualToString:EZLanguageAuto]) {
                    EZLanguage tryLanguage = EZLanguageJapanese;
                    [self ocrImage:image language:tryLanguage autoDetect:YES completion:completion];
                    return;
                } else {
                    error = [EZTranslateError errorWithString:NSLocalizedString(@"ocr_result_is_empty", nil)];
                    
                    // We try to use Japanese before, but failed, so need to reset to auto.
                    ocrResult.from = EZLanguageAuto;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(ocrResult, error);
            });
            return;
        }];
        
        if (@available(macOS 12.0, *)) {
            //            NSError *error;
            //            NSArray<NSString *> *supportedLanguages = [request supportedRecognitionLanguagesAndReturnError:&error];
            // "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ko-KR", "ja-JP", "ru-RU", "uk-UA"
            //            NSLog(@"supported Languages: %@", supportedLanguages);
        }
        
        if (@available(macOS 13.0, *)) {
            request.automaticallyDetectsLanguage = automaticallyDetectsLanguage;
        }
        
        if (![preferredLanguage isEqualToString:EZLanguageAuto]) {
            // If has designated ocr language, move it to first priority.
            recognitionLanguages = [self updateOCRRecognitionLanguages:recognitionLanguages
                                                    preferredLanguages:@[ preferredLanguage ]];
        }
        
        
        NSArray *appleOCRLangaugeCodes = [self appleOCRLangaugeCodesWithRecognitionLanguages:recognitionLanguages];
        request.recognitionLanguages = appleOCRLangaugeCodes; // ISO language codes
        
        // TODO: need to test [usesLanguageCorrection] value.
        // If we use automaticallyDetectsLanguage = YES, means we are not sure about the OCR text language, that we don't need auto correction.
        request.usesLanguageCorrection = !automaticallyDetectsLanguage; // Default is YES
        
        // Perform the text-recognition request.
        [requestHandler performRequests:@[ request ] error:nil];
    });
}

// Update OCR recognitionLanguages with preferred languages.
- (NSArray<EZLanguage> *)updateOCRRecognitionLanguages:(NSArray<EZLanguage> *)recognitionLanguages
                                    preferredLanguages:(NSArray<EZLanguage> *)preferredLanguages {
    NSMutableArray *newRecognitionLanguages = [NSMutableArray arrayWithArray:recognitionLanguages];
    for (EZLanguage preferredLanguage in [[preferredLanguages reverseObjectEnumerator] allObjects]) {
        if ([recognitionLanguages containsObject:preferredLanguage]) {
            [newRecognitionLanguages removeObject:preferredLanguage];
            [newRecognitionLanguages insertObject:preferredLanguage atIndex:0];
        }
    }
    
    /**
     Since ocr Chinese mixed with English is not very accurate,
     we need to move Chinese to the first priority if newRecognitionLanguages first object is English and if user system language contains Chinese.
     
     风云 wind and clouds 99$ é
     
     */
    if ([preferredLanguages.firstObject isEqualToString:EZLanguageEnglish]) {
        // iterate all system preferred languages, if contains Chinese, move Chinese to the first priority.
        for (EZLanguage language in [EZLanguageManager.shared preferredLanguages]) {
            if ([EZLanguageManager.shared isChineseLanguage:language]) {
                [newRecognitionLanguages removeObject:language];
                [newRecognitionLanguages insertObject:language atIndex:0];
                break;
            }
        }
    }
    return [newRecognitionLanguages copy];
}

// return Apple OCR language codes with EZLanguage array.
- (NSArray<NSString *> *)appleOCRLangaugeCodesWithRecognitionLanguages:(NSArray<EZLanguage> *)languages {
    NSMutableArray *appleOCRLanguageCodes = [NSMutableArray array];
    for (EZLanguage language in languages) {
        NSString *appleOCRLangaugeCode = [[self ocrLanguageDictionary] objectForKey:language];
        if (appleOCRLangaugeCode.length > 0) {
            [appleOCRLanguageCodes addObject:appleOCRLangaugeCode];
        }
    }
    return [appleOCRLanguageCodes copy];
}


- (void)getMostConfidentLangaugeOCRResult:(NSDictionary<NLLanguage, NSNumber *> *)languageProbabilityDict completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    /**
     
     苔むした岩に囲まれた滝
     
     */
    NSArray<NLLanguage> *sortedLanguages = [languageProbabilityDict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];
    
    NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
    dispatch_group_t group = dispatch_group_create();
    
    for (NLLanguage language in sortedLanguages) {
        EZLanguage ezLanguage = [self languageEnumFromAppleLanguage:language];
        dispatch_group_enter(group);
        
        // !!!: automaticallyDetectsLanguage must be YES, otherwise confidence will be always 1.0
        [self ocrImage:self.queryModel.OCRImage
              language:ezLanguage
            autoDetect:YES
            completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
            [results addObject:@{@"ocrResult" : ocrResult ?: [NSNull null], @"error" : error ?: [NSNull null]}];
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            NSArray<NSDictionary *> *sortedResults = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                EZOCRResult *result1 = obj1[@"ocrResult"];
                EZOCRResult *result2 = obj2[@"ocrResult"];
                NSNumber *confidence1 = result1 ? @(result1.confidence) : @(-1);
                NSNumber *confidence2 = result2 ? @(result2.confidence) : @(-1);
                return [confidence2 compare:confidence1];
            }];
            
            __block NSDictionary *firstResult = sortedResults.firstObject;
            EZOCRResult *firstOCRResult = firstResult[@"ocrResult"];
            
            // Since there are some languages that have the same confidence, we need to get all of them.
            NSMutableArray<NSDictionary *> *mostConfidentResults = [NSMutableArray array];
            CGFloat mostConfidence = firstOCRResult.confidence;
            
            for (NSDictionary *result in sortedResults) {
                EZOCRResult *ocrResult = result[@"ocrResult"];
                if (ocrResult.confidence == mostConfidence) {
                    [mostConfidentResults addObject:result];
                }
                NSString *mergedText = [ocrResult.mergedText trimToMaxLength:100];
                NSLog(@"%@(%.2f): %@", ocrResult.from, ocrResult.confidence, mergedText);
            }
            
            /**
             Since ocr detect language may be incorrect, we need to detect mergedText language again, get most confident OCR language.
             
             e.g. this lyrics may be OCR detected as simplified Chinese, but it's actually traditional Chinese.
             
             慢慢吹 輕輕送人生路 你就走
             就當我倆沒有明天
             就當我俩只剩眼前
             就當我都不曾離開
             還仍佔滿你心懐
             
             */
            if (mostConfidentResults.count > 1) {
                __block BOOL shouldBreak = NO;
                
                for (NSDictionary *result in mostConfidentResults) {
                    EZOCRResult *ocrResult = result[@"ocrResult"];
                    NSString *mergedText = ocrResult.mergedText;
                    EZLanguage detectedLanguage = [self detectText:mergedText];
                    if ([detectedLanguage isEqualToString:ocrResult.from]) {
                        NSLog(@"OCR detect language: %@", detectedLanguage);
                        firstResult = result;
                        shouldBreak = YES;
                    }
                    if (shouldBreak) {
                        break;
                    }
                }
            }
            
            firstOCRResult = firstResult[@"ocrResult"];
            NSError *error = firstResult[@"error"];
            if ([error isEqual:[NSNull null]]) {
                error = nil;
            }
            
            NSString *mergedText = firstOCRResult.mergedText;
            NSString *logMergedText = [mergedText trimToMaxLength:100];
            NSLog(@"Final ocr: %@(%.2f): %@", firstOCRResult.from, firstOCRResult.confidence, logMergedText);
            
            completion(firstOCRResult, error);
        }
    });
}

- (nullable NSArray<NSString *> *)detectQRCodeImage:(NSImage *)image {
    NSLog(@"detect QRCode image");
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    CGImageRef cgImage = [image CGImageForProposedRect:nil context:nil hints:nil];
    CIImage *ciImage = [CIImage imageWithCGImage:cgImage];
    if (!ciImage) {
        return nil;
    }
    
    CIContext *context = [CIContext context];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:nil];
    NSArray<CIFeature *> *features = [detector featuresInImage:ciImage];
    
    NSMutableArray *result = [NSMutableArray array];
    for (CIQRCodeFeature *feature in features) {
        NSString *text = feature.messageString;
        if (text.length) {
            [result addObject:text];
        }
    }
    
    if (result.count) {
        NSLog(@"QR code results: %@", result);
        
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"detect cost: %.1f ms", (endTime - startTime) * 1000); // ~20ms
        
        return result;
    }
    
    return nil;
}

- (nullable EZOCRResult *)getOCRResultFromQRCodeImage:(NSImage *)image {
    NSArray *qrCodeTexts = [self detectQRCodeImage:image];
    if (qrCodeTexts.count) {
        NSString *text = [qrCodeTexts componentsJoinedByString:@"\n"];

        EZOCRResult *ocrResult = [[EZOCRResult alloc] init];
        ocrResult.texts = qrCodeTexts;
        ocrResult.mergedText = text;
        ocrResult.raw = qrCodeTexts;

        EZLanguage language = [self detectText:text];
        self.queryModel.detectedLanguage = language;
        self.queryModel.autoQuery = NO;

        ocrResult.from = language;
        ocrResult.confidence = 1.0;

        return ocrResult;
    }
    return nil;
}


#pragma mark - Join OCR text array

- (void)setupOCRResult:(EZOCRResult *)ocrResult
               request:(VNRequest *_Nonnull)request
     intelligentJoined:(BOOL)intelligentJoined {
    EZLanguage language = ocrResult.from;
    
    CGFloat minLineHeight = MAXFLOAT;
    CGFloat totalLineHeight = 0;
    CGFloat averageLineHeight = 0;
    
    // OCR line spacing may be less than 0
    CGFloat minLineSpacing = MAXFLOAT;
    CGFloat minPositiveLineSpacing = MAXFLOAT;
    CGFloat totalLineSpacing = 0;
    CGFloat averageLineSpacing = 0;
    
    CGFloat minX = MAXFLOAT;
    CGFloat maxLengthOfLine = 0;
    CGFloat minLengthOfLine = MAXFLOAT;
    
    NSMutableArray *recognizedStrings = [NSMutableArray array];
    NSArray<VNRecognizedTextObservation *> *textObservations = request.results;
    NSInteger lineCount = textObservations.count;
    
    NSInteger lineSpacingCount = 0;
    
    for (int i = 0; i < lineCount; i++) {
        VNRecognizedTextObservation *textObservation = textObservations[i];
        VNRecognizedText *recognizedText = [[textObservation topCandidates:1] firstObject];
        NSString *recognizedString = recognizedText.string;
        [recognizedStrings addObject:recognizedString];
        
        CGRect boundingBox = textObservation.boundingBox;
        NSLog(@"%@, %@", @(boundingBox), recognizedString);
        
        CGFloat lineHeight = boundingBox.size.height;
        totalLineHeight += lineHeight;
        if (lineHeight < minLineHeight) {
            minLineHeight = lineHeight;
        }
        
        if (i > 0) {
            VNRecognizedTextObservation *prevObservation = textObservations[i - 1];
            CGRect prevBoundingBox = prevObservation.boundingBox;
            
            // !!!: deltaY may be < 0, means the [OCR] line frame is overlapped.
            CGFloat deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + boundingBox.size.height);
            
            // If deltaY too big, it is may paragraph, do not add it.
            if (deltaY > 0 && deltaY < averageLineHeight * kParagraphLineHeightRatio) {
                totalLineSpacing += deltaY;
                lineSpacingCount++;
            }
            
            if (deltaY < minLineSpacing) {
                minLineSpacing = deltaY;
            }
            
            if (deltaY > 0 && deltaY < minPositiveLineSpacing) {
                minPositiveLineSpacing = deltaY;
            }
        }
        
        CGFloat x = boundingBox.origin.x;
        if (x < minX) {
            minX = x;
            self.minXLineTextObservation = textObservation;
        }
        
        CGFloat lengthOfLine = boundingBox.size.width;
        if (lengthOfLine > maxLengthOfLine) {
            maxLengthOfLine = lengthOfLine;
            self.maxLongLineTextObservation = textObservation;
        }
        
        if (lengthOfLine < minLengthOfLine) {
            minLengthOfLine = lengthOfLine;
        }
        
        averageLineHeight = totalLineHeight / (i + 1);
        
        if (lineSpacingCount > 0) {
            averageLineSpacing = totalLineSpacing / lineSpacingCount;
        }
    }
    
    self.language = language;
    self.minX = minX;
    self.maxLineLength = maxLengthOfLine;
    self.minLineHeight = minLineHeight;
    
    self.averageLineHeight = averageLineHeight;
    self.averageLineSpacing = averageLineSpacing;
    
    ocrResult.texts = recognizedStrings;
    ocrResult.mergedText = [recognizedStrings componentsJoinedByString:@"\n"];
    
    if (!intelligentJoined) {
        return;
    }
    
    
    NSArray<NSString *> *stringArray = ocrResult.texts;
    NSLog(@"%@", textObservations);
    NSLog(@"ocr stringArray (%@): %@", ocrResult.from, stringArray);
    
    
    BOOL isPoetry = [self isPoetryOftextObservations:textObservations];
    NSLog(@"isPoetry: %d", isPoetry);
    self.isPoetry = isPoetry;
    
    CGFloat confidence = 0;
    NSMutableString *mergedText = [NSMutableString string];
    
    // !!!: Need to Sort textObservations
    textObservations = [self sortedTextObservations:textObservations];
    NSLog(@"%@", textObservations.recognizedTexts);
    
    for (int i = 0; i < lineCount; i++) {
        VNRecognizedTextObservation *textObservation = textObservations[i];
        VNRecognizedText *recognizedText = [[textObservation topCandidates:1] firstObject];
        confidence += recognizedText.confidence;
        
        NSString *recognizedString = recognizedText.string;
        CGRect boundingBox = textObservation.boundingBox;
        NSLog(@"%@ %@", recognizedString, @(boundingBox));
        
        /**
         《摊破浣溪沙》  123  《浣溪沙》
         
         菡萏香销翠叶残，西风愁起绿波间。还与韶光共憔悴，不堪看。
         细雨梦回鸡塞远，小楼吹彻玉笙寒。多少泪珠何限恨，倚阑干。
         
         —— 五代十国 · 李璟
         
         
         《摊破浣溪沙》
         NSRect: {{0.19622092374434116, 0.72371967654986524}, {0.14098837808214662, 0.045082544702082616}}
         
         菡萏香销翠叶残，西风愁起绿波问。还与韶光共憔悴，不堪看。
         NSRect: {{0.18604653059346432, 0.50134770889487879}, {0.65261626210058454, 0.064690026954177804}}
         
         细雨梦回鸡塞远，小楼吹彻玉笙寒。多少泪珠何限恨，倚阑干。
         NSRect: {{0.18604650913243892, 0.40389972491405723}, {0.65406975296814562,
         
         -一五代十国 •李璟
         NSRect: {{0.19583333762553842, 0.26400000065806095}, {0.1833333311872308, 0.048668462953798897}}
         */
        // 如果 i 不是第一个元素，且前一个元素的 boundingBox 的 minY 值大于当前元素的 maxY 值，则认为中间有换行。
        
        if (i > 0) {
            VNRecognizedTextObservation *prevTextObservation = textObservations[i - 1];
            CGRect prevBoundingBox = prevTextObservation.boundingBox;
            
            // !!!: deltaY may be < 0
            CGFloat deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + boundingBox.size.height);
            CGFloat deltaX = boundingBox.origin.x - (prevBoundingBox.origin.x + prevBoundingBox.size.width);
            
            // Note that line spacing is inaccurate, sometimes it's too small 😢
            BOOL isNewParagraph = NO;
            if (deltaY > 0) {
                // averageLineSpacing may too small, so deltaY should be much larger than averageLineSpacing
                BOOL isBigLineSpacing = [self isBigSpacingLineOfTextObservation:textObservation
                                                            prevTextObservation:prevTextObservation
                                                    greaterThanLineSpacingRatio:2.4
                                                     greaterThanLineHeightRatio:kParagraphLineHeightRatio];
                if (isBigLineSpacing) {
                    isNewParagraph = YES;
                }
            }
            
            // Note that sometimes the line frames will overlap a little, then deltaY will less then 0
            BOOL isNewLine = NO;
            if (deltaY > 0) {
                isNewLine = YES;
            } else {
                if (fabs(deltaY) < minLineHeight / 2) {
                    isNewLine = YES;
                }
            }
            
            // System deltaX is about 0.05. If the deltaX of two line is too large, it may be a new line.
            if (deltaX > 0.07) {
                isNewLine = YES;
            }
            
            NSString *joinedString;
            
            BOOL isNeedHandleLastDashOfText = [self isNeedHandleLastDashOfTextObservation:textObservation
                                                                      prevTextObservation:prevTextObservation];
            
            if (isNeedHandleLastDashOfText) {
                joinedString = @"";
                
                BOOL isNeedRemoveLastDashOfText = [self isNeedRemoveLastDashOfTextObservation:textObservation
                                                                          prevTextObservation:prevTextObservation];
                if (isNeedRemoveLastDashOfText) {
                    mergedText = [mergedText substringToIndex:mergedText.length - 1].mutableCopy;
                }
            } else if (isNewParagraph || isNewLine) {
                joinedString = [self joinedStringOfTextObservation:textObservation
                                               prevTextObservation:prevTextObservation
                                                    isNewParagraph:isNewParagraph];
            } else {
                joinedString = @" "; // if the same line, just join two texts
            }
            
            // 1. append joined string
            [mergedText appendString:joinedString];
        } else {
            //            CGFloat x = textObservation.boundingBox.origin.x;
            //            BOOL isEqualX = [self isEqualPrevLineX:self.minX lineX:x];
            //            BOOL hasIndentation = !isEqualX;
            //            if (hasIndentation) {
            //                [mergedText appendString:kIndentationText];
            //            }
        }
        
        // 2. append line text
        [mergedText appendString:recognizedString];
    }
    
    ocrResult.mergedText = [self replaceSimilarDotSymbolOfString:mergedText].trimNewLine;
    ocrResult.texts = [mergedText componentsSeparatedByString:kLineBreakText];
    ocrResult.raw = recognizedStrings;
    
    if (recognizedStrings.count > 0) {
        ocrResult.confidence = confidence / recognizedStrings.count;
    }
    
    NSString *showMergedText = [ocrResult.mergedText trimToMaxLength:100];
    
    NSLog(@"ocr text: %@(%.2f): %@", ocrResult.from, ocrResult.confidence, showMergedText);
}

/// Sort textObservations by textObservation.boundingBox.origin.y
- (NSArray<VNRecognizedTextObservation *> *)sortedTextObservations:(NSArray<VNRecognizedTextObservation *> *)textObservations {
    /**
     NSRect: {{0.07716049382716049, 0.51535836177474403}, {0.87345679012345678, 0.085324232081911311}}, 梦入江南烟水路，行尽江南，不与离人遇。睡里消魂无说处，觉来惆怅
     NSRect: {{0.021604938271604937, 0.37201365187713309}, {0.11111111111111112, 0.078498293515358419}}, 消魂误。
     NSRect: {{0.023148148148148147, 0.08191126279863481}, {0.10956790123456792, 0.085324232081911311}}, 秦筝柱。
     NSRect: {{0.075617283950617287, 0.22525597269624575}, {0.87654320987654322, 0.0853242320819112}}, 欲尽此情书尺素。浮雁沉鱼，终了无凭据。却倚缓弦歌别绪，断肠移破
     */
    NSArray *sortedTextObservations = [textObservations sortedArrayUsingComparator:^NSComparisonResult(VNRecognizedTextObservation *obj1, VNRecognizedTextObservation *obj2) {
        CGRect boundingBox1 = obj1.boundingBox;
        CGRect boundingBox2 = obj2.boundingBox;
        
        CGFloat y1 = boundingBox1.origin.y;
        CGFloat y2 = boundingBox2.origin.y;
        
        if ((y1 - y2) / self.minLineHeight > 0.8)  {
            return NSOrderedAscending; // Next line
        } else {
            return NSOrderedDescending;
        }
    }];
    
    return sortedTextObservations;
}

/// Check if texts is a poetry.
- (BOOL)isPoetryOftextObservations:(NSArray<VNRecognizedTextObservation *> *)textObservations {
    CGFloat lineCount = textObservations.count;
    NSInteger longLineCount = 0;
    
    NSInteger totalCharCount = 0;
    CGFloat charCountPerLine = 0;
    NSInteger punctuationMarkCount = 0;
    NSInteger totalWordCount = 0;
    NSInteger wordCountPerLine = 0;
    
    BOOL isAllEndPunctuationChar = YES;
    
    for (VNRecognizedTextObservation *textObservation in textObservations) {
        BOOL isLongLine = [self isLongTextObservation:textObservation];
        if (isLongLine) {
            longLineCount += 1;
        }
        
        NSString *text = [textObservation firstText];
        totalCharCount += text.length;
        totalWordCount += [EZTextWordUtils wordCount:text];
        
        NSInteger punctuationMarkCountOfLine = 0;
        
        // iterate string to check if has punctuation mark.
        for (NSInteger i = 0; i < text.length; i++) {
            NSString *charString = [text substringWithRange:NSMakeRange(i, 1)];
            NSArray *allowedCharArray = [kAllowedCharactersInPoetryList arrayByAddingObjectsFromArray:EZDashCharacterList];
            BOOL isChar = [self isPunctuationChar:charString excludeCharacters:allowedCharArray];
            if (isChar) {
                punctuationMarkCountOfLine += 1;
            }
            
            BOOL isEndPunctuationChar = [text hasEndPunctuationSuffix];
            if (!isEndPunctuationChar) {
                isAllEndPunctuationChar = NO;
            }
            
            /**
             Cannot be treated as poetry, cannot join with '\n'
             
             　　 京洛风流绝代人，因何风絮落溪津。笼鞋浅出鸦头袜，知是凌波
             　缥缈身。
             　　 红乍笑，绿长颦，与谁同度可怜春。鸳鸯独宿何曾惯，化作西楼
             　一缕云。
             */
            if (punctuationMarkCountOfLine >= 3 && !isEndPunctuationChar) {
                return NO;
            }
        }
        
        punctuationMarkCount += punctuationMarkCountOfLine;
    }
    
    charCountPerLine = totalCharCount / lineCount;
    wordCountPerLine = totalWordCount / lineCount;
    
    CGFloat numberOfPunctuationMarksPerLine = punctuationMarkCount / lineCount;
    
    /**
     独
     坐
     幽
     篁
     里
     */
    if (charCountPerLine < 2) {
        return NO;
    }
    
    // If average number of punctuation marks per line is greater than 2, then it is not poetry.
    if (numberOfPunctuationMarksPerLine > 2) {
        return NO;
    }
    
    if (punctuationMarkCount == 0) {
        /**
         Introducing English as the
         New Programming Language
         for Apache Spark
         */
        
        if (wordCountPerLine >= 5) {
            return YES;
        }
    }
    
    /**
     Works smarter.
      Plays harder.
      Goes further.
     */
    if (isAllEndPunctuationChar) {
        return YES;
    }
    
    /**
     Should >= 0.5, especially two lines.
     
     这首诗以白描手法写江南农村初夏时节的田野风光和农忙景象，
     前两句描绘自然景物
     */
    BOOL tooManyLongLine = longLineCount / lineCount >= 0.5;
    if (tooManyLongLine) {
        return NO;
    }
    
    return YES;
}

/// Get joined string of text, according to its last char.
- (NSString *)joinedStringOfTextObservation:(VNRecognizedTextObservation *)textObservation
                        prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation
                             isNewParagraph:(BOOL)isNewParagraph {
    NSString *joinedString = @"";
    BOOL needLineBreak = NO;
    
    CGRect prevBoundingBox = prevTextObservation.boundingBox;
    CGFloat prevLineLength = prevBoundingBox.size.width;
    NSString *prevText = [prevTextObservation firstText];
    NSString *prevLastChar = prevText.lastChar;
    // Note: sometimes OCR is incorrect, so [.] may be recognized as [,]
    BOOL isPrevEndPunctuationChar = [prevText hasEndPunctuationSuffix];
    
    NSString *text = [textObservation firstText];
    BOOL isEndPunctuationChar = [text hasEndPunctuationSuffix];
    
    BOOL isBigLineSpacing = [self isBigSpacingLineOfTextObservation:textObservation
                                                prevTextObservation:prevTextObservation
                                        greaterThanLineSpacingRatio:2.1
                                         greaterThanLineHeightRatio:1.0];
    
    BOOL hasPrevIndentation = [self hasIndentationOfTextObservation:prevTextObservation];
    BOOL hasIndentation = [self hasIndentationOfTextObservation:textObservation];
    
    BOOL isPrevLongText = [self isLongTextObservation:prevTextObservation];
    
    BOOL isEqualChineseText = [self isEqualChineseTextObservation:textObservation prevTextObservation:prevTextObservation];
    
    BOOL isPrevList = [prevText isListTypeFirstWord];
    BOOL isList = [text isListTypeFirstWord];

    // TODO: Maybe we need to refactor it, each indented paragraph is treated separately, instead of treating them together with the longest text line.
    
    if (hasIndentation) {
        BOOL isEqualX = [self isEqualXOfTextObservation:textObservation prevTextObservation:prevTextObservation];
        
        CGFloat lineX = CGRectGetMinX(textObservation.boundingBox);
        CGFloat prevLineX = CGRectGetMinX(prevTextObservation.boundingBox);
        CGFloat dx = lineX - prevLineX;
        
        if (hasPrevIndentation) {
            if (isBigLineSpacing && !isPrevLongText && !isPrevList && !isList) {
                isNewParagraph = YES;
            }
            
            /**
             Bitcoin: A Peer-to-Peer Electronic Cash System
             
             Satoshi Nakamoto
             satoshin@gmx.com
             www.bitcoin.org
             
             Abstract. A purely peer-to-peer version of electronic cash would allow online
             payments to be sent directly from one party to another without going through a
             */
            BOOL isPrevLessHalfShortLine = [self isShortLineLength:prevLineLength maxLineLength:self.maxLineLength lessRateOfMaxLength:0.5];
            BOOL isPrevShortLine = [self isShortLineLength:prevLineLength maxLineLength:self.maxLineLength lessRateOfMaxLength:0.85];
            
            
            CGFloat lineMaxX = CGRectGetMaxX(textObservation.boundingBox);
            CGFloat prevLineMaxX = CGRectGetMaxX(prevTextObservation.boundingBox);
            BOOL isEqualLineMaxX = [self isRatioGreaterThan:0.95 value1:lineMaxX value2:prevLineMaxX];
            
            BOOL isEqualInnerTwoLine = isEqualX && isEqualLineMaxX;
            
            if (isEqualInnerTwoLine) {
                if (isPrevLessHalfShortLine) {
                    needLineBreak = YES;
                } else {
                    if (isEqualChineseText) {
                        needLineBreak = YES;
                    } else {
                        needLineBreak = NO;
                    }
                }
            } else {
                if (isPrevLongText) {
                    if (isPrevEndPunctuationChar) {
                        needLineBreak = YES;
                    } else {
                        /**
                         V. SECURITY CHALLENGES AND OPPORTUNITIES
                         In the following, we discuss existing security challenges
                         and shed light on possible security opportunities and research
                         */
                        if (!isEqualX && dx < 0) {
                            isNewParagraph = YES;
                        } else {
                            needLineBreak = NO;
                        }
                    }
                } else {
                    if (isPrevEndPunctuationChar) {
                        if (!isEqualX && !isList) {
                            isNewParagraph = YES;
                        } else {
                            needLineBreak = YES;
                        }
                    } else {
                        if (isPrevShortLine) {
                            needLineBreak = YES;
                        } else {
                            needLineBreak = NO;
                        }
                    }
                }
            }
        } else {
            // Sometimes has hasIndentation is a mistake, when prev line is long.
            /**
             当您发现严重的崩溃问题后，通常推荐发布一个新的版本来修复该问题。这样做有以下几
             个原因：
             
             1. 保持版本控制：通过发布一个新版本，您可以清晰地记录修复了哪些问题。这对于用
             户和开发团队来说都是透明和易于管理的。
             2. 便于用户更新：通过发布新版本，您可以通知用户更新应用程序以修复问题。这样，
             用户可以轻松地通过应用商店或更新机制获取到修复后的版本。
             
             The problem with this solution is that the fate of  the  entire  money  system depends  on  the
             company running the mint, with every transaction having to go through them, just like a bank.
             We need a way for the payee to know that the previous owners  did  not  sign   any   earlier
             transactions.
             */
            
            if (isPrevLongText) {
                if (isPrevEndPunctuationChar) {
                    isNewParagraph = YES;
                } else {
                    if (!isEqualX && dx > 0) {
                        needLineBreak = NO;
                    } else {
                        needLineBreak = YES;
                    }
                }
            } else {
                isNewParagraph = YES;
            }
        }
    } else {
        if (hasPrevIndentation) {
            needLineBreak = YES;
        }
        
        if (isBigLineSpacing) {
            if (isPrevLongText) {
                if (self.isPoetry) {
                    needLineBreak = YES;
                } else {
                    needLineBreak = NO;
                    // 翻页, Page turn scenes without line feeds.
                    if (!isPrevEndPunctuationChar) {
                        isNewParagraph = NO;
                    }
                }
            } else {
                if (isPrevEndPunctuationChar || hasPrevIndentation) {
                    isNewParagraph = YES;
                } else {
                    needLineBreak = YES;
                }
            }
        } else {
            if (isPrevLongText) {
                if (hasPrevIndentation) {
                    needLineBreak = NO;
                }
                
                /**
                 人绕湘皋月坠时。斜横花树小，浸愁漪。一春幽事有谁知。东风冷、香远茜裙归。
                 鸥去昔游非。遥怜花可可，梦依依。九疑云杳断魂啼。相思血，都沁绿筠枝。
                 */
                if (isPrevEndPunctuationChar && isEndPunctuationChar) {
                    needLineBreak = YES;
                }
            } else {
                needLineBreak = YES;
                if (hasPrevIndentation && !isPrevEndPunctuationChar) {
                    isNewParagraph = YES;
                }
            }
            
            if (self.isPoetry) {
                needLineBreak = YES;
            }
        }
        
        /**
         Chinese poetry needs line break
         
         《鹧鸪天 · 正月十一日观灯》
         
         巷陌风光纵赏时，笼纱未出马先嘶。白头居士无呵殿，只有乘肩小女随。
         花满市，月侵衣，少年情事老来悲。沙河塘上春寒浅，看了游人缓缓归。
         
         —— 宋 · 姜夔
         */
        if (isEqualChineseText) {
            needLineBreak = YES;
            if (isBigLineSpacing) {
                isNewParagraph = YES;
            }
        }
    }
    
    if (isPrevList && isList) {
        needLineBreak = YES;

        isNewParagraph = isBigLineSpacing;
    }
    
    if (isNewParagraph) {
        joinedString = kParagraphBreakText;
    } else if (needLineBreak) {
        joinedString = kLineBreakText;
    } else if ([self isPunctuationChar:prevLastChar]) {
        // if last char is a punctuation mark, then append a space, since ocr will remove white space.
        joinedString = @" ";
    } else {
        // Like Chinese text, don't need space between words if it is not a punctuation mark.
        if ([self isLanguageWordsNeedSpace:self.language]) {
            joinedString = @" ";
        }
    }
    
    //    if (hasIndentation) {
    //        joinedString = [joinedString stringByAppendingString:kIndentationText];
    //    }
    
    return joinedString;
}

/// Equal character length && has end punctuation suffix
- (BOOL)isEqualCharacterLengthTextObservation:(VNRecognizedTextObservation *)textObservation
                          prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation {
    /**
     巷陌风光纵赏时，笼纱未出马先嘶。白头居士无呵殿，只有乘肩小女随。
     花满市，月侵衣，少年情事老来悲。沙河塘上春寒浅，看了游人缓缓归。
     */
    BOOL isEqual = [self isEqualTextObservation:textObservation prevTextObservation:prevTextObservation];
    
    NSString *text = [textObservation firstText];
    NSString *prevText = [prevTextObservation firstText];
    BOOL isEqualLength = text.length == prevText.length;
    BOOL isEqualEndSuffix = text.hasEndPunctuationSuffix && prevText.hasEndPunctuationSuffix;
    
    if (isEqual && isEqualLength && isEqualEndSuffix) {
        return YES;
    }
    return NO;
}

- (BOOL)isEqualChineseTextObservation:(VNRecognizedTextObservation *)textObservation
                  prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation {
    BOOL isEqualLength = [self isEqualCharacterLengthTextObservation:textObservation prevTextObservation:prevTextObservation];
    if (isEqualLength && [EZLanguageManager.shared isChineseLanguage:self.language]) {
        return YES;
    }
    return NO;
}


// TODO: Some text has large line spacing, which can lead to misjudgments.
- (BOOL)isBigSpacingLineOfTextObservation:(VNRecognizedTextObservation *)textObservation
                      prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation
              greaterThanLineSpacingRatio:(CGFloat)greaterThanLineSpacingRatio
               greaterThanLineHeightRatio:(CGFloat)greaterThanLineHeightRatio {
    //  lineHeightRatio = 1.2, 1.0
    BOOL isBigLineSpacing = NO;
    CGRect prevBoundingBox = prevTextObservation.boundingBox;
    CGRect boundingBox = textObservation.boundingBox;
    CGFloat lineHeight = boundingBox.size.height;
    
    CGFloat lineHeightRatioThreshold = 1.0;
    
    
    // !!!: deltaY may be < 0
    CGFloat deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + lineHeight);
    CGFloat lineHeightRatio = deltaY / lineHeight;
    CGFloat averageLineSpacingRatio = deltaY / self.averageLineSpacing;
    CGFloat averagerLineHeightRatio = deltaY / self.averageLineHeight;
    
    CGFloat minLineHeightRatio = 0.65;
    /**
     FIXME: https://github.com/tisfeng/Easydict/issues/16
     
     Since English text line height is smaller than Chinese, the ratio should be bigger, but if it is too large, it may affect the normal line break of the paragraph 😢
     */
    BOOL isEnglishTypeLanguage = [self isLanguageWordsNeedSpace:self.language];
    if (isEnglishTypeLanguage) {
        minLineHeightRatio = 0.8;
    }
    
    // Since line spacing sometimes is too small and imprecise, we do not use it.
    if (lineHeightRatio > lineHeightRatioThreshold ||
        averageLineSpacingRatio > greaterThanLineSpacingRatio ||
        averagerLineHeightRatio > greaterThanLineHeightRatio ||
        (lineHeightRatio / lineHeightRatioThreshold > minLineHeightRatio && averagerLineHeightRatio / greaterThanLineHeightRatio > 0.75)) {
        isBigLineSpacing = YES;
        //        NSLog(@"is big line spacing: %@", textObservation.firstText);
    }
    return isBigLineSpacing;
}

- (BOOL)isNeedHandleLastDashOfTextObservation:(VNRecognizedTextObservation *)textObservation
                          prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation {
    NSString *text = [textObservation firstText];
    NSString *prevText = [prevTextObservation firstText];
    
    CGFloat maxLineFrameX = CGRectGetMaxX(prevTextObservation.boundingBox);
    BOOL isPrevLongLine = [self isLongLineLength:maxLineFrameX maxLineLength:self.maxLineLength];
    //    BOOL hasIndentation = [self hasIndentationOfTextObservation:textObservation];
    
    BOOL isPrevLastDashChar = [self isLastJoinedDashCharactarInText:text prevText:prevText];
    return isPrevLongLine && isPrevLastDashChar;
}

/// Called when isNeedHandleLastDashOfTextObservation is YES
- (BOOL)isNeedRemoveLastDashOfTextObservation:(VNRecognizedTextObservation *)textObservation
                          prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation {
    NSString *text = [textObservation firstText];
    NSString *prevText = [prevTextObservation firstText];
    
    NSString *removedPrevDashText = [prevText substringToIndex:prevText.length - 1].mutableCopy;
    NSString *lastWord = [removedPrevDashText lastWord];
    NSString *firstWord = [text firstWord];
    NSString *newWord = [NSString stringWithFormat:@"%@%@", lastWord, firstWord];
    
    // Request-Response, Architec-ture
    BOOL isLowercaseWord = [firstWord isLowercaseString];
    BOOL isSpelledCorrectly = [EZTextWordUtils isSpelledCorrectly:newWord];
    if (isLowercaseWord && isSpelledCorrectly) {
        return YES;
    }
    return NO;
}

- (BOOL)hasIndentationOfTextObservation:(VNRecognizedTextObservation *)textObservation {
    BOOL isEqualX = [self isEqualXOfTextObservation:textObservation prevTextObservation:self.minXLineTextObservation];
    BOOL hasIndentation = !isEqualX;
    return hasIndentation;
}

- (BOOL)isEqualTextObservation:(VNRecognizedTextObservation *)textObservation
           prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation {
    // 0.06 - 0.025
    BOOL isEqualX = [self isEqualXOfTextObservation:textObservation prevTextObservation:prevTextObservation];
    
    CGFloat lineMaxX = CGRectGetMaxX(textObservation.boundingBox);
    CGFloat prevLineMaxX = CGRectGetMaxX(prevTextObservation.boundingBox);
    
    CGFloat ratio = 0.95;
    BOOL isEqualLineMaxX = [self isRatioGreaterThan:ratio value1:lineMaxX value2:prevLineMaxX];
    
    if (isEqualX && isEqualLineMaxX) {
        return YES;
    }
    return NO;
}

- (BOOL)isEqualXOfTextObservation:(VNRecognizedTextObservation *)textObservation
              prevTextObservation:(VNRecognizedTextObservation *)prevTextObservation {
    /**
     test data
     image width: 900, indentation: 3 white space, deltaX = 0.016,
     threshold = 900 * 0.016 = 14.4
     
     But sometimes OCR frame is imprecise, so threshold should be bigger.
     */
    CGFloat threshold = 22;
    
    // lineX > prevLineX
    CGFloat lineX = textObservation.boundingBox.origin.x;
    CGFloat prevLineX = prevTextObservation.boundingBox.origin.x;
    CGFloat dx = lineX - prevLineX;
    
    CGFloat maxLength = self.ocrImage.size.width * self.maxLineLength;
    CGFloat difference = maxLength * dx;
    
    if ((difference > 0 && difference < threshold) || fabs(difference) < (threshold / 2)) {
        return YES;
    }
    NSLog(@"not equal x difference: %.1f", difference);
    return NO;
}

- (BOOL)isEqualLength:(CGFloat)length comparedLength:(CGFloat)compareLength {
    return [self isRatioGreaterThan:0.98 value1:length value2:compareLength];
}

- (BOOL)isRatioGreaterThan:(CGFloat)ratio value1:(CGFloat)value1 value2:(CGFloat)value2 {
    //  99 / 100 > 0.98
    CGFloat minValue = MIN(value1, value2);
    CGFloat maxValue = MAX(value1, value2);
    return (minValue / maxValue) > ratio;
}

- (BOOL)isLongTextObservation:(VNRecognizedTextObservation *)textObservation {
    return [self isLongTextObservation:textObservation comparedTextObservation:self.maxLongLineTextObservation];
}

- (BOOL)isLongTextObservation:(VNRecognizedTextObservation *)textObservation
      comparedTextObservation:(VNRecognizedTextObservation *)comparedTextObservation {
    // Two Chinese words length
    CGFloat threshold = 80;
    BOOL isEnglishTypeLanguage = [self isLanguageWordsNeedSpace:self.language];
    if (isEnglishTypeLanguage) {
        threshold = 230; // This value is related to the font size, take the average, and a bit larger.
    }
    
    CGFloat dx = CGRectGetMaxX(comparedTextObservation.boundingBox) - CGRectGetMaxX(textObservation.boundingBox);
    CGFloat maxLength = self.ocrImage.size.width * self.maxLineLength;
    CGFloat difference = maxLength * dx;
    
    if (difference < threshold) {
        return YES;
    }
    return NO;
}


/// Check if the last char ot text is a joined dash.
- (BOOL)isLastJoinedDashCharactarInText:(NSString *)text prevText:(NSString *)prevText {
    if (prevText.length == 0 || prevText.length == 0) {
        return NO;
    }
    
    NSString *prevLastChar = prevText.lastChar;
    BOOL isPrevLastDashChar = [EZDashCharacterList containsObject:prevLastChar];
    if (isPrevLastDashChar) {
        NSString *removedPrevDashText = [prevText substringToIndex:prevText.length - 1].mutableCopy;
        NSString *lastWord = [removedPrevDashText lastWord];
        
        BOOL isFirstCharAlphabet = [text.firstChar isAlphabet];
        if (lastWord.length > 0 && isFirstCharAlphabet) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isShortLineLength:(CGFloat)lineLength
            maxLineLength:(CGFloat)maxLineLength {
    return [self isShortLineLength:lineLength maxLineLength:maxLineLength lessRateOfMaxLength:0.85];
}

- (BOOL)isShortLineLength:(CGFloat)lineLength
            maxLineLength:(CGFloat)maxLineLength
      lessRateOfMaxLength:(CGFloat)lessRateOfMaxLength {
    BOOL isShortLine = lineLength < maxLineLength * lessRateOfMaxLength;
    return isShortLine;
}

- (BOOL)isLongLineLength:(CGFloat)lineLength
           maxLineLength:(CGFloat)maxLineLength {
    return [self isLongLineLength:lineLength maxLineLength:maxLineLength greaterRateOfMaxLength:0.9];
}

- (BOOL)isLongLineLength:(CGFloat)lineLength
           maxLineLength:(CGFloat)maxLineLength
  greaterRateOfMaxLength:(CGFloat)greaterRateOfMaxLength {
    BOOL isLongLine = lineLength >= maxLineLength * greaterRateOfMaxLength;
    return isLongLine;
}

- (BOOL)isPoetryCharactersOfLineText:(NSString *)lineText language:(EZLanguage)language {
    NSInteger charactersCount = lineText.length;
    return [self isPoetryLineCharactersCount:charactersCount language:language];
}

- (BOOL)isPoetryLineCharactersCount:(NSInteger)charactersCount language:(EZLanguage)language {
    BOOL isPoetry = NO;
    NSInteger charCountPerLineOfPoetry = 50;
    if ([EZLanguageManager.shared isChineseLanguage:language]) {
        charCountPerLineOfPoetry = 40;
    }
    
    if (charactersCount <= charCountPerLineOfPoetry) {
        isPoetry = YES;
    }
    
    return isPoetry;
}

/// Languages that don't need extra space for words, generally non-Engglish alphabet languages.
- (BOOL)isLanguageWordsNeedSpace:(EZLanguage)language {
    NSArray *languages = @[
        EZLanguageSimplifiedChinese,
        EZLanguageTraditionalChinese,
        EZLanguageJapanese,
        EZLanguageKorean,
    ];
    return ![languages containsObject:language];
}


#pragma mark - Apple Speech Synthesizer

- (nullable NSString *)voiceIdentifierFromLanguage:(EZLanguage)language {
    NSString *voiceIdentifier = nil;
    EZLanguageModel *languageModel = [EZLanguageManager.shared languageModelFromLanguage:language];
    NSString *localeIdentifier = languageModel.localeIdentifier;
    
    NSArray *availableVoices = [NSSpeechSynthesizer availableVoices];
    for (NSString *voice in availableVoices) {
        //        NSLog(@"%@", voice);
        NSDictionary *attributesForVoice = [NSSpeechSynthesizer attributesForVoice:voice];
        NSString *voiceLocaleIdentifier = attributesForVoice[NSVoiceLocaleIdentifier];
        if ([voiceLocaleIdentifier isEqualToString:localeIdentifier]) {
            voiceIdentifier = attributesForVoice[NSVoiceIdentifier];
            // a language has multiple voice, we use compact type.
            if ([voiceIdentifier containsString:@"compact"]) {
                return voiceIdentifier;
            }
        }
    }
    
    return voiceIdentifier;
}

- (void)say {
    // 创建语音合成器。
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    // 创建一个语音合成器的语音。
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"The quick brown fox jumped over the lazy dog."];
    // 配置语音。
    utterance.rate = 0.57;
    utterance.pitchMultiplier = 0.8;
    utterance.postUtteranceDelay = 0.2;
    utterance.volume = 0.8;
    
    // 检索英式英语的声音。
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:nil];
    
    //    NSArray<AVSpeechSynthesisVoice *> *speechVoices = [AVSpeechSynthesisVoice speechVoices];
    //    NSLog(@"speechVoices: %@", speechVoices);
    
    // 将语音分配给语音合成器。
    utterance.voice = voice;
    // 告诉语音合成器来讲话。
    [synthesizer speakUtterance:utterance];
}


#pragma mark - Manually detect language, simply

/// Get Chinese language type of text, traditional or simplified. If it is not Chinese, return EZLanguageAuto.
/// If it is Chinese, try to remove all English characters, then check if it is traditional or simplified.
/// - !!!: Make sure the count of Chinese characters is > 50% of the entire text.
/// test: 開門 open, 使用 OCR 123$, 月によく似た風景, アイス・スノーセーリング世界選手権大会
- (EZLanguage)chineseLanguageTypeOfText:(NSString *)text fromLanguage:(EZLanguage)language {
    text = [EZTextWordUtils removeNonNormalCharacters:text];
    
    if (text.length == 0) {
        return EZLanguageAuto;
    }
    
    if ([language isEqualToString:EZLanguageEnglish]) {
        NSString *noAlphabetText = [EZTextWordUtils removeAlphabet:text];
        
        BOOL isChinese = [self isChineseText:noAlphabetText];
        if (isChinese) {
            NSInteger chineseLength = [self chineseCharactersLength:noAlphabetText];
            // Since 1 Chinese character is approximately 1 English word, approximately 4 English characters.
            if (chineseLength * 4 > text.length * 0.5) {
                EZLanguage chineseLanguage = [self chineseLanguageTypeOfText:noAlphabetText];
                return chineseLanguage;
            }
        }
    }
    
    return EZLanguageAuto;
}

/// Count Chinese characters length in string.
- (NSInteger)chineseCharactersLength:(NSString *)string {
    __block NSInteger length = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *_Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL *_Nonnull stop) {
        if ([self isChineseText:substring]) {
            length++;
        }
    }];
    return length;
}

/// Check if text is Chinese.
- (BOOL)isChineseText:(NSString *)text {
    EZLanguage language = [self appleDetectTextLanguage:text];
    if ([EZLanguageManager.shared isChineseLanguage:language]) {
        return YES;
    }
    return NO;
}


/// Check Chinese language type of text, traditional or simplified.
/// - !!!: Make sure the text is Chinese.
- (EZLanguage)chineseLanguageTypeOfText:(NSString *)chineseText {
    // test: 狗，勿 --> zh-Hant --> zh-Hans
    
    // Check if simplified Chinese.
    if ([chineseText isSimplifiedChinese]) {
        return EZLanguageSimplifiedChinese;
    }
    
    return EZLanguageTraditionalChinese;
}


#pragma mark - Check character punctuation

/// Use punctuationCharacterSet to check if it is a punctuation mark.
- (BOOL)isPunctuationChar:(NSString *)charString {
    return [self isPunctuationChar:charString excludeCharacters:nil];
}

- (BOOL)isPunctuationChar:(NSString *)charString excludeCharacters:(nullable NSArray *)charArray {
    if (charString.length != 1) {
        return NO;
    }
    
    if ([charArray containsObject:charString]) {
        return NO;
    }
    
    NSCharacterSet *punctuationCharacterSet = [NSCharacterSet punctuationCharacterSet];
    return [punctuationCharacterSet characterIsMember:[charString characterAtIndex:0]];
}


/// Use regex to check if it is a punctuation mark.
- (BOOL)isPunctuationMark2:(NSString *)charString {
    if (charString.length != 1) {
        return NO;
    }
    
    NSString *regex = @"[\\p{Punct}]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:charString];
}


/// Check if char is a punctuation mark but not a end punctuation mark.
- (BOOL)isNonEndPunctuationMark:(NSString *)charString {
    if (charString.length != 1) {
        return NO;
    }
    
    NSArray *punctuationMarks = @[ @"，", @"、", @"；", @",", @";" ];
    return [punctuationMarks containsObject:charString];
}


#pragma mark - Handle special characters

/// Use NSCharacterSet to replace simlar dot sybmol with char "·"
- (NSString *)replaceSimilarDotSymbolOfString:(NSString *)string {
    // 《蝶恋花 • 阅尽天涯离别苦》
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"•‧∙"];
    //    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@"·"];
    
    NSString *text = string;
    NSArray *strings = [string componentsSeparatedByCharactersInSet:charSet];
    
    if (strings.count > 1) {
        // Remove extra white space.
        NSMutableArray *array = [NSMutableArray array];
        for (NSString *string in strings) {
            NSString *text = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (text.length > 0) {
                [array addObject:text];
            }
        }
        
        // Add white space for better reading.
        text = [array componentsJoinedByString:@" · "];
    }
    
    return text;
}

/// Use regex to replace simlar dot sybmol with char "·"
- (NSString *)replaceSimilarDotSymbolOfString2:(NSString *)string {
    NSString *regex = @"[•‧∙]"; // [•‧∙・]
    NSString *text = [string stringByReplacingOccurrencesOfString:regex withString:@"·" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)];
    return text;
}

@end
