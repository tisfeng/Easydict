//
//  EZTitlebar.h
//  Open Bob
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZHoverButton.h"
#import "EZLinkButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface EZTitlebar : NSView

@property (nonatomic, strong) EZButton *pinButton;

@property (nonatomic, strong) EZLinkButton *eudicButton;
@property (nonatomic, strong) EZLinkButton *googleButton;

@property (nonatomic, strong) EZLinkButton *favoriteButton;

@end

NS_ASSUME_NONNULL_END
