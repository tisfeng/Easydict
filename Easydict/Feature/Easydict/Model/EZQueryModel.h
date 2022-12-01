//
//  EZQueryModel.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/21.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZLanguageTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZQueryModel : NSObject

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, assign) EZLanguage sourceLanguage;
@property (nonatomic, assign) EZLanguage targetLanguage;
@property (nonatomic, assign) EZLanguage detectedLanguage;

@property (nonatomic, strong) NSImage *image;

@property (nonatomic, assign) CGFloat queryViewHeight;

@end

NS_ASSUME_NONNULL_END
