//
//  HoverButton.h
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SWSTAnswerButton.h"

NS_ASSUME_NONNULL_BEGIN

/// Auto show highlight background color when hover button.
@interface EDHoverButton : SWSTAnswerButton

@property (nonatomic, copy) void (^actionBlock)(EDHoverButton *button);

@end

NS_ASSUME_NONNULL_END
