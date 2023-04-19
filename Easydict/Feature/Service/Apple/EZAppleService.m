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

/// general word width, alphabet count is abount 5, means if a line is short, then append \n.
static CGFloat const kEnglishWordWidth = 30; // [self widthOfString:@"array"]; // 30.79
static CGFloat const kChineseWordWidth = 13; // [self widthOfString:@"爱"]; // 13.26

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
    NSDictionary<NLLanguage, NSNumber *> *languageProbabilityDict = [self appleDetectTextLanguageDict:text printLog:logFlag];
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

    // !!!: All numbers will be return nil: 729
    if (languageProbabilityDict.count == 0) {
        EZLanguage firstLanguage = [EZLanguageManager firstLanguage];
        dominantLanguage = [self appleLanguageFromLanguageEnum:firstLanguage];
        languageProbabilityDict = @{dominantLanguage : @(0)};
    }
    
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
    BOOL hasSpecifiedLanguage = ![queryModel.queryFromLanguage isEqualToString:EZLanguageAuto];
    if (hasSpecifiedLanguage) {
        automaticallyDetectsLanguage = NO;
    }
    
    [self ocrImage:queryModel.ocrImage
          language:queryModel.queryFromLanguage
        autoDetect:automaticallyDetectsLanguage
        completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
        if (hasSpecifiedLanguage || error || ocrResult.confidence == 1.0) {
            completion(ocrResult, error);
            return;
        }
        
        NSDictionary *languageDict = [self appleDetectTextLanguageDict:ocrResult.mergedText printLog:YES];
        [self getMostConfidentLangaugeOCRResult:languageDict completion:^(EZOCRResult *_Nullable ocrResult, NSError *_Nullable error) {
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
        
        MMOrderedDictionary *appleOCRLanguageDict = [self ocrLanguageDictionary];
        NSArray<EZLanguage> *defaultRecognitionLanguages = [appleOCRLanguageDict sortedKeys];
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

- (void)setupOCRResult:(EZOCRResult *)ocrResult
               request:(VNRequest *_Nonnull)request
     intelligentJoined:(BOOL)intelligentJoined {
    CGFloat miniLineHeight = MAXFLOAT;
    CGFloat miniLineSpacing = MAXFLOAT;
    CGFloat miniX = MAXFLOAT;
    NSMutableArray *recognizedStrings = [NSMutableArray array];
    NSArray<VNRecognizedTextObservation *> *observationResults = request.results;
    
    for (int i = 0; i < observationResults.count; i++) {
        VNRecognizedTextObservation *observation = observationResults[i];
        VNRecognizedText *recognizedText = [[observation topCandidates:1] firstObject];
        NSString *recognizedString = recognizedText.string;
        [recognizedStrings addObject:recognizedString];
        
        CGRect boundingBox = observation.boundingBox;
//        NSLog(@"%@ %@", recognizedString, @(boundingBox));
        
        CGFloat lineHeight = boundingBox.size.height;
        if (lineHeight < miniLineHeight) {
            miniLineHeight = lineHeight;
        }
        
        if (i > 0) {
            VNRecognizedTextObservation *prevObservation = observationResults[i - 1];
            CGRect prevBoundingBox = prevObservation.boundingBox;
            CGFloat deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + boundingBox.size.height);
            if (deltaY > 0 && deltaY < miniLineSpacing) {
                miniLineSpacing = deltaY;
            }
        }
        
        CGFloat x = boundingBox.origin.x;
        if (x < miniX) {
            miniX = x;
        }
    }
    
    ocrResult.texts = recognizedStrings;
    ocrResult.mergedText = [recognizedStrings componentsJoinedByString:@"\n"];
    
    if (!intelligentJoined) {
        return;
    }
    
    
    NSArray<NSString *> *stringArray = ocrResult.texts;
    NSLog(@"ocr stringArray: %@", stringArray);
    
    CGFloat maxLengthOfLine = 0;
    CGFloat minLengthOfLine = 0;
    NSInteger punctuationMarkCount = 0;
    CGFloat punctuationMarkRate = 0;
    
    BOOL isPoetry = [self isPoetryOfOCRResults:ocrResult
                               maxLengthOfLine:&maxLengthOfLine
                               minLengthOfLine:&minLengthOfLine
                          punctuationMarkCount:&punctuationMarkCount
                           punctuationMarkRate:&punctuationMarkRate];
    
    CGFloat confidence = 0;
    NSMutableString *mergedText = [NSMutableString string];
    
    for (int i = 0; i < observationResults.count; i++) {
        VNRecognizedTextObservation *observation = observationResults[i];
        VNRecognizedText *recognizedText = [[observation topCandidates:1] firstObject];
        confidence += recognizedText.confidence;
        
        NSString *recognizedString = recognizedText.string;
        CGRect boundingBox = observation.boundingBox;
//        NSLog(@"%@ %@", recognizedString, @(boundingBox));
        
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
            VNRecognizedTextObservation *prevObservation = observationResults[i - 1];
            CGRect prevBoundingBox = prevObservation.boundingBox;
            CGFloat deltaY = prevBoundingBox.origin.y - (boundingBox.origin.y + boundingBox.size.height);
            // miniLineHeight = 0.1
            
            BOOL aligned = boundingBox.origin.x - miniX < 0.15;
            BOOL needLineBreak = !aligned || isPoetry;
            
            NSString *joinedString;
            //            if (deltaY > miniLineSpacing * 1.8 ) { // line spacing is inaccurate, sometimes it's too small 😢
            if (deltaY > miniLineHeight) { // 0.7 - 0.04 - 0.5 = 0.16
                joinedString = @"\n\n";
            } else if (deltaY > 0) {
                if (needLineBreak) {
                    joinedString = @"\n"; // 0.5 - 0.06 - 0.4 = 0.04
                } else {
                    NSString *prevString = [[prevObservation topCandidates:1] firstObject].string;
                    joinedString = [self joinedStringOfText:prevString
                                            maxLengthOfLine:&maxLengthOfLine
                                                   language:ocrResult.from];
                }
            } else {
                joinedString = @" "; // the same line
            }
            [mergedText appendString:joinedString];
        }
        
        [mergedText appendString:recognizedString];
    }
    
    ocrResult.mergedText = [self replaceSimilarDotSymbolOfString:mergedText].trim;
    ocrResult.texts = [mergedText componentsSeparatedByString:@"\n"];
    ocrResult.raw = recognizedStrings;
    
    if (recognizedStrings.count > 0) {
        ocrResult.confidence = confidence / recognizedStrings.count;
    }
    
    NSLog(@"ocr text: %@(%.1f): %@", ocrResult.from, ocrResult.confidence, ocrResult.mergedText);
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
        [self ocrImage:self.queryModel.ocrImage
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
            
            NSDictionary *firstResult = sortedResults.firstObject;
            EZOCRResult *firstOCRResult = firstResult[@"ocrResult"];
            
            // Since there are some languages that have the same confidence, we need to get all of them.
            NSMutableArray<NSDictionary *> *mostConfidentResults = [NSMutableArray array];
            CGFloat mostConfidence = firstOCRResult.confidence;;
            
            for (NSDictionary *result in sortedResults) {
                EZOCRResult *ocrResult = result[@"ocrResult"];
                if (ocrResult.confidence == mostConfidence) {
                    [mostConfidentResults addObject:result];
                }
                NSLog(@"%@(%.1f): %@", ocrResult.from, ocrResult.confidence, ocrResult.mergedText);
            }
            
            if (mostConfidentResults.count > 1) {
                // iterate mostConfidentResults, find the first ocrResult.from in supportLanguages
                NSArray<NLLanguage> *sortedAppleLanguages = [[self appleLanguagesDictionary] sortedValues];
                
                BOOL shouldBreak = NO;
                for (NLLanguage appleLanguage in sortedAppleLanguages) {
                    EZLanguage ezLanguage = [self languageEnumFromAppleLanguage:appleLanguage];
                    for (NSDictionary *result in mostConfidentResults) {
                        EZOCRResult *ocrResult = result[@"ocrResult"];
                        if ([ezLanguage isEqualToString:ocrResult.from]) {
                            firstResult = result;
                            shouldBreak = YES;
                            break;
                        }
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
            
            NSLog(@"Final ocr: %@(%.1f): %@", firstOCRResult.from, firstOCRResult.confidence, firstOCRResult.mergedText);
            
            completion(firstOCRResult, error);
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

#pragma mark - Detect Language Manually

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
    
    text = [EZTextWordUtils removeNonNormalCharacters:text];
    
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

#pragma mark - Handle OCR text.

/**
 Hello world"
 然后请你也谈谈你对习主席连任的看法？
 最后输出以下内容的反义词："go up
 */
- (NSString *)joinOCRResults:(EZOCRResult *)ocrResult {
    NSArray<NSString *> *stringArray = ocrResult.texts;
    NSLog(@"ocr stringArray: %@", stringArray);
    
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
        NSLog(@"--> isPoetry");
        return [stringArray componentsJoinedByString:newLineString];
    }
    
    for (NSInteger i = 0; i < stringArray.count; i++) {
        NSString *string = stringArray[i];
        [joinedString appendString:string];
        
        /// Join string array, if string last char end with [ 。？!.?！],  join with "\n", else join with " ".
        NSString *lastChar = [string substringFromIndex:string.length - 1];
        
        // Append \n for short line if string frame width is less than max width - delta.
        BOOL isShortLine = [self isShortLineOfString:string
                                     maxLengthOfLine:maxLengthOfLine
                                            language:language];
        
        BOOL needAppendNewLine = isShortLine;
        
        if (needAppendNewLine) {
            [joinedString appendString:newLineString];
        } else if ([self isPunctuationChar:lastChar]) {
            // if last char is a punctuation mark, then append a space, since ocr will remove white space.
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

/// Get joined string of text, according to its last char.
- (NSString *)joinedStringOfText:(NSString *)text
                 maxLengthOfLine:(CGFloat *)maxLengthOfLine
                        language:(EZLanguage)language {
    NSString *joinedString = @"";
    NSString *lastChar = [text substringFromIndex:text.length - 1];
    BOOL isShortLine = [self isShortLineOfString:text
                                 maxLengthOfLine:*maxLengthOfLine
                                        language:language];
    BOOL needLineBreak = isShortLine || [self isEndPunctuationChar:lastChar];
    
    if (needLineBreak) {
        joinedString = @"\n";
    } else if ([self isPunctuationChar:lastChar]) {
        // if last char is a punctuation mark, then append a space, since ocr will remove white space.
        joinedString = @" ";
    } else {
        // Like Chinese text, don't need space between words if it is not a punctuation mark.
        if ([self isLanguageWordsNeedSpace:language]) {
            joinedString = @" ";
        }
    }
    return joinedString;
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
            NSArray *allowList = @[ @"《", @"》", @"—" ];
            BOOL isChar = [self isPunctuationChar:charString excludeCharArray:allowList];
            if (isChar) {
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
        BOOL isShortLine = [self isShortLineOfString:string
                                     maxLengthOfLine:maxLengthOfLine
                                            language:language];
        
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

/// Check if string is a short line, if string frame width is less than max width - delta * 2
- (BOOL)isShortLineOfString:(NSString *)string
            maxLengthOfLine:(CGFloat)maxLengthOfLine
                   language:(EZLanguage)language {
    if (string.length == 0) {
        return YES;
    }
    
    CGFloat width = [self widthOfString:string];
    CGFloat delta = kEnglishWordWidth;
    if ([EZLanguageManager isChineseLanguage:language]) {
        delta = kChineseWordWidth;
    }
    
    // TODO: Since some articles has indent, generally 3 Chinese words enough for indent.
    BOOL isShortLine = maxLengthOfLine - width >= delta * 2;
    
    return isShortLine;
}

/// Check if string is a long line, if string frame width is greater than max width - delta * 1.5
- (BOOL)isLongLineOfString:(NSString *)string
           maxLengthOfLine:(CGFloat)maxLengthOfLine
                  language:(EZLanguage)language {
    CGFloat width = [self widthOfString:string];
    CGFloat delta = kEnglishWordWidth;
    if ([EZLanguageManager isChineseLanguage:language]) {
        delta = kChineseWordWidth;
    }
    BOOL isLongLine = maxLengthOfLine - width <= delta * 1.5;
    
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
- (BOOL)isPunctuationChar:(NSString *)charString {
    return [self isPunctuationChar:charString excludeCharArray:nil];
}

- (BOOL)isPunctuationChar:(NSString *)charString excludeCharArray:(nullable NSArray *)charArray {
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

/// Check if char is a end punctuation mark.
- (BOOL)isEndPunctuationChar:(NSString *)charString {
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
