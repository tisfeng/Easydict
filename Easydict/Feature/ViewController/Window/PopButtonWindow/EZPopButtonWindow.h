//
//  EZSelectTextPopWindow.h
//  Easydict
//
//  Created by tisfeng on 2022/11/17.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZPopButtonWindow : NSWindow

@property (nonatomic, strong) EZButton *popButton;

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
