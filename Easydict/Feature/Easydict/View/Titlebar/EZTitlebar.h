//
//  EZTitlebar.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZHoverButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZTitlebar : NSView

@property (nonatomic, strong) EZHoverButton *pinButton;

@property (nonatomic, strong) EZButton *eudicButton;

@end

NS_ASSUME_NONNULL_END
