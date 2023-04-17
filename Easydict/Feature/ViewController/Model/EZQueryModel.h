//
//  EZQueryModel.h
//  Easydict
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *EZQueryType NS_STRING_ENUM;

FOUNDATION_EXPORT EZQueryType const EZQueryTypeAutoSelect;
FOUNDATION_EXPORT EZQueryType const EZQueryTypeShortcut;
FOUNDATION_EXPORT EZQueryType const EZQueryTypeInput;
FOUNDATION_EXPORT EZQueryType const EZQueryTypeOCR;

@interface EZQueryModel : NSObject <NSCopying>

@property (nonatomic, copy) EZQueryType queryType;
@property (nonatomic, copy) NSString *queryText;

@property (nonatomic, copy) EZLanguage userSourceLanguage;
@property (nonatomic, copy) EZLanguage userTargetLanguage;

@property (nonatomic, copy) EZLanguage detectedLanguage;

@property (nonatomic, copy, readonly) EZLanguage queryFromLanguage;
@property (nonatomic, copy, readonly) EZLanguage queryTargetLanguage;

// Means queryFromLanguage is not auto
@property (nonatomic, assign) BOOL hasQueryFromLanguage;

// If queryText has changed, we need to detect again. But, if user has specified detected language, do not auto detect.
@property (nonatomic, assign) BOOL needDetectLanguage;

@property (nonatomic, strong, nullable) NSImage *ocrImage;
@property (nonatomic, copy, nullable) NSString *audioURL;

@property (nonatomic, assign) CGFloat queryViewHeight;

- (void)setStopBlock:(void (^ _Nullable)(void))stopBlock serviceType:(NSString *)type; // EZServiceType

// Stop block will be removed when stop the service.
- (void)stopServiceRequest:(NSString *)serviceType; // EZServiceType

- (BOOL)isServiceStopped:(NSString *)serviceType;

- (void)stopAllService;

@end

NS_ASSUME_NONNULL_END
