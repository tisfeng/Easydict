//
//  EZSelectTextPopWindow.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/17.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EZSelectTextPopWindow : NSWindow

@property (nonatomic, copy) void (^hoverBlock)(void);

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
