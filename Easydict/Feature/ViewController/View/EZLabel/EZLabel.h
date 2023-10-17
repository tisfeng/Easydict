//
//  EDTextField.h
//  Easydict
//
//  Created by tisfeng on 2022/11/7.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZQueryMenuTextView.h"

NS_ASSUME_NONNULL_BEGIN

// Since there seems to be a bug in NSTextField, even if the line spacing is set, it will be automatically reset to 0 after clicking, which cannot be solved for the time being, so I have to use NSTextView.
@interface EZLabel : EZQueryMenuTextView

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSColor *textForegroundColor;

@property (nonatomic, assign) CGFloat lineSpacing; // default 4

@property (nonatomic, assign) CGFloat paragraphSpacing; // default 0

- (CGSize)oneLineSize;

@end

NS_ASSUME_NONNULL_END
