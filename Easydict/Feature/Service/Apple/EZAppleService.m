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

/// System detect text language,
- (void)detectText:(NSString *)text completion:(void (^)(EZLanguage, NSError *_Nullable))completion {
    EZLanguage mostConfidentLanguage = [self detectTextLanguage:text printLog:YES];
    completion(mostConfidentLanguage, nil);
}

/// Apple System language recognize, and try to correct language.
- (EZLanguage)detectTextLanguage:(NSString *)text printLog:(BOOL)logFlag {
    EZLanguage mostConfidentLanguage = [self appleDetectTextLanguage:text printLog:logFlag];
    
    if ([self isAlphabet:text] && ![mostConfidentLanguage isEqualToString:EZLanguageEnglish]) {
        mostConfidentLanguage = EZLanguageEnglish;
    }
    
    if ([EZLanguageManager isChineseLanguage:mostConfidentLanguage]) {
        // Correct 勿 --> zh-Hant --> zh-Hans
        EZLanguage chineseLanguage = [self chineseLanguageTypeOfText:text];
        return chineseLanguage;
    } else {
        // Try to detect Chinese language.
        if ([EZLanguageManager isChineseFirstLanguage]) {
            // test: 開門 open, 使用1 OCR --> 英文 --> 中文
            EZLanguage chineseLanguage = [self chineseLanguageTypeOfText:text fromLanguage:mostConfidentLanguage];
            if (![chineseLanguage isEqualToString:EZLanguageAuto]) {
                mostConfidentLanguage = chineseLanguage;
            }
        }
    }
    
    return mostConfidentLanguage;
}

- (EZLanguage)appleDetectTextLanguage:(NSString *)text {
    EZLanguage mostConfidentLanguage = [self appleDetectTextLanguage:text printLog:NO];
    return mostConfidentLanguage;
}

/// Apple original language detect.
- (EZLanguage)appleDetectTextLanguage:(NSString *)text printLog:(BOOL)logFlag {
    text = [text substringToIndex:MIN(100, text.length)];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // Ref: https://developer.apple.com/documentation/naturallanguage/identifying_the_language_in_text?language=objc
    
    // macos(10.14)
    NLLanguageRecognizer *recognizer = [[NLLanguageRecognizer alloc] init];
    
    // Because Apple text recognition is often inaccurate, we need to limit the recognition language type.
    recognizer.languageConstraints = [self designatedLanguages];
    recognizer.languageHints = [self customLanguageHints];
    [recognizer processString:text];
    
    NSDictionary<NLLanguage, NSNumber *> *languageProbabilityDict = [recognizer languageHypothesesWithMaximum:10];
    NLLanguage dominantLanguage = recognizer.dominantLanguage;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    
    if (logFlag) {
        NSLog(@"system probabilities:: %@", languageProbabilityDict);
        NSLog(@"dominant Language: %@", dominantLanguage);
        NSLog(@"detect cost: %.1f ms", (endTime - startTime) * 1000); // ~4ms
    }
    
    EZLanguage mostConfidentLanguage = [self getMostConfidentLanguage:languageProbabilityDict printLog:logFlag];
    return mostConfidentLanguage;
}

