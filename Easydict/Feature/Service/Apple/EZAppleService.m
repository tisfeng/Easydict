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
#import <AVFoundation/AVFoundation.h>
#import "EZExeCommand.h"
#import "EZConfiguration.h"

@interface EZAppleService ()

@property (nonatomic, strong) EZExeCommand *exeCommand;

@property (nonatomic, strong) NSDictionary *appleLangEnumFromStringDict;

@end

@implementation EZAppleService

- (EZExeCommand *)exeCommand {
    if (!_exeCommand) {
        _exeCommand = [[EZExeCommand alloc] init];
    }
    return _exeCommand;
}

- (NSDictionary<NSString *, EZLanguage> *)appleLangEnumFromStringDict {
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
    return NSLocalizedString(@"system_translate", nil);
}


- (MMOrderedDictionary *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                        EZLanguageAuto, @"auto",
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

- (MMOrderedDictionary *)appleLanguagesDictionary {
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

// zh-Hans --> Chinese-Simplified
- (EZLanguage)appleLanguageEnumFromCode:(NSString *)langString {
    EZLanguage language = [self.appleLangEnumFromStringDict objectForKey:langString];
    if (!language) {
        language = EZLanguageAuto;
    }
    return language;
}

// Chinese-Simplified --> zh-Hans
- (NSString *)appleLanguageCodeForLanguage:(EZLanguage)lang {
    return [self.appleLanguagesDictionary objectForKey:lang];
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
    
    NSString *appleFromLangCode = [self languageCodeForLanguage:from];
    NSString *appleToLangCode = [self languageCodeForLanguage:to];
    if (!appleFromLangCode || !appleToLangCode) {
        completion(self.result, EZQueryUnsupportedLanguageError(self));
        return;
    }
    
    NSDictionary *paramters = @{
        @"text" : text,
        @"from" : appleFromLangCode,
        @"to" : appleToLangCode,
    };
    NSLog(@"Apple translate paramters: %@", paramters);
    
    [self.exeCommand runTranslateShortcut:paramters completionHandler:^(NSString *_Nonnull result, NSError *error) {
        if (!error) {
            self.result.normalResults = @[ result ];
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
}

/// System detect text language, and try to correct language.
- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    EZLanguage mostConfidentLanguage = [self detectTextLanguage:text printLog:YES];
    completion(mostConfidentLanguage, nil);
}

/// Apple System language recognize.
- (EZLanguage)detectTextLanguage:(NSString *)text {
    return [self detectTextLanguage:text printLog:NO];
}

/// Apple System language recognize.
- (EZLanguage)detectTextLanguage:(NSString *)text printLog:(BOOL)logFlag {
    // Ref: https://developer.apple.com/documentation/naturallanguage/identifying_the_language_in_text?language=objc
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // macos(10.14)
    NLLanguageRecognizer *recognizer = [[NLLanguageRecognizer alloc] init];
    
    // Because Apple text recognition is often inaccurate, we need to limit the recognition language type.
    recognizer.languageConstraints = [self constraintLanguages];
    recognizer.languageHints = [self customLanguageHints];
    [recognizer processString:text];
    
    NSDictionary<NLLanguage, NSNumber *> *languageProbabilityDict = [recognizer languageHypothesesWithMaximum:10];
    NLLanguage dominantLanguage = recognizer.dominantLanguage;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    
    if (logFlag) {
        NSLog(@"system probabilities:: %@", languageProbabilityDict);
        NSLog(@"dominant Language: %@", dominantLanguage);
        NSLog(@"detect cost: %.1f ms", (endTime - startTime) * 1000);
    }
    
    EZLanguage mostConfidentLanguage = [self getMostConfidentLanguage:languageProbabilityDict];
    return mostConfidentLanguage;
}


/// Apple System ocr. Use Vision to recognize text in the image. Cost ~0.4s
- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    EZLanguage ocrLanguage = queryModel.detectedLanguage;
    if (![queryModel.userSourceLanguage isEqualToString:EZLanguageAuto]) {
        ocrLanguage = queryModel.userSourceLanguage;
    }
    [self ocrImage:queryModel.ocrImage language:ocrLanguage retry:YES completion:completion];
}

- (void)ocrImage:(NSImage *)image
        language:(EZLanguage)ocrLanguage
           retry:(BOOL)retryWithAutoDetectedLanguage
      completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    NSLog(@"ocr language: %@", ocrLanguage);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Convert NSImage to CGImage
        CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
        
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        
        // Ref: https://developer.apple.com/documentation/vision/recognizing_text_in_images?language=objc
        
        MMOrderedDictionary *appleOCRDict = [self ocrLanguageDictionary];
        NSArray<EZLanguage> *defaultRecognitionLanguages = [appleOCRDict sortedKeys];
        NSArray<EZLanguage> *recognitionLanguages = [self updateOCRRecognitionLanguages:defaultRecognitionLanguages
                                                                     preferredLanguages:[EZLanguageManager systemPreferredLanguages]];
        
        // Create a new image-request handler. macos(10.13)
        VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
        // Create a new request to recognize text.
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *_Nonnull request, NSError *_Nullable error) {
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            NSLog(@"ocr cost: %.1f ms", (endTime - startTime) * 1000);
            
            EZOCRResult *result = [[EZOCRResult alloc] init];
            result.from = ocrLanguage;
            
            if (error) {
                completion(result, error);
                return;
            }
            
            NSMutableArray *recognizedStrings = [NSMutableArray array];
            for (VNRecognizedTextObservation *observation in request.results) {
                VNRecognizedText *recognizedText = [[observation topCandidates:1] firstObject];
                [recognizedStrings addObject:recognizedText.string];
            }
            NSString *resultText = [recognizedStrings componentsJoinedByString:@"\n"];
            
            result.texts = recognizedStrings;
            result.mergedText = resultText;
            result.raw = recognizedStrings;
            
            NSLog(@"ocr text: %@", recognizedStrings);
            
            /**
             !!!: There are some problems with the system OCR.
             For example, it may return nil when ocr Japanese text.
             
             アイス・スノーセーリング世界選手権大会
             
             */
            
            BOOL retryOCR = retryWithAutoDetectedLanguage && [ocrLanguage isEqualToString:EZLanguageAuto];
            
            if (!retryOCR) {
                if (!error && resultText.length == 0) {
                    error = [EZTranslateError errorWithString:NSLocalizedString(@"ocr_result_is_empty", nil)];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(result, error);
                });
                return;
            }
            
            [self detectText:resultText completion:^(EZLanguage lang, NSError *_Nullable error) {
                if (![lang isEqualToString:recognitionLanguages.firstObject]) {
                    [self ocrImage:image language:lang retry:NO completion:completion];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(result, nil);
                    });
                }
            }];
        }];
        
        if (@available(macOS 12.0, *)) {
            //            NSError *error;
            //            NSArray<NSString *> *supportedLanguages = [request supportedRecognitionLanguagesAndReturnError:&error];
            // "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ko-KR", "ja-JP", "ru-RU", "uk-UA"
            //            NSLog(@"supported Languages: %@", supportedLanguages);
        }
        
        if ([ocrLanguage isEqualToString:EZLanguageAuto]) {
            if (@available(macOS 13.0, *)) {
                request.automaticallyDetectsLanguage = YES;
            }
        } else {
            // If has designated ocr language, move it to first priority.
            recognitionLanguages = [self updateOCRRecognitionLanguages:recognitionLanguages
                                                    preferredLanguages:@[ ocrLanguage ]];
        }
        
        NSArray *appleOCRLangaugeCodes = [self appleOCRLangaugeCodesWithRecognitionLanguages:recognitionLanguages];
        request.recognitionLanguages = appleOCRLangaugeCodes; // ISO language codes
        
        // TODO: need to test it.
        request.usesLanguageCorrection = YES;
        
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


