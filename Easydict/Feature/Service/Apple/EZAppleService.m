//
//  EZAppleService.m
//  Easydict
//
//  Created by tisfeng on 2022/11/29.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAppleService.h"
#import <Vision/Vision.h>
#import <NaturalLanguage/NaturalLanguage.h>

@implementation EZAppleService

#pragma mark - 子类重写

- (EZServiceType)serviceType {
    return EZServiceTypeApple;
}

- (NSString *)name {
    return @"Apple";
}

- (NSString *)link {
    return @"";
}

// Currently supports 48 languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, Spanish, Portuguese, Italian, German, Russian, Arabic, Swedish, Romanian, Thai, Slovak, Dutch, Hungarian, Greek, Danish, Finnish, Polish, Czech, Turkish, Lithuanian, Latvian, Ukrainian, Bulgarian, Indonesian, Malay, Slovenian, Estonian, Vietnamese, Persian, Hindi, Telugu, Tamil, Urdu, Filipino, Khmer, Lao, Bengali, Burmese, Norwegian, Serbian, Croatian, Mongolian, Hebrew.

// get supportLanguagesDictionary, key is EZLanguage, value is NLLanguage, such as EZLanguageAuto, NLLanguageUndetermined
- (MMOrderedDictionary *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, NLLanguageUndetermined,
                                        EZLanguageSimplifiedChinese, NLLanguageSimplifiedChinese,
                                        EZLanguageTraditionalChinese, NLLanguageTraditionalChinese,
                                        EZLanguageEnglish, NLLanguageEnglish,
                                        EZLanguageJapanese, NLLanguageJapanese,
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
}

/// Apple System language recognize.
- (void)detect:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    // Ref: https://developer.apple.com/documentation/naturallanguage/identifying_the_language_in_text?language=objc
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // macos(10.14)
    NLLanguageRecognizer *recognizer = [[NLLanguageRecognizer alloc] init];
    
    // Because Apple text recognition is often inaccurate, we need to limit the recognition language type.
    recognizer.languageConstraints = [self constraintLanguages];
    recognizer.languageHints = [self customLanguageHints];
    
    [recognizer processString:text];
    
    NSDictionary<NLLanguage, NSNumber *> *languageDict = [recognizer languageHypothesesWithMaximum:5];
    NSLog(@"language dict: %@", languageDict);
    
    NLLanguage dominantLanguage = recognizer.dominantLanguage;
    NSLog(@"dominant Language: %@", dominantLanguage);
    
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"detect cost: %.1f ms", (endTime - startTime) * 1000);
    
    EZLanguage mostConfidentLanguage = [self getMostConfidentLanguage:languageDict];
    
    if ([self isAlphabet:text]) {
        mostConfidentLanguage = EZLanguageEnglish;
        NSLog(@"%@ isAlphabet, correct to English", text);
    }
    
    completion(mostConfidentLanguage, nil);
}


/// Apple System ocr. Use Vision to recognize text in the image. Cost ~400ms
- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    // Convert NSImage to CGImage
    CGImageRef cgImage = [queryModel.image CGImageForProposedRect:NULL context:nil hints:nil];
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // Ref: https://developer.apple.com/documentation/vision/recognizing_text_in_images?language=objc
    
    // Create a new image-request handler. macos(10.13)
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
    // Create a new request to recognize text.
    if (@available(macOS 10.15, *)) {
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *_Nonnull request, NSError *_Nullable error) {
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            NSLog(@"ocr cost: %.1f ms", (endTime - startTime) * 1000);
            
            EZOCRResult *result = [[EZOCRResult alloc] init];
            result.from = queryModel.sourceLanguage;
            result.to = queryModel.targetLanguage;
            
            if (error) {
                completion(result, error);
                return;
            }
            
            NSMutableArray *recognizedStrings = [NSMutableArray array];
            for (VNRecognizedTextObservation *observation in request.results) {
                VNRecognizedText *recognizedText = [[observation topCandidates:1] firstObject];
                [recognizedStrings addObject:recognizedText.string];
            }
            
            result.texts = recognizedStrings;
            result.mergedText = [recognizedStrings componentsJoinedByString:@"\n"];
            result.raw = recognizedStrings;
            
            NSLog(@"ocr text: %@", recognizedStrings);
            
            completion(result, nil);
        }];
        
        
        if (@available(macOS 12.0, *)) {
            //            NSError *error;
            //            NSArray<NSString *> *supportedLanguages = [request supportedRecognitionLanguagesAndReturnError:&error];
            // "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ko-KR", "ja-JP", "ru-RU", "uk-UA"
            //            NSLog(@"supported Languages: %@", supportedLanguages);
        }
        
        NSMutableArray *recognitionLanguages = [NSMutableArray arrayWithArray:@[
            @"zh-Hans",
            @"zh-Hant",
            @"en-US",
            @"ja-JP",
            @"fr-FR",
            @"it-IT",
            @"de-DE",
            @"es-ES",
            @"pt-BR",
            @"yue-Hans",
            @"yue-Hant",
            @"ko-KR",
            @"ru-RU",
            @"uk-UA",
        ]];
        
        EZLanguage sourceLanguage = queryModel.sourceLanguage;
        if ([sourceLanguage isEqualToString:EZLanguageAuto]) {
            if (@available(macOS 13.0, *)) {
                request.automaticallyDetectsLanguage = YES;
            }
        } else {
            // If has designated ocr language, move it to first priority.
            NSString *appleOCRLangaugeCode = [[self ocrLanguageDictionary] objectForKey:sourceLanguage];
            [recognitionLanguages removeObject:appleOCRLangaugeCode];
            
            if (appleOCRLangaugeCode.length > 0) {
                [recognitionLanguages insertObject:appleOCRLangaugeCode atIndex:0];
            }
        }
        request.recognitionLanguages = recognitionLanguages; // ISO language codes
        
        // TODO: need to test it.
        request.usesLanguageCorrection = YES;
        
        // Perform the text-recognition request.
        [requestHandler performRequests:@[ request ] error:nil];
    } else {
        // Fallback on earlier versions
    }
}

