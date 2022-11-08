//
//  EDQueryView.h
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EDCommonView.h"
#import "TextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EDQueryView : EDCommonView

@property (nonatomic, strong) TextView *textView;
@property (nonatomic, copy) NSString *detectLanguage;

@property (nonatomic, copy) void (^enterActionBlock)(NSString *text);
@property (nonatomic, copy) void (^detectActionBlock)(NSString *text);

@end

NS_ASSUME_NONNULL_END
