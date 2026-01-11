//
//  EZSelectLanguageCell.h
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZLanguageManager.h"

@class EZQueryModel;

NS_ASSUME_NONNULL_BEGIN

@interface EZSelectLanguageCell : NSTableRowView

@property (nonatomic, strong) EZQueryModel *queryModel;

@property (nonatomic, copy) void (^enterActionBlock)(EZLanguage from, EZLanguage to);

- (void)toggleTranslationLanguages;

@end

NS_ASSUME_NONNULL_END
