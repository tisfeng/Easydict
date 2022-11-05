//
//  HoverButton.h
//  Bob
//
//  Created by tisfeng on 2022/11/5.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RoundRectButton : NSButton

@property (nonatomic, assign) CGFloat cornerRadius; // default 5
@property (nonatomic, copy) void (^actionBlock)(RoundRectButton *button);

@end

NS_ASSUME_NONNULL_END
