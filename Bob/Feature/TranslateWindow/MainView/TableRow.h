//
//  TablerRow.h
//  Bob
//
//  Created by tisfeng on 2022/11/3.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TranslateResult.h"
#import "ResultView.h"

NS_ASSUME_NONNULL_BEGIN

@interface TableRow : NSTableRowView

@property (nonatomic, strong) TranslateResult *result;
@property (nonatomic, strong) ResultView *resultView;

@end

NS_ASSUME_NONNULL_END