/// Apple System ocr. Use Vision to recognize text in the image. Cost ~0.4s
- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    EZLanguage ocrLanguage = queryModel.detectedLanguage;
    if (![queryModel.userSourceLanguage isEqualToString:EZLanguageAuto]) {
        ocrLanguage = queryModel.userSourceLanguage;
    }
    [self ocrImage:queryModel.ocrImage language:ocrLanguage retry:NO completion:completion];
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
    
    /**
     Since ocr Chinese mixed with English is not very accurate,
     we need to move Chinese to the first priority if newRecognitionLanguages first object is English and if user system language contains Chinese.
     
     风云 wind and clouds 99$ é
     
     */
    
    if ([preferredLanguages.firstObject isEqualToString:EZLanguageEnglish]) {
        // iterate all system preferred languages, if contains Chinese, move Chinese to the first priority.
        for (EZLanguage language in [EZLanguageManager systemPreferredLanguages]) {
            if ([EZLanguageManager isChineseLanguage:language]) {
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
- (EZLanguage)getMostConfidentLanguage:(NSDictionary<NLLanguage, NSNumber *> *)defaultLanguageProbabilities printLog:(BOOL)logFlag {
    NSMutableDictionary<NLLanguage, NSNumber *> *languageProbabilities = [NSMutableDictionary dictionaryWithDictionary:defaultLanguageProbabilities];
    NSDictionary<EZLanguage, NSNumber *> *userPreferredLanguageProbabilities = [self userPreferredLanguageProbabilities];
    
    for (EZLanguage language in userPreferredLanguageProbabilities.allKeys) {
        NLLanguage appleLanguage = [self appleLanguageCodeForLanguage:language];
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
    EZLanguage ezLanguage = [self appleLanguageEnumFromCode:mostConfidentLanguage];
    
    if (logFlag) {
        NSLog(@"user probabilities: %@", userPreferredLanguageProbabilities);
        NSLog(@"final language probabilities: %@", languageProbabilities);
        NSLog(@"---> Apple detect: %@", ezLanguage);
    }
    
    return ezLanguage;
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
    string = [self removeAllSymbolAndWhitespaceCharacters:string];
    __block NSInteger length = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *_Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL *_Nonnull stop) {
        if ([self isAlphabet:substring]) {
            length++;
        }
    }];
    return length;
}

/// Check Chinese language type of text, traditional or simplified.
/// - !!!: Make sure the text is Chinese.
- (EZLanguage)chineseLanguageTypeOfText:(NSString *)text {
    // test: 狗，勿 --> zh-Hant --> zh-Hans
    
    // Check if simplified Chinese.
    NSString *simplifiedChinese = [self toSimplifiedChineseText:text];
    if ([simplifiedChinese isEqualToString:text]) {
        return EZLanguageSimplifiedChinese;
    }
    
    // Check if traditional Chinese. 開門
    NSString *traditionalChinese = [self toTraditionalChineseText:text];
    if ([traditionalChinese isEqualToString:text]) {
        return EZLanguageTraditionalChinese;
    }
    
    return EZLanguageSimplifiedChinese;
}

/// Get Chinese language type of text, traditional or simplified. If it is not Chinese, return EZLanguageAuto.
/// If traditional Chinese characters length + simplified Chinese characters length + English characters length !== text length, return EZLanguageAuto.
/// If traditional Chinese characters length >= 1/4 of Chinese characters length, then it is traditional Chinese. else it is simplified Chinese.
/// test: 開門 open, 使用 OCR 123$, 月によく似た風景, アイス・スノーセーリング世界選手権大会
- (EZLanguage)chineseLanguageTypeOfText:(NSString *)text fromLanguage:(EZLanguage)language {
    text = [self removeAllSymbolAndWhitespaceCharacters:text];
    
    if (text.length == 0) {
        return EZLanguageAuto;
    }
    
    if ([language isEqualToString:EZLanguageEnglish]) {
        NSString *newText = [self removeAlphabet:text];
        EZLanguage detectedLanguage = [self appleDetectTextLanguage:newText];
        if ([EZLanguageManager isChineseLanguage:detectedLanguage]) {
            EZLanguage chineseLanguage = [self chineseLanguageTypeOfText:newText];
            return chineseLanguage;
        }
    }
    
    return EZLanguageAuto;
}

/// ⚠️ This method is not accurate, it is only used to detect Chinese language type.
- (EZLanguage)chineseLanguageTypeOfText2:(NSString *)text {
    //  月によく似た風景
    
    NSInteger traditionalChineseLength = [self chineseCharactersLength:text type:EZLanguageTraditionalChinese];
    NSInteger simplifiedChineseLength = [self chineseCharactersLength:text type:EZLanguageSimplifiedChinese];
    NSInteger englishLength = [self englishCharactersLength:text];
    NSInteger chineseLength = traditionalChineseLength + simplifiedChineseLength;
    NSInteger totalLength = chineseLength + englishLength;
    
    if (totalLength != text.length || traditionalChineseLength + simplifiedChineseLength == 0) {
        return EZLanguageAuto;
    }
    
    if (traditionalChineseLength >= chineseLength / 4.0) {
        return EZLanguageTraditionalChinese;
    } else {
        return EZLanguageSimplifiedChinese;
    }
}

/// Count Chinese characters length in string with specific language.
- (NSInteger)chineseCharactersLength:(NSString *)string type:(EZLanguage)language {
    string = [self removeAllSymbolAndWhitespaceCharacters:string];
    __block NSInteger length = 0;
    for (NSInteger i = 0; i < string.length; i++) {
        NSString *charString = [string substringWithRange:NSMakeRange(i, 1)];
        if (language == EZLanguageTraditionalChinese) {
            if ([self isTraditionalChineseChar:charString]) {
                length++;
            }
        } else if (language == EZLanguageSimplifiedChinese) {
            if ([self isSimplifiedChineseChar:charString]) {
                length++;
            }
        }
    }
    return length;
}

/// Check if char is Simplified Chinese. test: 使用 OCR 123$
- (BOOL)isSimplifiedChineseChar:(NSString *)charString {
    // ???: Why 勿, 狗 is traditional Chinese?
    EZLanguage language = [self appleDetectTextLanguage:charString];
    if (language == EZLanguageSimplifiedChinese) {
        return YES;
    }
    if (language == EZLanguageTraditionalChinese) {
        NSString *simplifiedChinese = [self toSimplifiedChineseText:charString];
        if ([simplifiedChinese isEqualToString:charString]) {
            return YES;
        }
    }
    return NO;
}

/// Check if char is Traditional Chinese. test: 開門 open
- (BOOL)isTraditionalChineseChar:(NSString *)charString {
    EZLanguage language = [self appleDetectTextLanguage:charString];
    if (language == EZLanguageTraditionalChinese) {
        // Convert to simplified Chinese, check if simplified Chinese is same as traditional Chinese.
        NSString *simplifiedChinese = [self toSimplifiedChineseText:charString];
        if ([simplifiedChinese isEqualToString:charString]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

/// !!!: This method is not accurate. 権 --> zh
- (BOOL)isChineseCharacter2:(NSString *)string {
    if (string.length != 1) {
        return NO;
    }
    
    // 権 should be Japanese, but this method will detect it as Chinese.
    NSString *regex = @"[\u4e00-\u9fa5]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:string];
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

/// Remove all punctuation whitespace and number characters.
- (NSString *)removeAllSymbolAndWhitespaceCharacters:(NSString *)string {
    NSString *text = [self removeWhitespaceAndNewlineCharacters:string];
    text = [self removeSymbolCharacterSet:text];
    text = [self removeNumbers:text];
    text = [self removeNonBaseCharacterSet:text];
    return text;
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
    NSCharacterSet *punctuationCharacterSet = [NSCharacterSet punctuationCharacterSet];
    NSString *result = [[string componentsSeparatedByCharactersInSet:punctuationCharacterSet] componentsJoinedByString:@""];
    return result;
}

- (NSString *)removePunctuationCharacters2:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"~`!@#$%^&*()-_+={}[]|\\;:'\",<.>/?·~！@#￥%……&*（）——+={}【】、|；：‘“，。、《》？"];
    NSCharacterSet *punctuationCharSet = [NSCharacterSet punctuationCharacterSet];
    NSMutableCharacterSet *finalCharSet = [punctuationCharSet mutableCopy];
    [finalCharSet formUnionWithCharacterSet:charSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:finalCharSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all numbers.
- (NSString *)removeNumbers:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet decimalDigitCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all symbolCharacterSet. such as $, including punctuationCharacterSet.
- (NSString *)removeSymbolCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet symbolCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all controlCharacterSet.
- (NSString *)removeControlCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet controlCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all illegalCharacterSet.
- (NSString *)removeIllegalCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet illegalCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all nonBaseCharacterSet.
- (NSString *)removeNonBaseCharacterSet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet nonBaseCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all alphabet.
- (NSString *)removeAlphabet:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all alphabet, use regex.
- (NSString *)removeAlphabet2:(NSString *)string {
    NSString *regex = @"[a-zA-Z]";
    NSString *text = [string stringByReplacingOccurrencesOfString:regex withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)];
    return text;
}

/// Remove all letters. Why "我123abc" will return "123"? Chinese characters are also letters ??
- (NSString *)removeLetters:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet letterCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Remove all alphabet and numbers.
- (NSString *)removeAlphabetAndNumbers:(NSString *)string {
    NSCharacterSet *charSet = [NSCharacterSet alphanumericCharacterSet];
    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    return text;
}

/// Print NSCharacterSet object.
- (void)printCharacterSet:(NSCharacterSet *)charSet {
    NSMutableArray *array = [NSMutableArray array];
    for (int plane = 0; plane <= 16; plane++) {
        if ([charSet hasMemberInPlane:plane]) {
            UTF32Char c;
            for (c = plane << 16; c < (plane + 1) << 16; c++) {
                if ([charSet longCharacterIsMember:c]) {
                    UTF32Char c1 = OSSwapHostToLittleInt32(c); // To make it byte-order safe
                    NSString *s = [[NSString alloc] initWithBytes:&c1 length:4 encoding:NSUTF32LittleEndianStringEncoding];
                    [array addObject:s];
                }
            }
        }
    }
    NSLog(@"charSet: %@", array);
}

@end