- (nullable NSString *)voiceIdentifierFromLanguage:(EZLanguage)language {
    NSString *voiceIdentifier = nil;
    EZLanguageModel *languageModel = [EZLanguageManager languageModelFromLanguage:language];
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


- (void)ocrAndTranslate:(NSImage *)image from:(EZLanguage)from to:(EZLanguage)to ocrSuccess:(void (^)(EZOCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(EZOCRResult *_Nullable, EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"Apple not support ocrAndTranslate");
}

#pragma mark - Public Methods

- (void)playTextAudio:(NSString *)text fromLanguage:(EZLanguage)fromLanguage {
    void (^playBlock)(NSString *, EZLanguage) = ^(NSString *text, EZLanguage fromLanguage) {
        // voiceIdentifier: com.apple.voice.compact.en-US.Samantha
        NSString *voiceIdentifier = [self voiceIdentifierFromLanguage:fromLanguage];
        NSSpeechSynthesizer *synthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:voiceIdentifier];
        [synthesizer startSpeakingString:text];
    };
    
    if ([fromLanguage isEqualToString:EZLanguageAuto]) {
        [self detectText:text completion:^(EZLanguage _Nonnull fromLanguage, NSError *_Nullable error) {
            playBlock(text, fromLanguage);
        }];
    } else {
        playBlock(text, fromLanguage);
    }
}

#pragma mark - Others

// uniqueLanguages is supportLanguagesDictionary remove some languages
- (NSArray<NLLanguage> *)constraintLanguages {
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
        NLLanguageEnglish : @(3.0),
        NLLanguageSimplifiedChinese : @(2.0),
        NLLanguageTraditionalChinese : @(0.4),
        NLLanguageJapanese : @(0.25),
        NLLanguageFrench : @(0.25), // const, ex, delimiter
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
    NSArray *preferredLanguages = [EZLanguageManager systemPreferredLanguages];
    
    // TODO: need to test more data. Maybe need to write a unit test.
    
    /**
     Increase the proportional weighting of the user's preferred language.
     
     1. Chinese, + 0.3
     2. English, + 0.2
     3. Japanese, + 0.1
     4. ........, + 0.1
     
     */
    NSMutableDictionary<EZLanguage, NSNumber *> *languageProbabilities = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < preferredLanguages.count; i++) {
        EZLanguage language = preferredLanguages[i];
        CGFloat maxWeight = 0.3;
        CGFloat step = 0.1;
        CGFloat weight = maxWeight - step * i;
        if (weight < 0.1) {
            weight = 0.1;
        }
        if ([language isEqualToString:EZLanguageEnglish]) {
            if (![EZLanguageManager isEnglishFirstLanguage]) {
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
- (EZLanguage)getMostConfidentLanguage:(NSDictionary<NLLanguage, NSNumber *> *)defaultLanguageProbabilities {
    NSMutableDictionary<NLLanguage, NSNumber *> *languageProbabilities = [NSMutableDictionary dictionaryWithDictionary:defaultLanguageProbabilities];
    NSDictionary<EZLanguage, NSNumber *> *userPreferredLanguageProbabilities = [self userPreferredLanguageProbabilities];
    NSLog(@"user probabilities: %@", userPreferredLanguageProbabilities);
    
    for (EZLanguage language in userPreferredLanguageProbabilities.allKeys) {
        NLLanguage appleLanguage = [self appleLanguageCodeForLanguage:language];
        CGFloat defaultProbability = [defaultLanguageProbabilities[appleLanguage] doubleValue];
        if (defaultProbability) {
            NSNumber *userPreferredLanguageProbability = userPreferredLanguageProbabilities[language];
            languageProbabilities[appleLanguage] = @(defaultProbability + userPreferredLanguageProbability.doubleValue);
        }
    }
    
    NSLog(@"final language probabilities: %@", languageProbabilities);
    
    NSArray<NLLanguage> *sortedLanguages = [languageProbabilities keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    
    NLLanguage mostConfidentLanguage = sortedLanguages.firstObject;
    EZLanguage ezLanguage = [self appleLanguageEnumFromCode:mostConfidentLanguage];
    
    NSLog(@"---> Apple detect: %@", ezLanguage);
    
    return ezLanguage;
}

@end