- (void)audio:(NSString *)text from:(EZLanguage)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
}


- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
}

#pragma mark - Others

// uniqueLanguages is supportLanguagesDictionary remove some languages
- (NSArray<NLLanguage> *)constraintLanguages {
    NSArray<NLLanguage> *supportLanguages = [[self supportLanguagesDictionary] allValues];
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
        NLLanguageEnglish : @(2.0),
        NLLanguageSimplifiedChinese : @(0.8),
        NLLanguageJapanese : @(0.7),
        NLLanguageFrench : @(0.45), // const, ex
        NLLanguageKorean : @(0.4),
        NLLanguageGerman : @(0.15), // usa
        NLLanguageTraditionalChinese : @(0.2),
        NLLanguageItalian : @(0.1), // via
        NLLanguageSpanish : @(0.1), // favor
        
        NLLanguagePortuguese : @(0.05), // favor, e
        NLLanguageDutch : @(0.01),   // heel, via
        NLLanguageCzech : @(0.01),      // pro
    };
    
    NSArray<NLLanguage> *allSupportedLanguages = [[self supportLanguagesDictionary] allValues];
    NSMutableDictionary<NLLanguage, NSNumber *> *languageHints = [NSMutableDictionary dictionary];
    for (NLLanguage language in allSupportedLanguages) {
        languageHints[language] = @(0.01);
    }
    
    [languageHints addEntriesFromDictionary:customHints];
    
    return languageHints;
}

- (NSDictionary<EZLanguage, NSNumber *> *)userPreferredLanguageProbabilities {
    NSArray *preferredLanguages = [EZLanguageManager systemPreferredLanguages];
    
    // TODO: need to test more data. Maybe need to write a unit test.
    
    /**
     Increase the proportional weighting of the user's preferred language.
     
     1. Chinese, + 0.5
     2. English, + 0.3
     3. Japanese, + 0.1
     4. ........, + 0.1
     
     Since English is so widely used, we need to add additional weighting, + 0.3
     
     */
    NSMutableDictionary<EZLanguage, NSNumber *> *languageProbabilities = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < preferredLanguages.count; i++) {
        EZLanguage language = preferredLanguages[i];
        CGFloat maxWeight = 0.5;
        CGFloat weight = maxWeight - i * 0.2;
        if (weight < 0.1) {
            weight = 0.1;
        }
        if ([language isEqualToString:EZLanguageEnglish]) {
            if (![EZLanguageManager isEnglishFirstLanguage]) {
                weight += 0.3;
            } else {
                weight += 0.1;
            }
        }
        languageProbabilities[language] = @(weight);
    }
    
    if (![preferredLanguages containsObject:EZLanguageEnglish]) {
        languageProbabilities[EZLanguageEnglish] = @(0.2);
    }
    
    return languageProbabilities;
}


/// Get most confident language.
/// languageDict value add userPreferredLanguageProbabilities, then sorted by value, return max dict value.
- (EZLanguage)getMostConfidentLanguage:(NSDictionary<NLLanguage, NSNumber *> *)defaultLanguageProbabilities {
    NSMutableDictionary<NLLanguage, NSNumber *> *languageProbabilities = [NSMutableDictionary dictionaryWithDictionary:defaultLanguageProbabilities];
    NSDictionary<EZLanguage, NSNumber *> *userPreferredLanguageProbabilities = [self userPreferredLanguageProbabilities];
    
    for (EZLanguage language in userPreferredLanguageProbabilities.allKeys) {
        NLLanguage appleLanguage = [self languageCodeForLanguage:language];
        CGFloat defaultProbability = [defaultLanguageProbabilities[appleLanguage] doubleValue];
        if (defaultProbability) {
            NSNumber *userPreferredLanguageProbability = userPreferredLanguageProbabilities[language];
            languageProbabilities[appleLanguage] = @(defaultProbability + userPreferredLanguageProbability.doubleValue);
        }
    }
    
    NSLog(@"language probabilities: %@", languageProbabilities);
    
    NSArray<NLLanguage> *sortedLanguages = [languageProbabilities keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    
    NLLanguage mostConfidentLanguage = sortedLanguages.firstObject;
    EZLanguage ezLanguage = [self languageEnumFromCode:mostConfidentLanguage];
    
    NSLog(@"---> Apple detect: %@", ezLanguage);
    
    return ezLanguage;
}

/// Check if it is a single letter of the alphabet.
- (BOOL)isAlphabet:(NSString *)string {
    if (string.length != 1) {
        return NO;
    }
    
    NSString *regex = @"[a-zA-Z]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:string];
}

@end
