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

- (NSString *)identifier {
    return @"Apple";
}

- (NSString *)name {
    return @"Apple";
}

- (NSString *)link {
    return @"";
}

- (MMOrderedDictionary *)supportLanguagesDictionary {
    MMOrderedDictionary *orderDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                      @(Language_auto), NLLanguageUndetermined,
                                      @(Language_zh_Hans), NLLanguageSimplifiedChinese,
                                      @(Language_zh_Hant), NLLanguageTraditionalChinese,
                                      @(Language_en), NLLanguageEnglish,
                                      @(Language_ja), NLLanguageJapanese,
                                      @(Language_fr), NLLanguageFrench,
                                      @(Language_ko), NLLanguageKorean,
                                      @(Language_it), NLLanguageItalian,
                                      @(Language_de), NLLanguageGerman,
                                      @(Language_es), NLLanguageSpanish,
                                      @(Language_pt), NLLanguagePortuguese,
                                      @(Language_ru), NLLanguageRussian,
                                      
                                      @(Language_ar), NLLanguageArabic,
                                      @(Language_sv), NLLanguageSwedish,
                                      @(Language_ro), NLLanguageRomanian,
                                      @(Language_th), NLLanguageThai,
                                      @(Language_sk), NLLanguageSlovak,
                                      @(Language_nl), NLLanguageDutch,
                                      @(Language_hu), NLLanguageHungarian,
                                      @(Language_el), NLLanguageGreek,
                                      @(Language_da), NLLanguageDanish,
                                      @(Language_fi), NLLanguageFinnish,
                                      @(Language_pl), NLLanguagePolish,
                                      @(Language_cs), NLLanguageCzech,
                                      @(Language_uk), NLLanguageUkrainian,
                                      
                                      @(Language_bn), NLLanguageBengali,
                                      @(Language_ca), NLLanguageCatalan,
                                      @(Language_he), NLLanguageHebrew,
                                      @(Language_hi), NLLanguageHindi,
                                      @(Language_id), NLLanguageIndonesian,
                                      @(Language_no), NLLanguageNorwegian,
                                      @(Language_tr), NLLanguageTurkish,
                                      @(Language_vi), NLLanguageVietnamese,
                                      @(Language_ps), NLLanguagePersian,
                                      @(Language_am), NLLanguageAmharic,
                                      @(Language_bg), NLLanguageBulgarian,
                                      @(Language_gu), NLLanguageGujarati,
                                      @(Language_hr), NLLanguageCroatian,
                                      @(Language_hy), NLLanguageArmenian,
                                      @(Language_is), NLLanguageIcelandic,
                                      @(Language_ka), NLLanguageGeorgian,
                                      @(Language_km), NLLanguageKhmer,
                                      @(Language_kn), NLLanguageKannada,
                                      @(Language_lo), NLLanguageLao,
                                      @(Language_ml), NLLanguageMalayalam,
                                      @(Language_mn), NLLanguageMongolian,
                                      @(Language_mr), NLLanguageMarathi,
                                      @(Language_ms), NLLanguageMalay,
                                      @(Language_my), NLLanguageBurmese,
                                      
                                      nil];
    
    if (@available(macOS 13.0, *)) {
        [orderDict setObject:NLLanguageKazakh forKey:@(Language_kk)];
    }
    
    return orderDict;
}

- (void)translate:(NSString *)text from:(Language)from to:(Language)to completion:(void (^)(TranslateResult *_Nullable, NSError *_Nullable))completion {
}

/// Apple System language recognize.
- (void)detect:(NSString *)text completion:(void (^)(Language, NSError *_Nullable))completion {
    // Ref: https://developer.apple.com/documentation/naturallanguage/identifying_the_language_in_text?language=objc
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // macos(10.14)
    NLLanguageRecognizer *recognizer = [[NLLanguageRecognizer alloc] init];
    
    // Because Apple text recognition is often inaccurate, we need to limit the recognition language type.
    recognizer.languageConstraints = [self constraintLanguages];
    
    
    recognizer.languageHints = [self customLanguageHints];
    
    [recognizer processString:text];
    
    NSDictionary<NLLanguage, NSNumber *> *dict = [recognizer languageHypothesesWithMaximum:10];
    NSLog(@"language dict: %@", dict);
    
    NLLanguage dominantLanguage = recognizer.dominantLanguage;
    NSLog(@"dominant Language: %@", dominantLanguage);
    
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"cost time: %.1f ms", (endTime - startTime) * 1000);
    
    Language language = [self languageEnumFromString:dominantLanguage];
    
    completion(language, nil);
}


/// Apple System ocr. Use Vision to recognize text in the image. Cost ~400ms
- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(OCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
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
            NSLog(@"cost time: %.1f ms", (endTime - startTime) * 1000);
            
            OCRResult *result = [[OCRResult alloc] init];
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
            
            completion(result, nil);
        }];
        
        if (@available(macOS 12.0, *)) {
            //            NSError *error;
            //            NSArray<NSString *> *supportedLanguages = [request supportedRecognitionLanguagesAndReturnError:&error];
            // "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ko-KR", "ja-JP", "ru-RU", "uk-UA"
            //            NSLog(@"supported Languages: %@", supportedLanguages);
        }
        
        request.recognitionLanguages = @[
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
        ]; // ISO language codes
        
        if (@available(macOS 13.0, *)) {
            request.automaticallyDetectsLanguage = YES;
        }
        request.usesLanguageCorrection = YES;
        
        // Perform the text-recognition request.
        [requestHandler performRequests:@[ request ] error:nil];
    } else {
        // Fallback on earlier versions
    }
}

- (void)audio:(NSString *)text from:(Language)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
}


- (void)ocrAndTranslate:(NSImage *)image from:(Language)from to:(Language)to ocrSuccess:(void (^)(OCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(OCRResult *_Nullable, TranslateResult *_Nullable, NSError *_Nullable))completion {
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


- (NSDictionary<NLLanguage, NSNumber *> *)customLanguageHints {
    NSDictionary *customHints = @{
        NLLanguageEnglish : @(0.95),
        NLLanguageSimplifiedChinese : @(0.8),
        NLLanguageJapanese : @(0.7),
        NLLanguageFrench : @(0.45), // const, ex
        NLLanguageKorean : @(0.4),
        NLLanguageGerman : @(0.2), // Bob 是一款 macOS 平台 翻译 和 OCR 软件
        NLLanguageTraditionalChinese : @(0.2),
        NLLanguageItalian : @(0.1),    // via
        NLLanguageSpanish : @(0.1),    // favor
        NLLanguagePortuguese : @(0.1), // favor
        NLLanguageDutch : @(0.1),      // heel, via
        
        NLLanguageCzech : @(0.01), // pro
    };
    
    NSArray<NLLanguage> *allSupportedLanguages = [[self supportLanguagesDictionary] allValues];
    NSMutableDictionary<NLLanguage, NSNumber *> *languageHints = [NSMutableDictionary dictionary];
    for (NLLanguage language in allSupportedLanguages) {
        languageHints[language] = @(0.01);
    }
    
    [languageHints addEntriesFromDictionary:customHints];
    
    return languageHints;
}

@end
