//
//  TablerRow.h
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TranslateResult.h"
#import "EZResultView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZResultCell : NSTableRowView

@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, strong) EZResultView *resultView;

@property (nonatomic, copy) void (^clickArrowBlock)(BOOL isShowing);

@end

NS_ASSUME_NONNULL_END
