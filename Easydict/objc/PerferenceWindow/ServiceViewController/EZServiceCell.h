//
//  EZServiceCell.h
//  Easydict
//
//  Created by tisfeng on 2022/12/25.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryService.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EZServiceCellDarkBackgroundColor = @"#181818";
static NSString *const EZServiceCellLightBackgroundColor = @"#ffffff";


@interface EZServiceCell : NSView

@property (nonatomic, strong) EZQueryService *service;

@property (nonatomic, copy) void (^clickToggleButton)(NSButton *);

@end

NS_ASSUME_NONNULL_END
