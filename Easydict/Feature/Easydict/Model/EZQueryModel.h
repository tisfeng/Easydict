//
//  EZQueryModel.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryModel : NSObject

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, assign) EZLanguage userSourceLanguage;
@property (nonatomic, assign) EZLanguage userTargetLanguage;
@property (nonatomic, assign) EZLanguage queryFromLanguage;

@property (nonatomic, assign) EZLanguage detectedLanguage;
@property (nonatomic, assign) EZLanguage queryTargetLanguage;

@property (nonatomic, strong) NSImage *ocrImage;

@property (nonatomic, assign) CGFloat queryViewHeight;

@end

NS_ASSUME_NONNULL_END
