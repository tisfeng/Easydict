//
//  EZAppleService.m
//  Easydict
//
//  Created by tisfeng on 2022/11/29.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZAppleService.h"
#import <Vision/Vision.h>

@implementation EZAppleService

/// Apple system ocr. Use Vision to recognize text in the image. Cost ~400ms
- (void)ocr:(NSImage *)image from:(Language)from to:(Language)to completion:(void (^)(OCRResult *_Nullable, NSError *_Nullable))completion {
    // Convert NSImage to CGImage
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    // Ref: https://developer.apple.com/documentation/vision/recognizing_text_in_images?language=objc

    // Create a new image-request handler.
    VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
    // Create a new request to recognize text.
    if (@available(macOS 10.15, *)) {
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *_Nonnull request, NSError *_Nullable error) {
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            NSLog(@"cost time: %.1f ms", (endTime - startTime) * 1000);

            OCRResult *result = [[OCRResult alloc] init];
            result.from = from;
            result.to = to;

            if (error) {
                completion(result, error);
                return;
            }
            if (request.results.count == 0) {
                completion(result, nil);
                return;
            }

            NSMutableArray *recognizedStrings = [NSMutableArray array];
            for (VNRecognizedTextObservation *observation in request.results) {
                VNRecognizedText *recognizedText = [[observation topCandidates:1] firstObject];
                ;
                [recognizedStrings addObject:recognizedText.string];
            }

            result.texts = recognizedStrings;
            result.mergedText = [recognizedStrings componentsJoinedByString:@"\n"];

            completion(result, nil);
        }];

        if (@available(macOS 12.0, *)) {
            NSError *error;
            NSArray<NSString *> *supportedLanguages = [request supportedRecognitionLanguagesAndReturnError:&error];
            // "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ko-KR", "ja-JP", "ru-RU", "uk-UA"
            NSLog(@"supported Languages: %@", supportedLanguages);
        }

        request.recognitionLanguages = @[ @"zh-Hant", @"zh-Hans", @"en-US" ]; // ISO language codes

        // Perform the text-recognition request.
        [requestHandler performRequests:@[ request ] error:nil];

    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - 子类重写

- (EZServiceType)serviceType {
    return EZServiceTypeApple;
}

- (NSString *)identifier {
    return @"Apple";
}

- (NSString *)name {
    return @"Apple OCR";
}

- (NSString *)link {
    return @"";
}

- (MMOrderedDictionary *)supportLanguagesDictionary {
    return [[MMOrderedDictionary alloc] initWithKeysAndObjects:
                                            @(Language_auto), @"auto",
                                            @(Language_zh_Hans), @"zh-Hant",
                                            @(Language_zh_Hant), @"zh-Hans",
                                            @(Language_en), @"en-US", nil];
}

- (void)translate:(NSString *)text from:(Language)from to:(Language)to completion:(void (^)(TranslateResult *_Nullable, NSError *_Nullable))completion {
}

- (void)detect:(NSString *)text completion:(void (^)(Language, NSError *_Nullable))completion {
}

- (void)audio:(NSString *)text from:(Language)from completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
}


- (void)ocrAndTranslate:(NSImage *)image from:(Language)from to:(Language)to ocrSuccess:(void (^)(OCRResult *_Nonnull, BOOL))ocrSuccess completion:(void (^)(OCRResult *_Nullable, TranslateResult *_Nullable, NSError *_Nullable))completion {
}

@end
