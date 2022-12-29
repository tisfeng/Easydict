//
//  TablerRow.h
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryResult.h"
#import "EZResultView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZResultCell : NSView

@property (nonatomic, strong) EZQueryResult *result;
@property (nonatomic, strong) EZResultView *resultView;

@property (nonatomic, copy) void (^clickArrowBlock)(BOOL isShowing);

@end

NS_ASSUME_NONNULL_END
