//
//  EZNiuTransTranslateResponse.h
//  Easydict
//
//  Created by tisfeng on 2023/2/23.
//  Copyright © 2023 izual. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class EZNiuTransTranslateResponse;
@class EZNiuTransTranslateResponseResult;
@class EZNiuTransTranslateResponseText;
@class EZNiuTransTranslateResponseAlternative;

#pragma mark - Object interfaces

@interface EZNiuTransTranslateResponse : NSObject
@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *jsonrpc;
@property (nonatomic, strong) EZNiuTransTranslateResponseResult *result;
@end

@interface EZNiuTransTranslateResponseResult : NSObject
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *detectedLanguages;
@property (nonatomic, copy) NSString *lang;
@property (nonatomic, assign) BOOL isLangIsConfident;
@property (nonatomic, copy) NSArray<EZNiuTransTranslateResponseText *> *texts;
@end

@interface EZNiuTransTranslateResponseText : NSObject
@property (nonatomic, copy) NSArray<EZNiuTransTranslateResponseAlternative *> *alternatives;
@property (nonatomic, copy) NSString *text;
@end

@interface EZNiuTransTranslateResponseAlternative : NSObject
@property (nonatomic, copy) NSString *text;
@end


NS_ASSUME_NONNULL_END
