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

@property (nonatomic, assign) EZLanguage userSourceLanguage;
@property (nonatomic, assign) EZLanguage userTargetLanguage;

@property (nonatomic, assign) EZLanguage detectedLanguage;
@property (nonatomic, assign, readonly) EZLanguage queryFromLanguage;
@property (nonatomic, assign, readonly) EZLanguage queryTargetLanguage;

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
