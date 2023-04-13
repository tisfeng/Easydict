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

/// general word width, alphabet count is abount 5, means if a line is short, then append \n.
static CGFloat kEnglishWordWidth = 30; // [self widthOfString:@"array"]; // 30
static CGFloat kChineseWordWidth = 15; // [self widthOfString:@"爱"]; // 13

static NSArray *kEndPunctuationMarks = @[ @"。", @"？", @"！", @"?", @".", @"!" ];

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
    if (!appleFromLangCode || !appleToLangCode) {
        completion(self.result, EZQueryUnsupportedLanguageError(self));
        return;
    }
    
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
            self.result.normalResults = @[ result.trim ];
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
    text = [text trimToMaxLength:100];
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

- (NSDictionary<NLLanguage, NSNumber *> *)appleDetectTextLanguageDict:(NSString *)text printLog:(BOOL)logFlag {
    text = [text trimToMaxLength:100];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // Ref: https://developer.apple.com/documentation/naturallanguage/identifying_the_language_in_text?language=objc
    
    // macos(10.14)
    NLLanguageRecognizer *recognizer = [[NLLanguageRecognizer alloc] init];
    
    // Because Apple text recognition is often inaccurate, we need to limit the recognition language type.
    recognizer.languageConstraints = [self designatedLanguages];
    recognizer.languageHints = [self customLanguageHints];
    [recognizer processString:text];
    
    NSDictionary<NLLanguage, NSNumber *> *languageProbabilityDict = [recognizer languageHypothesesWithMaximum:5];
    NLLanguage dominantLanguage = recognizer.dominantLanguage;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    
    if (logFlag) {
        NSLog(@"system probabilities:: %@", languageProbabilityDict);
        NSLog(@"dominant Language: %@", dominantLanguage);
        NSLog(@"detect cost: %.1f ms", (endTime - startTime) * 1000); // ~4ms
    }
    
    return languageProbabilityDict;
}

/// Apple System ocr. Use Vision to recognize text in the image. Cost ~0.4s
- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    self.queryModel = queryModel;
    
    BOOL automaticallyDetectsLanguage = YES;
    if (![queryModel.queryFromLanguage isEqualToString:EZLanguageAuto]) {
        automaticallyDetectsLanguage = NO;
    }
    
    [self ocrImage:queryModel.ocrImage
          language:queryModel.queryFromLanguage
        autoDetect:automaticallyDetectsLanguage
        completion:^(EZOCRResult * _Nullable ocrResult, NSError * _Nullable error) {
        if (error || ocrResult.confidence == 1.0) {
            completion(ocrResult, error);
            return;
        }
        
        NSDictionary *languageDict = [self appleDetectTextLanguageDict:ocrResult.mergedText printLog:YES];
        [self getMostConfidenceLangaugeOCRResult:languageDict completion:^(EZOCRResult * _Nullable ocrResult, NSError * _Nullable error) {
            completion(ocrResult, error);
        }];
    }];
}

