//
//  EZEnumTypes.h
//  Easydict
//
//  Created by tisfeng on 2023/4/18.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMOrderedDictionary.h"

NS_ASSUME_NONNULL_BEGIN

/// Window type
typedef NS_ENUM(NSInteger, EZWindowType) {
    EZWindowTypeNone = -1,
    EZWindowTypeMain = 0,
    EZWindowTypeMini = 1,
    EZWindowTypeFixed = 2,
};

/// Show window position
typedef NS_ENUM(NSUInteger, EZShowWindowPosition) {
    EZShowWindowPositionRight = 0,
    EZShowWindowPositionMouse = 1,
    EZShowWindowPositionFormer = 2,
    EZShowWindowPositionCenter = 3,
};

FOUNDATION_EXPORT NSString *const EZServiceTypeKey;

typedef NSString *EZServiceType NS_STRING_ENUM NS_SWIFT_NAME(ServiceType);
FOUNDATION_EXPORT EZServiceType const EZServiceTypeGoogle;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeBaidu;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeYoudao;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeApple;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeDeepL;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeVolcano;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeOpenAI;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeAppleDictionary;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeBing;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeNiuTrans;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeCaiyun;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeTencent;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeAli;
FOUNDATION_EXPORT EZServiceType const EZServiceTypeGemini;

FOUNDATION_EXPORT NSString *const EZQueryTextTypeKey;
FOUNDATION_EXPORT NSString *const EZIntelligentQueryTextTypeKey;

typedef NS_OPTIONS(NSUInteger, EZQueryTextType) {
    EZQueryTextTypeNone = 0,             // 0
    EZQueryTextTypeTranslation = 1 << 0, // 01 = 1
    EZQueryTextTypeDictionary = 1 << 1,  // 10 = 2
    EZQueryTextTypeSentence = 1 << 2,    // 100 = 4
};


FOUNDATION_EXPORT NSString *const EZServiceUsageStatusKey;
typedef NS_ENUM(NSUInteger, EZServiceUsageStatus) {
    EZServiceUsageStatusDefault = 0,
    EZServiceUsageStatusAlwaysOff = 1,
    EZServiceUsageStatusAlwaysOn = 2,
};

FOUNDATION_EXPORT NSString *const EZDeepLTranslationAPIKey;
typedef NS_ENUM(NSUInteger, EZDeepLTranslationAPI) {
    EZDeepLTranslationAPIWebFirst = 0,
    EZDeepLTranslationAPIOfficialFirst = 1,
    EZDeepLTranslationAPIOnlyOfficical = 2,
};


typedef NSString *EZActionType NS_STRING_ENUM;
FOUNDATION_EXPORT EZActionType const EZActionTypeAutoSelectQuery;
FOUNDATION_EXPORT EZActionType const EZActionTypeShortcutQuery;
FOUNDATION_EXPORT EZActionType const EZActionTypeInputQuery;
FOUNDATION_EXPORT EZActionType const EZActionTypeOCRQuery;
FOUNDATION_EXPORT EZActionType const EZActionTypeScreenshotOCR;
FOUNDATION_EXPORT EZActionType const EZActionTypeInvokeQuery;


typedef NSString *EZSelectTextType NS_STRING_ENUM;
FOUNDATION_EXPORT EZSelectTextType const EZSelectTextTypeAccessibility;
FOUNDATION_EXPORT EZSelectTextType const EZSelectTextTypeSimulatedKey; // Cmd+C
FOUNDATION_EXPORT EZSelectTextType const EZSelectTextTypeAppleScript;


/// Action trigger type
typedef NS_OPTIONS(NSUInteger, EZTriggerType) {
    EZTriggerTypeNone = 0,
    EZTriggerTypeDoubleClick = 1 << 0,
    EZTriggerTypeTripleClick = 1 << 1,
    EZTriggerTypeDragged = 1 << 2,
    EZTriggerTypeShift = 1 << 3,
};


@interface EZEnumTypes : NSObject

+ (NSString *)stringValueOfTriggerType:(EZTriggerType)triggerType;

+ (NSString *)windowName:(EZWindowType)type;

+ (MMOrderedDictionary<NSNumber *, NSString *> *)fixedWindowPositionDict;

+ (MMOrderedDictionary<NSNumber *, NSString *> *)translateWindowTypeDict;

@end


NS_ASSUME_NONNULL_END
