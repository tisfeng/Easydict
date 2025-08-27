//
//  EZQueryModel.h
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"
#import "EZEnumTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryModel : NSObject <NSCopying>

@property (nonatomic, copy) NSString *inputText;
/// queryText = [inputText trim]
@property (nonatomic, copy, readonly) NSString *queryText;

@property (nonatomic, copy) EZActionType actionType;
@property (nonatomic, copy) EZSelectTextType selectTextType;

@property (nonatomic, copy) EZLanguage userSourceLanguage;
@property (nonatomic, copy) EZLanguage userTargetLanguage;

@property (nonatomic, assign, readonly) BOOL hasUserSourceLanguage;
@property (nonatomic, assign, readonly) BOOL hasUserTargetLanguage;

@property (nonatomic, copy) EZLanguage detectedLanguage;

@property (nonatomic, assign) CGFloat ocrConfidence;
@property (nonatomic, assign) CGFloat detectConfidence;

@property (nonatomic, copy, readonly) EZLanguage queryFromLanguage;
@property (nonatomic, copy, readonly) EZLanguage queryTargetLanguage;

// Means queryFromLanguage is not auto
@property (nonatomic, assign) BOOL hasQueryFromLanguage;

// If queryText has changed, we need to detect again. But, if user has specified detected language, do not auto detect.
@property (nonatomic, assign) BOOL needDetectLanguage;

@property (nonatomic, assign) BOOL showAutoLanguage;


// TODO: This dict may be need to be stored in NSUserDefaults.
@property (nonatomic, strong) NSMutableDictionary<NSString *, EZLanguage> *specifiedTextLanguageDict;

@property (nonatomic, strong, nullable) NSImage *ocrImage;
@property (nonatomic, copy, nullable) NSString *audioURL;

@property (nonatomic, assign) CGFloat queryViewHeight;

@property (nonatomic, assign) BOOL autoQuery;

#pragma mark - Stop Block

- (void)setStopBlock:(void (^ _Nullable)(void))stopBlock serviceType:(NSString *)type; // EZServiceType

// Stop block will be removed when stop the service.
- (void)stopServiceRequest:(NSString *)serviceType; // EZServiceType

- (BOOL)isServiceStopped:(NSString *)serviceType;

- (void)stopAllService;

@end

NS_ASSUME_NONNULL_END