- (void)ocrImage:(NSImage *)image
        language:(EZLanguage)preferredLanguage
      autoDetect:(BOOL)automaticallyDetectsLanguage
      completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    NSLog(@"ocr language: %@", preferredLanguage);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Convert NSImage to CGImage
        CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
        
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        
        // Ref: https://developer.apple.com/documentation/vision/recognizing_text_in_images?language=objc
        
        MMOrderedDictionary *appleOCRDict = [self ocrLanguageDictionary];
        NSArray<EZLanguage> *defaultRecognitionLanguages = [appleOCRDict sortedKeys];
        NSArray<EZLanguage> *recognitionLanguages = [self updateOCRRecognitionLanguages:defaultRecognitionLanguages
                                                                     preferredLanguages:[EZLanguageManager systemPreferredLanguages]];
        
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
                        
            [self setupOCRResult:ocrResult request:request intelligentJoined:YES];
            if (!error && ocrResult.mergedText.length == 0) {
                /**
                 !!!: There are some problems with the system OCR.
                 For example, it may return nil when ocr Japanese text:
                 
                 アイス・スノーセーリング世界選手権大会
                 
                 */
                error = [EZTranslateError errorWithString:NSLocalizedString(@"ocr_result_is_empty", nil)];
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

- (void)setupOCRResult:(EZOCRResult *)ocrResult
               request:(VNRequest *_Nonnull)request
     intelligentJoined:(BOOL)intelligentJoined {
    // TODO: need to optimize, check the frame of the text and determine if line breaks are necessary.
    CGFloat confidence = 0;
    NSMutableArray *recognizedStrings = [NSMutableArray array];
    for (VNRecognizedTextObservation *observation in request.results) {
        VNRecognizedText *recognizedText = [[observation topCandidates:1] firstObject];
        VNConfidence recognizedConfidence = recognizedText.confidence;
        [recognizedStrings addObject:recognizedText.string];
        
        confidence += recognizedConfidence;
    }
    
    ocrResult.texts = recognizedStrings;
    if (recognizedStrings.count > 0) {
        ocrResult.confidence = confidence / recognizedStrings.count;
    }
    
    NSString *mergedText = [recognizedStrings componentsJoinedByString:@"\n"];
    if (intelligentJoined) {
        mergedText = [self joinOCRResults:ocrResult];
        mergedText = [self replaceSimilarDotSymbolOfString:mergedText];
    }
    
    ocrResult.mergedText = mergedText;
    ocrResult.raw = recognizedStrings;
    
    NSLog(@"ocr text: %@(%.1f): %@", ocrResult.from, ocrResult.confidence, recognizedStrings);
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


- (void)getMostConfidenceLangaugeOCRResult:(NSDictionary<NLLanguage, NSNumber *> *)languageProbabilityDict completion:(void (^)(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error))completion {
    /**
     
     苔むした岩に囲まれた滝
     
     */
    NSArray<NLLanguage> *sortedLanguages = [languageProbabilityDict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];

    NSMutableArray *results = [NSMutableArray array];
    dispatch_group_t group = dispatch_group_create();

    for (NLLanguage language in sortedLanguages) {
        EZLanguage ezLanguage = [self appleLanguageEnumFromCode:language];
        dispatch_group_enter(group);

        // !!!: automaticallyDetectsLanguage must be YES, otherwise confidence will be always 1.0
        [self ocrImage:self.queryModel.ocrImage
              language:ezLanguage
            autoDetect:YES
            completion:^(EZOCRResult * _Nullable ocrResult, NSError *_Nullable error) {
            [results addObject:@{@"ocrResult": ocrResult ?: [NSNull null], @"error": error ?: [NSNull null]}];
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            NSArray *sortedResults = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                EZOCRResult *result1 = obj1[@"ocrResult"];
                EZOCRResult *result2 = obj2[@"ocrResult"];
                NSNumber *confidence1 = result1 ? @(result1.confidence) : @(-1);
                NSNumber *confidence2 = result2 ? @(result2.confidence) : @(-1);
                return [confidence2 compare:confidence1];
            }];
            
            for (NSDictionary *result in sortedResults) {
                EZOCRResult *ocrResult = result[@"ocrResult"];
                NSLog(@"%@(%.1f): %@", ocrResult.from, ocrResult.confidence, ocrResult.mergedText);
            }
            
            NSDictionary *firstResult = sortedResults.firstObject;
            EZOCRResult *ocrResult = firstResult[@"ocrResult"];
            NSError *error = firstResult[@"error"];
            if ([error isEqual:[NSNull null]]) {
                error = nil;
            }
            
            NSLog(@"Final ocr: %@(%.1f): %@", ocrResult.from, ocrResult.confidence, ocrResult.mergedText);
            
            completion(ocrResult, error);
        }
    });
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

#pragma mark -

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

/// Get Chinese language type of text, traditional or simplified. If it is not Chinese, return EZLanguageAuto.
/// If it is Chinese, try to remove all English characters, then check if it is traditional or simplified.
/// - !!!: Make sure the count of Chinese characters is > 50% of the entire text.
/// test: 開門 open, 使用 OCR 123$, 月によく似た風景, アイス・スノーセーリング世界選手権大会
- (EZLanguage)chineseLanguageTypeOfText:(NSString *)text fromLanguage:(EZLanguage)language {
    text = [self removeAllSymbolAndWhitespaceCharacters:text];
    
    if (text.length == 0) {
        return EZLanguageAuto;
    }
    
    if ([language isEqualToString:EZLanguageEnglish]) {
        NSString *noAlphabetText = [self removeAlphabet:text];
        
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

/// Check if text is Chinese.
- (BOOL)isChineseText:(NSString *)text {
    EZLanguage language = [self appleDetectTextLanguage:text];
    if ([EZLanguageManager isChineseLanguage:language]) {
        return YES;
    }
    return NO;
}

/// Count Chinese characters length in string.
- (NSInteger)chineseCharactersLength:(NSString *)string {
    string = [self removeAllSymbolAndWhitespaceCharacters:string];
    __block NSInteger length = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *_Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL *_Nonnull stop) {
        if ([self isChineseText:substring]) {
            length++;
        }
    }];
    return length;
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

/// Check Chinese language type of text, traditional or simplified.
/// - !!!: Make sure the text is Chinese.
- (EZLanguage)chineseLanguageTypeOfText:(NSString *)chineseText {
    // test: 狗，勿 --> zh-Hant --> zh-Hans
    
    // Check if simplified Chinese.
    NSString *simplifiedChinese = [chineseText toSimplifiedChineseText];
    if ([simplifiedChinese isEqualToString:chineseText]) {
        return EZLanguageSimplifiedChinese;
    }
    
    // Check if traditional Chinese. 開門
    NSString *traditionalChinese = [chineseText toTraditionalChineseText];
    if ([traditionalChinese isEqualToString:chineseText]) {
        return EZLanguageTraditionalChinese;
    }
    
    return EZLanguageSimplifiedChinese;
}

#pragma mark -

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
        NSString *simplifiedChinese = [charString toSimplifiedChineseText];
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
        NSString *simplifiedChinese = [charString toSimplifiedChineseText];
        if ([simplifiedChinese isEqualToString:charString]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

/// !!!: This method is not accurate. 権 --> zh
- (BOOL)isChineseCharacter:(NSString *)string {
    if (string.length != 1) {
        return NO;
    }
    
    // 権 should be Japanese, but this method will detect it as Chinese.
    NSString *regex = @"[\u4e00-\u9fa5]";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:string];
}

#pragma mark - Remove desingated characters.

/// Remove all whitespace, punctuation, symbol and number characters.
- (NSString *)removeAllSymbolAndWhitespaceCharacters:(NSString *)string {
    NSString *text = [self removeWhitespaceAndNewlineCharacters:string];
    text = [self removePunctuationCharacters:text];
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

/// Remove all symbolCharacterSet. such as $, not including punctuationCharacterSet.
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

#pragma mark - Handle OCR text.

/**
 Hello world"
 然后请你也谈谈你对习主席连任的看法？
 最后输出以下内容的反义词："go up
 
 我宁愿所有痛苦都留在心里
 也不愿忘记你的眼睛
 给我再去相信的勇气
 Oh 越过谎言去拥抱你
 */
- (NSString *)joinOCRResults:(EZOCRResult *)ocrResult {
    NSArray<NSString *> *stringArray = ocrResult.texts;
    EZLanguage language = ocrResult.from;
    
    NSMutableString *joinedString = [NSMutableString string];
    CGFloat maxLengthOfLine = 0;
    CGFloat minLengthOfLine = 0;
    NSInteger punctuationMarkCount = 0;
    CGFloat punctuationMarkRate = 0;
    
    BOOL isPoetry = [self isPoetryOfOCRResults:ocrResult
                               maxLengthOfLine:&maxLengthOfLine
                               minLengthOfLine:&minLengthOfLine
                          punctuationMarkCount:&punctuationMarkCount
                           punctuationMarkRate:&punctuationMarkRate];
    
    NSString *newLineString = @"\n";
    if (isPoetry) {
        return [stringArray componentsJoinedByString:newLineString];
    }
    
    for (NSInteger i = 0; i < stringArray.count; i++) {
        NSString *string = stringArray[i];
        [joinedString appendString:string];
        
        // Append \n for short line if string frame width is less than max width - delta.
        BOOL isShortLine = [self isShortLineOfString:string maxLengthOfLine:maxLengthOfLine language:language];
        
        /// Join string array, if string last char end with [ 。？!.?！],  join with "\n", else join with " ".
        NSString *lastChar = [joinedString substringFromIndex:joinedString.length - 1];
        BOOL endWithPunctuationMark = [self isEndPunctuationMark:lastChar];
        
        BOOL needAppendNewLine = isShortLine || endWithPunctuationMark;
        
        if (needAppendNewLine) {
            [joinedString appendString:newLineString];
        } else if ([self isPunctuationMark:lastChar]) {
            // if last char is a punctuation mark, then append a space.
            [joinedString appendString:@" "];
        } else {
            // Like Chinese text, don't need space between words if it is not a punctuation mark.
            if ([self isLanguageWordsNeedSpace:language]) {
                [joinedString appendString:@" "];
            }
        }
    }
    
    // Remove last \n.
    return [joinedString trim];
}

/// Check if string array is poetry, and get the max and min frame width of string, the punctuation count and the punctuation mark percent.
- (BOOL)isPoetryOfOCRResults:(EZOCRResult *)ocrResult
             maxLengthOfLine:(CGFloat *)maxLengthOfLine
             minLengthOfLine:(CGFloat *)minLengthOfLine
        punctuationMarkCount:(NSInteger *)punctuationMarkCount
         punctuationMarkRate:(CGFloat *)punctuationMarkRate {
    NSArray<NSString *> *stringArray = ocrResult.texts;
    EZLanguage language = ocrResult.from;
    
    CGFloat _maxLengthOfLine = 0;
    CGFloat _minLengthOfLine = CGFLOAT_MAX;
    NSInteger _punctuationMarkCount = 0;
    CGFloat _punctuationMarkRate = 0;
    
    NSInteger totalCharCount = 0;
    for (NSString *string in stringArray) {
        CGFloat width = [self widthOfString:string];
        if (width > _maxLengthOfLine) {
            _maxLengthOfLine = width;
        }
        if (width < _minLengthOfLine) {
            _minLengthOfLine = width;
        }
        
        // iterate string to check if has punctuation mark.
        for (NSInteger i = 0; i < string.length; i++) {
            totalCharCount += 1;
            NSString *charString = [string substringWithRange:NSMakeRange(i, 1)];
            if ([self isPunctuationMark:charString]) {
                _punctuationMarkCount += 1;
            }
        }
    }
    
    *maxLengthOfLine = _maxLengthOfLine;
    *minLengthOfLine = _minLengthOfLine;
    *punctuationMarkCount = _punctuationMarkCount;
    
    _punctuationMarkRate = _punctuationMarkCount / (CGFloat)totalCharCount;
    *punctuationMarkRate = _punctuationMarkRate;
    
    NSInteger lineCount = stringArray.count;
    CGFloat numberOfPunctuationMarksPerLine = (CGFloat)_punctuationMarkCount / lineCount;
    
    /**
     曾经沧海难为水，
     除却巫山不是云。
     取次花丛懒回顾，
     半缘修道半缘君。
     */
    if (_maxLengthOfLine == _minLengthOfLine) {
        if ((numberOfPunctuationMarksPerLine <= 2) || lineCount >= 4) {
            return YES;
        }
    }
    
    // If average number of punctuation marks per line is greater than 2, then it is not poetry.
    if (numberOfPunctuationMarksPerLine > 2) {
        return NO;
    }
    
    if (_punctuationMarkCount == 0 && [EZLanguageManager isChineseLanguage:language]) {
        return YES;
    }
    
    if (lineCount >= 4 && _punctuationMarkRate < 0.02) {
        return YES;
    }
    
    if (lineCount >= 8 && (numberOfPunctuationMarksPerLine < 1 / 4) && (_punctuationMarkRate < 0.04)) {
        return YES;
    }
    
    NSInteger shortLineCount = 0;
    NSInteger longLineCount = 0;
    [self shortLineCount:&shortLineCount
           longLineCount:&longLineCount
           ofStringArray:stringArray
         maxLengthOfLine:_maxLengthOfLine
                language:language];
    
    BOOL tooManyLongLine = longLineCount >= lineCount * 0.8;
    if (tooManyLongLine) {
        return NO;
    }
    
    BOOL tooManyShortLine = shortLineCount >= lineCount * 0.8;
    if (tooManyShortLine) {
        return YES;
    }
    
    return NO;
}

/// Iterate string array, get the short line count and long line count.
- (void)shortLineCount:(NSInteger *)shortLineCount
         longLineCount:(NSInteger *)longLineCount
         ofStringArray:(NSArray<NSString *> *)stringArray
       maxLengthOfLine:(CGFloat)maxLengthOfLine
              language:(EZLanguage)language {
    NSInteger _shortLineCount = 0;
    NSInteger _longLineCount = 0;
    for (NSString *string in stringArray) {
        BOOL isShortLine = [self isShortLineOfString:string maxLengthOfLine:maxLengthOfLine language:language];
        BOOL isLongLine = [self isLongLineOfString:string maxLengthOfLine:maxLengthOfLine language:language];
        if (isShortLine) {
            _shortLineCount += 1;
        }
        if (isLongLine) {
            _longLineCount += 1;
        }
    }
    *shortLineCount = _shortLineCount;
    *longLineCount = _longLineCount;
}

/// Check if string is a short line, if string frame width is less than max width - delta * 2.
- (BOOL)isShortLineOfString:(NSString *)string
            maxLengthOfLine:(CGFloat)maxLengthOfLine
                   language:(EZLanguage)language {
    CGFloat width = [self widthOfString:string];
    CGFloat delta = kEnglishWordWidth;
    if ([EZLanguageManager isChineseLanguage:language]) {
        delta = kChineseWordWidth;
    }
    // TODO: Since some articles has indent, generally 3 Chinese words enough for indent.
    BOOL isShortLine = width <= maxLengthOfLine - delta * 2;
    
    return isShortLine;
}

/// Check if string is a long line, if string frame width is greater than max width - delta.
- (BOOL)isLongLineOfString:(NSString *)string
           maxLengthOfLine:(CGFloat)maxLengthOfLine
                  language:(EZLanguage)language {
    CGFloat width = [self widthOfString:string];
    CGFloat delta = kEnglishWordWidth;
    if ([EZLanguageManager isChineseLanguage:language]) {
        delta = kChineseWordWidth;
    }
    BOOL isLongLine = width >= maxLengthOfLine - delta;
    
    return isLongLine;
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

/// Use punctuationCharacterSet to check if it is a punctuation mark.
- (BOOL)isPunctuationMark:(NSString *)charString {
    if (charString.length != 1) {
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

/// Check if char is a end punctuation mark.
- (BOOL)isEndPunctuationMark:(NSString *)charString {
    if (charString.length != 1) {
        return NO;
    }
    
    return [kEndPunctuationMarks containsObject:charString];
}

/// Check if char is a punctuation mark but not a end punctuation mark.
- (BOOL)isNonEndPunctuationMark:(NSString *)charString {
    if (charString.length != 1) {
        return NO;
    }
    
    NSArray *punctuationMarks = @[ @"，", @"、", @"；", @",", @";" ];
    return [punctuationMarks containsObject:charString];
}

/// Itearte string array, get the max frame width of string.
- (CGFloat)maxLengthOfStringArray:(NSArray<NSString *> *)stringArray {
    CGFloat maxLength = 0;
    for (NSString *string in stringArray) {
        CGFloat width = [self widthOfString:string];
        if (width > maxLength) {
            maxLength = width;
        }
    }
    return maxLength;
}

/// Get string frame width.
- (CGFloat)widthOfString:(NSString *)string {
    CGSize size = [string sizeWithAttributes:@{NSFontAttributeName : [NSFont systemFontOfSize:NSFont.systemFontSize]}];
    return size.width;
}

/// Use NSCharacterSet to replace simlar dot sybmol with char "·", do not iterate.
- (NSString *)replaceSimilarDotSymbolOfString:(NSString *)string {
    // 《蝶恋花 • 阅尽天涯离别苦》
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"•‧∙"];
    //    NSString *text = [[string componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@"·"];
    
    NSArray *strings = [string componentsSeparatedByCharactersInSet:charSet];
    // Remove extra white space.
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *string in strings) {
        NSString *text = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (text.length > 0) {
            [array addObject:text];
        }
    }
    
    // Add white space for better reading.
    NSString *text = [array componentsJoinedByString:@" · "];
    
    return text;
}

/// Use regex to replace simlar dot sybmol with char "·", do not iterate.
- (NSString *)replaceSimilarDotSymbolOfString2:(NSString *)string {
    NSString *regex = @"[•‧∙]"; // [•‧∙・]
    NSString *text = [string stringByReplacingOccurrencesOfString:regex withString:@"·" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)];
    return text;
}

@end
