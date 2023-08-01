//
//  EZEnumTypes.m
//  Easydict
//
//  Created by tisfeng on 2023/4/18.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZEnumTypes.h"

NSString *const EZServiceTypeKey = @"ServiceType";

NSString *const EZServiceTypeGoogle = @"Google";
NSString *const EZServiceTypeBaidu = @"Baidu";
NSString *const EZServiceTypeYoudao = @"Youdao";
NSString *const EZServiceTypeApple = @"Apple";
NSString *const EZServiceTypeDeepL = @"DeepL";
NSString *const EZServiceTypeVolcano = @"Volcano";
NSString *const EZServiceTypeOpenAI = @"OpenAI";

NSString *const EZServiceTypeAppleDictionary = @"AppleDictionary";

NSString *const EZQueryTextTypeKey = @"QueryTextType";
NSString *const EZIntelligentQueryTextTypeKey = @"IntelligentQueryTextType";

NSString *const EZServiceUsageStatusKey = @"ServiceUsageStatus";

NSString *const EZDeepLTranslationAPIKey = @"EZDeepLTranslationAPIKey";

NSString *const EZActionTypeAutoSelectQuery = @"auto_select_query";
NSString *const EZActionTypeShortcutQuery = @"shortcut_query";
NSString *const EZActionTypeInputQuery = @"input_query";
NSString *const EZActionTypeOCRQuery = @"ocr_query";
NSString *const EZActionTypeScreenshotOCR = @"silent_screenshot_ocr";

NSString *const EZSelectTextTypeAccessibility = @"accessibility_select_text";
NSString *const EZSelectTextTypeSimulatedKey = @"simulate_key_select_text";
NSString *const EZSelectTextTypeAppleScript = @"applescript_select_text";

NSString *const EZDefaultTTSServiceKey = @"EZDefaultTTSServiceKey";


@implementation EZEnumTypes

+ (NSString *)stringValueOfTriggerType:(EZTriggerType)triggerType {
    switch (triggerType) {
        case EZTriggerTypeNone:
            return @"none";
        case EZTriggerTypeDoubleClick:
            return @"double_click";
        case EZTriggerTypeTripleClick:
            return @"triple_click";
        case EZTriggerTypeDragged:
            return @"dragged";
        case EZTriggerTypeShift:
            return @"shift";
    }
}

+ (NSString *)windowName:(EZWindowType)type {
    switch (type) {
        case EZWindowTypeMain:
            return @"main_window";
        case EZWindowTypeFixed:
            return @"fixed_window";
        case EZWindowTypeMini:
            return @"mini_window";
        default:
            return @"none_window";
    }
}

+ (MMOrderedDictionary<NSNumber *, NSString *> *)fixedWindowPositionDict {
    MMOrderedDictionary *dict = [
        [MMOrderedDictionary alloc] initWithKeysAndObjects:
        @(EZShowWindowPositionRight), NSLocalizedString(@"fixed_window_position_right", nil),
        @(EZShowWindowPositionMouse), NSLocalizedString(@"fixed_window_position_mouse", nil),
        @(EZShowWindowPositionFormer), NSLocalizedString(@"fixed_window_position_former", nil),
        @(EZShowWindowPositionCenter), NSLocalizedString(@"fixed_window_position_center", nil),
        nil
    ];
    
    return dict;
}

@end
