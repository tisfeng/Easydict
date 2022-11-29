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

/**
 Swift

 // Get the CGImage on which to perform requests.
 guard let cgImage = UIImage(named: "snapshot")?.cgImage else { return }

 // Create a new image-request handler.
 let requestHandler = VNImageRequestHandler(cgImage: cgImage)

 // Create a new request to recognize text.
 let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

 do {
     // Perform the text-recognition request.
     try requestHandler.perform([request])
 } catch {
     print("Unable to perform the requests: \(error).")
 }

 func recognizeTextHandler(request: VNRequest, error: Error?) {
     guard let observations =
             request.results as? [VNRecognizedTextObservation] else {
         return
     }
     let recognizedStrings = observations.compactMap { observation in
         // Return the string of the top VNRecognizedText instance.
         return observation.topCandidates(1).first?.string
     }

     // Process the recognized strings.
     processResults(recognizedStrings)
 }

 */

/// Apple system ocr. Use Vision to recognize text in the image.
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
                VNRecognizedText *recognizedText = [[observation topCandidates:1] firstObject];;
                [recognizedStrings addObject:recognizedText.string];
            }
            
            result.texts = recognizedStrings;
            result.mergedText = [recognizedStrings componentsJoinedByString:@"\n"];
            
            completion(result, nil);
        }];
        
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
            @(Language_auto), @"auto",nil];
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
